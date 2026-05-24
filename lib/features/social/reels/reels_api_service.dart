import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ReelsApiService {
  final Random _random = Random();
  String? _nextPageToken;

  /// İlk videoları çeker
  Future<List<Map<String, dynamic>>> fetchInitialReels({String query = '#yemektarifleri #shorts'}) async {
    _nextPageToken = null; // Sayfalandırmayı sıfırla
    return await _fetchFromYouTubeAPI(query);
  }

  /// Sınırsız kaydırma için sonraki sayfayı çeker
  Future<List<Map<String, dynamic>>> fetchMoreReels({String query = '#yemektarifleri #shorts'}) async {
    if (_nextPageToken == null) return [];
    return await _fetchFromYouTubeAPI(query, pageToken: _nextPageToken);
  }

  /// Resmi YouTube Data API v3 üzerinden arama yapar
  Future<List<Map<String, dynamic>>> _fetchFromYouTubeAPI(String query, {String? pageToken}) async {
    try {
      final apiKey = dotenv.env['YOUTUBE_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        debugPrint('HATA: YOUTUBE_API_KEY bulunamadı!');
        return [];
      }

      final uri = Uri.https('youtube.googleapis.com', '/youtube/v3/search', {
        'part': 'snippet',
        'q': query,
        'type': 'video',
        'maxResults': '10', 
        'videoDuration': 'short',
        'key': apiKey,
        'pageToken': ?pageToken,
      });

      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _nextPageToken = data['nextPageToken']; 
        
        final items = data['items'] as List;
        return _processVideos(items);
      } else {
        debugPrint('YouTube API Hatası: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('API üzerinden Reels çekerken hata: $e');
      return [];
    }
  }

  /// Sadece videoId'yi ve meta verileri döndürür (mp4 çıkarma yok)
  List<Map<String, dynamic>> _processVideos(List items) {
    final List<Map<String, dynamic>> reels = [];
    
    for (var item in items) {
      final videoId = item['id']['videoId'];
      final snippet = item['snippet'];
      
      final randomLikes = '${(_random.nextDouble() * 100 + 1).toStringAsFixed(1)}K';
      final randomComments = (_random.nextInt(500) + 10).toString();

      reels.add({
        'videoId': videoId, // Orijinal ID, mp4 url değil!
        'user': '@${snippet['channelTitle'].toString().replaceAll(' ', '')}',
        'avatar': 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(snippet['channelTitle'])}&background=random&color=fff',
        'caption': snippet['title'],
        'likes': randomLikes,
        'comments': randomComments,
      });
    }
    
    return reels;
  }

  void dispose() {
    // youtube_explode_dart artık olmadığı için dispose edilecek bir client yok.
  }
}
