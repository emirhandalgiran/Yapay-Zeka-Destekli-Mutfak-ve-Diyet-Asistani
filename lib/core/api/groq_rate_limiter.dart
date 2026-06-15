import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Groq API rate limits:
/// RPM: 30
/// TPM: 6K (6,000 tokens)
/// RPD: 14.4K
///
/// This rate limiter enforces strict request limits using a sliding window for
/// both Request Per Minute (RPM) and Tokens Per Minute (TPM).
/// It also handles exponential backoff for HTTP 429 (rate limit) or 503 (busy).
class GroqRateLimiter {
  GroqRateLimiter._();
  static final GroqRateLimiter instance = GroqRateLimiter._();

  static const String _baseUrl = 'https://api.groq.com/openai/v1';
  static const String _defaultModel = 'llama-3.1-8b-instant';
  static const String _fallbackModel = 'meta-llama/llama-4-scout-17b-16e-instruct';
  
  static const int _maxRequestsPerMinute = 28; // slightly conservative under 30
  static const int _maxTokensPerMinute = 5800; // slightly conservative under 6000
  static const int _maxRetries = 3;
  static const Duration _retryBaseDelay = Duration(seconds: 2);

  final List<DateTime> _requestTimestamps = [];
  final List<_TokenUsageRecord> _tokenUsageRecords = [];
  final _queue = _RequestQueue();

  String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  /// Sends a chat completion request to Groq API with robust queuing, rate limiting, and retry handling.
  Future<String> executeChat({
    required List<Map<String, String>> messages,
    double temperature = 0.1,
    int maxTokens = 4096,
    String? label,
  }) async {
    return _queue.add(() => _executeWithRetry(
      messages: messages,
      temperature: temperature,
      maxTokens: maxTokens,
      label: label,
    ));
  }

  Future<String> _executeWithRetry({
    required List<Map<String, String>> messages,
    required double temperature,
    required int maxTokens,
    String? label,
  }) async {
    // Rough pre-estimate of prompt tokens: 1 word ~ 1.3 tokens
    int estimatedInputTokens = 0;
    for (var msg in messages) {
      final content = msg['content'] ?? '';
      estimatedInputTokens += (content.split(RegExp(r'\s+')).length * 1.3).ceil() + 10;
    }
    
    // Total estimated token weight for rate limiter planning
    final estimatedTotalTokens = estimatedInputTokens + (maxTokens > 1000 ? 500 : maxTokens);

    String currentModel = _defaultModel;

    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      // Ensure we fit within RPM and TPM before proceeding
      await _waitForSlot(estimatedTotalTokens);

      try {
        _recordRequest();
        
        if (_apiKey.isEmpty) {
          throw Exception('Groq API Key (GROQ_API_KEY) is not set in environment variables!');
        }

        final response = await http.post(
          Uri.parse('$_baseUrl/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
          body: jsonEncode({
            'model': currentModel,
            'messages': messages,
            'temperature': temperature,
            'max_tokens': maxTokens,
          }),
        ).timeout(const Duration(seconds: 30));

        final responseBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> responseJson = jsonDecode(responseBody);

        if (response.statusCode == 200) {
          // Parse actual usage to update token records precisely
          final usage = responseJson['usage'];
          if (usage != null) {
            final int actualTotalTokens = usage['total_tokens'] ?? estimatedTotalTokens;
            _recordTokenUsage(actualTotalTokens);
          } else {
            _recordTokenUsage(estimatedTotalTokens);
          }

          final choices = responseJson['choices'] as List<dynamic>?;
          if (choices != null && choices.isNotEmpty) {
            final message = choices.first['message'];
            if (message != null) {
              final content = message['content']?.toString() ?? '';
              return content;
            }
          }
          throw Exception('Invalid choices structure in Groq API response');
        } else {
          // Handle rate limiting (429) or other errors
          final isRateLimit = response.statusCode == 429 || 
                              responseBody.toLowerCase().contains('rate_limit') ||
                              responseBody.toLowerCase().contains('429');
          final isServerError = response.statusCode >= 500 || 
                                responseBody.toLowerCase().contains('overloaded');

          if ((isRateLimit || isServerError) && attempt < _maxRetries) {
            final oldModel = currentModel;
            // Switch to fallback model on rate limit or server error
            currentModel = _fallbackModel;
            final delay = _calculateBackoff(attempt, isRateLimit: isRateLimit);
            debugPrint(
              '⏳ Groq ${label ?? "API"} — '
              '${isRateLimit ? "Rate limit (429)" : "HTTP ${response.statusCode}"} ($oldModel). '
              'Yedek modele geçiliyor: $currentModel. '
              '${delay.inSeconds}s bekleniyor... '
              '(Deneme ${attempt + 1}/$_maxRetries)',
            );
            await Future.delayed(delay);
            continue;
          }

          throw Exception('Groq API Error (${response.statusCode}): $responseBody');
        }
      } catch (e) {
        final errorStr = e.toString().toLowerCase();
        final isTimeoutOrNetwork = errorStr.contains('timeout') || errorStr.contains('socketexception') || errorStr.contains('connection');

        if (isTimeoutOrNetwork && attempt < _maxRetries) {
          final oldModel = currentModel;
          currentModel = _fallbackModel;
          final delay = _calculateBackoff(attempt, isRateLimit: false);
          debugPrint(
            '⏳ Groq ${label ?? "API"} — Hata ($oldModel): $e. '
            'Yedek modele geçiliyor: $currentModel. '
            '${delay.inSeconds}s bekleniyor... (Deneme ${attempt + 1}/$_maxRetries)',
          );
          await Future.delayed(delay);
          continue;
        }

        rethrow;
      }
    }

    throw Exception('Groq API: Maksimum deneme sayısı aşıldı');
  }

  /// Evaluates sliding windows of RPM and TPM, postponing the request if needed.
  Future<void> _waitForSlot(int estimatedTokens) async {
    _cleanOldRecords();

    while (true) {
      final now = DateTime.now();
      _cleanOldRecords();

      // Enforce at least 2 seconds between any consecutive requests to prevent burst limit triggers on free tier
      final lastReqTs = _requestTimestamps.isNotEmpty ? _requestTimestamps.last : null;
      if (lastReqTs != null) {
        final timeSinceLastReq = now.difference(lastReqTs);
        if (timeSinceLastReq < const Duration(seconds: 2)) {
          final waitDelay = const Duration(seconds: 2) - timeSinceLastReq;
          await Future.delayed(waitDelay);
          continue;
        }
      }

      // Check RPM limit
      final recentRequests = _requestTimestamps.length;
      final recentTokens = _tokenUsageRecords.fold<int>(0, (sum, record) => sum + record.tokens);

      if (recentRequests >= _maxRequestsPerMinute || (recentTokens + estimatedTokens) >= _maxTokensPerMinute) {
        // Find earliest timestamp to wait for
        final DateTime? oldestReqTs = _requestTimestamps.isNotEmpty ? _requestTimestamps.first : null;
        final DateTime? oldestTokenTs = _tokenUsageRecords.isNotEmpty ? _tokenUsageRecords.first.timestamp : null;
        
        DateTime waitTarget = now.add(const Duration(seconds: 2));
        if (oldestReqTs != null && (recentRequests >= _maxRequestsPerMinute)) {
          final reqRelease = oldestReqTs.add(const Duration(minutes: 1, seconds: 1));
          if (reqRelease.isAfter(waitTarget)) waitTarget = reqRelease;
        }
        if (oldestTokenTs != null && ((recentTokens + estimatedTokens) >= _maxTokensPerMinute)) {
          final tokenRelease = oldestTokenTs.add(const Duration(minutes: 1, seconds: 1));
          if (tokenRelease.isAfter(waitTarget)) waitTarget = tokenRelease;
        }

        final waitDuration = waitTarget.difference(now);
        if (waitDuration.isNegative || waitDuration.inMilliseconds < 100) {
          await Future.delayed(const Duration(milliseconds: 200));
          continue;
        }

        debugPrint(
          '🚦 Groq Rate Limit Koruyucu — Bekletiliyor: ${waitDuration.inSeconds}s '
          '(İstekler: $recentRequests/$_maxRequestsPerMinute, Tokenlar: $recentTokens/$_maxTokensPerMinute, Tahmini yeni: $estimatedTokens)',
        );
        await Future.delayed(waitDuration);
      } else {
        break; // Slot is available!
      }
    }
  }

  void _recordRequest() {
    _requestTimestamps.add(DateTime.now());
  }

  void _recordTokenUsage(int tokens) {
    _tokenUsageRecords.add(_TokenUsageRecord(DateTime.now(), tokens));
  }

  void _cleanOldRecords() {
    final cutoff = DateTime.now().subtract(const Duration(minutes: 1));
    _requestTimestamps.removeWhere((ts) => ts.isBefore(cutoff));
    _tokenUsageRecords.removeWhere((rec) => rec.timestamp.isBefore(cutoff));
  }

  Duration _calculateBackoff(int attempt, {bool isRateLimit = false}) {
    final baseMs = isRateLimit
        ? _retryBaseDelay.inMilliseconds * 2
        : _retryBaseDelay.inMilliseconds;
    final exponential = baseMs * pow(2, attempt);
    final jitter = Random().nextInt(1500);
    return Duration(milliseconds: exponential.toInt() + jitter);
  }
}

class _TokenUsageRecord {
  final DateTime timestamp;
  final int tokens;
  _TokenUsageRecord(this.timestamp, this.tokens);
}

/// Basit FIFO istek kuyruğu — aynı anda tek istek
class _RequestQueue {
  final _completer = <Completer<void>>[];
  bool _isProcessing = false;

  Future<T> add<T>(Future<T> Function() task) async {
    if (_isProcessing) {
      final completer = Completer<void>();
      _completer.add(completer);
      await completer.future;
    }

    _isProcessing = true;
    try {
      return await task();
    } finally {
      _isProcessing = false;
      if (_completer.isNotEmpty) {
        final next = _completer.removeAt(0);
        next.complete();
      }
    }
  }
}
