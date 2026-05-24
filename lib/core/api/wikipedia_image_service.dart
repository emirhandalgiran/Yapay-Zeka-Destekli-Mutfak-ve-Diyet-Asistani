import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Ücretsiz Wikipedia API'sini kullanarak yemekler için gerçek görseller bulur.
class WikipediaImageService {
  WikipediaImageService._();
  static final WikipediaImageService instance = WikipediaImageService._();

  // Cache: Aynı yemek için tekrar istek atılmasın
  final Map<String, String?> _imageCache = {};

  /// Yemeğin İngilizce adını aratıp uygun bir resim bulur.
  Future<String?> findImageForFood(String foodName) async {
    final query = foodName.trim();
    if (query.isEmpty) return null;

    // Cache kontrolü
    if (_imageCache.containsKey(query)) {
      return _imageCache[query];
    }

    try {
      // Wikipedia Search API: Görüntü URL'si döndürür
      final encodedQuery = Uri.encodeQueryComponent(query);
      final url = Uri.parse(
          'https://en.wikipedia.org/w/api.php?action=query&generator=search&gsrsearch=$encodedQuery&prop=pageimages&format=json&pithumbsize=500&gsrlimit=1');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final pages = data['query']?['pages'] as Map<String, dynamic>?;

        if (pages != null && pages.isNotEmpty) {
          final firstPage = pages.values.first;
          final thumbnailUrl = firstPage['thumbnail']?['source'] as String?;

          if (thumbnailUrl != null) {
            _imageCache[query] = thumbnailUrl;
            return thumbnailUrl;
          }
        }
      }
    } catch (e) {
      debugPrint('Wikipedia Görsel Hatası: \$e');
    }

    // Bulunamazsa null cache'le ki tekrar tekrar denenmesin
    _imageCache[query] = null;
    return null;
  }
}
