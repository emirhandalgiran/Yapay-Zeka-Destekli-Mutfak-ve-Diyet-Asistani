import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// FatSecret Platform API servisi — OAuth1.0 HMAC-SHA1 kimlik doğrulaması ile.
class FatSecretService {
  static const String _baseUrl = 'https://platform.fatsecret.com/rest/server.api';
  static final String _consumerKey = dotenv.env['FATSECRET_CONSUMER_KEY'] ?? '';
  static final String _consumerSecret = dotenv.env['FATSECRET_CONSUMER_SECRET'] ?? '';

  // ─────────────── OAuth1 İmzalama ───────────────

  /// RFC3986 uyumlu URL encode
  String _percentEncode(String value) {
    return Uri.encodeComponent(value)
        .replaceAll('+', '%20')
        .replaceAll('*', '%2A')
        .replaceAll('%7E', '~');
  }

  /// Rastgele nonce üret
  String _generateNonce() {
    final random = Random.secure();
    final values = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(values).replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  }

  /// HMAC-SHA1 imzası hesapla
  String _generateSignature(String method, String url, Map<String, String> params) {
    // 1. Parametreleri sırala ve birleştir
    final sortedKeys = params.keys.toList()..sort();
    final normalizedParams = sortedKeys
        .map((k) => '${_percentEncode(k)}=${_percentEncode(params[k]!)}')
        .join('&');

    // 2. Signature Base String oluştur
    final signatureBaseString =
        '${method.toUpperCase()}&${_percentEncode(url)}&${_percentEncode(normalizedParams)}';

    // 3. HMAC-SHA1 ile imzala (key = consumerSecret&)
    final signingKey = '${_percentEncode(_consumerSecret)}&';
    final hmacSha1 = Hmac(sha1, utf8.encode(signingKey));
    final digest = hmacSha1.convert(utf8.encode(signatureBaseString));

    return base64.encode(digest.bytes);
  }

  /// API'ye imzalı istek gönder
  Future<Map<String, dynamic>> _makeRequest(String methodName, [Map<String, String>? extraParams]) async {
    final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final nonce = _generateNonce();

    // OAuth parametreleri
    final params = <String, String>{
      'method': methodName,
      'oauth_consumer_key': _consumerKey,
      'oauth_nonce': nonce,
      'oauth_signature_method': 'HMAC-SHA1',
      'oauth_timestamp': timestamp,
      'oauth_version': '1.0',
      'format': 'json',
    };

    // Ek parametreleri ekle
    if (extraParams != null) {
      params.addAll(extraParams);
    }

    // İmza hesapla
    final signature = _generateSignature('POST', _baseUrl, params);
    params['oauth_signature'] = signature;

    // İstek gönder
    final uri = Uri.parse(_baseUrl);
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: params.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('FatSecret API Hatası: ${response.statusCode} — ${response.body}');
    }
  }

  // ─────────────── API Endpoint Metodları ───────────────

  /// 1) foods.search.v5 — Yiyecek arama
  Future<Map<String, dynamic>> searchFoods({
    required String query,
    int pageNumber = 0,
    int maxResults = 20,
    bool includeSubCategories = true,
    bool includeFoodImages = true,
    bool includeFoodAttributes = true,
    String? foodType, // 'brand' veya 'generic'
  }) async {
    final params = <String, String>{
      'search_expression': query,
      'page_number': pageNumber.toString(),
      'max_results': maxResults.toString(),
      'include_sub_categories': includeSubCategories.toString(),
      'include_food_images': includeFoodImages.toString(),
      'include_food_attributes': includeFoodAttributes.toString(),
    };
    if (foodType != null) params['food_type'] = foodType;
    return _makeRequest('foods.search.v5', params);
  }

  /// 2) foods.autocomplete.v2 — Otomatik tamamlama
  Future<Map<String, dynamic>> autocompleteFoods({
    required String expression,
    int maxResults = 10,
  }) async {
    return _makeRequest('foods.autocomplete.v2', {
      'expression': expression,
      'max_results': maxResults.toString(),
    });
  }

  /// 3) food.create.v2 — Yeni yiyecek oluştur
  Future<Map<String, dynamic>> createFood({
    required String foodName,
    String? brandName,
    required String servingDescription,
    required double caloriesPerServing,
    double? fatPerServing,
    double? proteinPerServing,
    double? carbsPerServing,
  }) async {
    final params = <String, String>{
      'food_name': foodName,
      'serving_description': servingDescription,
      'calories': caloriesPerServing.toString(),
    };
    if (brandName != null) params['brand_name'] = brandName;
    if (fatPerServing != null) params['fat'] = fatPerServing.toString();
    if (proteinPerServing != null) params['protein'] = proteinPerServing.toString();
    if (carbsPerServing != null) params['carbohydrate'] = carbsPerServing.toString();
    return _makeRequest('food.create.v2', params);
  }

  /// 4) food.find_id_for_barcode.v2 — Barkoddan yiyecek bul
  Future<Map<String, dynamic>> findFoodByBarcode({
    required String barcode,
  }) async {
    return _makeRequest('food.find_id_for_barcode.v2', {
      'barcode': barcode,
    });
  }

  /// 5) food_brands.get.v2 — Marka listesi
  Future<Map<String, dynamic>> getFoodBrands({
    String? startsWith,
  }) async {
    final params = <String, String>{};
    if (startsWith != null) params['starts_with'] = startsWith;
    return _makeRequest('food_brands.get.v2', params);
  }

  /// 6) food_categories.get.v2 — Kategori listesi
  Future<Map<String, dynamic>> getFoodCategories() async {
    return _makeRequest('food_categories.get.v2');
  }

  /// 7) food_sub_categories.get.v2 — Alt kategori listesi
  Future<Map<String, dynamic>> getFoodSubCategories({
    required int foodCategoryId,
  }) async {
    return _makeRequest('food_sub_categories.get.v2', {
      'food_category_id': foodCategoryId.toString(),
    });
  }
}
