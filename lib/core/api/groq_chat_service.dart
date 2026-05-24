import 'package:flutter/foundation.dart';
import 'groq_rate_limiter.dart';

/// Aura Şef — Groq tabanlı yemek asistanı sohbet servisi.
/// Chat oturumunu ve context-aware (bağlama duyarlı) mesaj geçmişini yönetir.
class GroqChatService {
  final GroqRateLimiter _limiter = GroqRateLimiter.instance;
  
  final List<Map<String, String>> _historyTr = [];
  final List<Map<String, String>> _historyEn = [];
  
  bool _hasSessionTr = false;
  bool _hasSessionEn = false;

  GroqChatService();

  /// Sistem promptu — Aura Şef Türkçe
  static const String _systemPromptTr = '''
Sen "Aura Şef" adında, Türk ve dünya mutfağında uzman, samimi ve yardımsever bir yapay zeka mutfak asistanısın. AuraCook uygulamasının yapay zeka asistanısın.

Kuralların:
1. Her zaman Türkçe cevap ver (kullanıcı İngilizce yazsa bile).
2. Yemek tarifleri, malzeme önerileri, pişirme teknikleri, besin değerleri, diyet önerileri gibi mutfak konularında uzman gibi cevap ver.
3. Tarifleri paylaşırken malzemeleri ve adımları açık, numaralı listeler halinde sun.
4. Samimi, sıcak ve cesaretlendirici bir dil kullan. Emoji kullanabilirsin ama abartma.
5. Kullanıcının sağlık durumunu (alerji, diyet) sorgulamak yerine, genel bilgi ver ve "doktorunuza danışın" şeklinde yönlendir.
6. Mutfak dışı konularda nazikçe "Ben bir mutfak asistanıyım, bu konuda yardımcı olamıyorum ama mutfakla ilgili her şeyi sorabilirsin! 🍳" şeklinde yönlendir.
7. Kısa ve öz cevaplar ver; kullanıcı detay isterse açıkla.
''';

  /// Sistem promptu — Aura Chef English
  static const String _systemPromptEn = '''
You are "Aura Chef", a warm, friendly, and highly skilled AI culinary assistant specializing in Turkish and world cuisines. You are the AI assistant of the AuraCook app.

Your Rules:
1. Always respond in English (even if the user writes in another language).
2. Answer as an expert on kitchen topics such as food recipes, ingredient suggestions, cooking techniques, nutrition values, and dietary advice.
3. Present recipes clearly with ingredients and cooking steps as numbered/bulleted lists.
4. Use a warm, friendly, and encouraging tone. Emojis are welcome but don't overdo them.
5. Instead of directly diagnosing a user's health condition (allergies, diets), provide general information and advise them to "consult your doctor".
6. For non-kitchen topics, gently redirect: "I'm a kitchen assistant, so I can't help with that, but feel free to ask me anything about cooking! 🍳"
7. Give brief and concise answers; explain further if the user asks for details.
''';

  /// Yeni bir chat oturumu başlatır veya mevcut oturumu sıfırlar.
  void startNewSession({bool isTurkish = true}) {
    if (isTurkish) {
      _historyTr.clear();
      _historyTr.add({'role': 'system', 'content': _systemPromptTr});
      _hasSessionTr = true;
    } else {
      _historyEn.clear();
      _historyEn.add({'role': 'system', 'content': _systemPromptEn});
      _hasSessionEn = true;
    }
  }

  /// Mesaj gönderir ve yanıt alır. Oturum yoksa otomatik başlatır.
  Future<String> sendMessage(String userMessage, {bool isTurkish = true}) async {
    try {
      if (isTurkish) {
        if (!_hasSessionTr || _historyTr.isEmpty) {
          startNewSession(isTurkish: true);
        }
        _historyTr.add({'role': 'user', 'content': userMessage});
        _trimHistory(_historyTr);
        
        final response = await _limiter.executeChat(
          messages: _historyTr,
          temperature: 0.7,
          maxTokens: 1500, // conservative for chat to fit TPM (6K)
          label: 'Aura Şef Chat',
        );

        if (response.isNotEmpty) {
          _historyTr.add({'role': 'assistant', 'content': response});
          return response;
        }
        throw Exception('Boş yanıt alındı');
      } else {
        if (!_hasSessionEn || _historyEn.isEmpty) {
          startNewSession(isTurkish: false);
        }
        _historyEn.add({'role': 'user', 'content': userMessage});
        _trimHistory(_historyEn);

        final response = await _limiter.executeChat(
          messages: _historyEn,
          temperature: 0.7,
          maxTokens: 1500,
          label: 'Aura Chef Chat',
        );

        if (response.isNotEmpty) {
          _historyEn.add({'role': 'assistant', 'content': response});
          return response;
        }
        throw Exception('Empty response received');
      }
    } catch (e) {
      debugPrint('GroqChatService Hata: $e');

      final errorStr = e.toString().toLowerCase();

      if (errorStr.contains('rate_limit') || errorStr.contains('429') || errorStr.contains('limit')) {
        return isTurkish
            ? 'Şu anda çok fazla istek var, lütfen birkaç saniye bekleyip tekrar deneyin 🕐'
            : 'Too many requests right now. Please wait a few seconds and try again 🕐';
      }

      if (errorStr.contains('busy') || errorStr.contains('overloaded') || errorStr.contains('503')) {
        return isTurkish
            ? 'Sunucu şu an yoğun, lütfen birkaç saniye sonra tekrar deneyin 🙏'
            : 'Server is currently busy, please try again in a few seconds 🙏';
      }

      return isTurkish
          ? 'Bir hata oluştu. Lütfen internet bağlantınızı kontrol edip tekrar deneyin.'
          : 'An error occurred. Please check your internet connection and try again.';
    }
  }

  /// Keep token/context size in check by trimming older messages (system + last 10 messages max).
  void _trimHistory(List<Map<String, String>> history) {
    if (history.length > 11) {
      final systemMsg = history.first;
      final lastTen = history.sublist(history.length - 10);
      history.clear();
      history.add(systemMsg);
      history.addAll(lastTen);
    }
  }

  /// Chat geçmişini temizler.
  void clearHistory() {
    _historyTr.clear();
    _historyEn.clear();
    _hasSessionTr = false;
    _hasSessionEn = false;
  }

  /// Chat oturumunun aktif olup olmadığını döndürür.
  bool hasActiveSession({bool isTurkish = true}) =>
      isTurkish ? _hasSessionTr : _hasSessionEn;
}
