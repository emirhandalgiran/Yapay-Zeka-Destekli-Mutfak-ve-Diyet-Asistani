import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../features/recipes/data/models/food_item.dart';
import '../../features/recipes/data/models/food_category.dart';
import 'groq_rate_limiter.dart';

class GroqTranslationService {
  final GroqRateLimiter _limiter = GroqRateLimiter.instance;
  
  // In-memory cache: İngilizce -> Türkçe
  final Map<String, String> _textCache = {};
  // Kategori çevirisi kalıcı cache (bir kez çevrilince bir daha API'ye gitme)
  bool _categoriesTranslated = false;

  // Sistem talimatı: system message olarak mesaj listesinin başına yerleştirilir
  static const String _systemInstruction =
      'You are an expert food and nutrition terminology translator. '
      'You ONLY output valid JSON — no markdown, no explanation, no extra text. '
      'Never include code fences like ```json. Output must be parseable by jsonDecode().';
  
  GroqTranslationService();

  /// Rate limiter üzerinden model çağrısı yapar.
  Future<String> _generate(String prompt, {int maxTokens = 4096}) {
    final messages = [
      {'role': 'system', 'content': _systemInstruction},
      {'role': 'user', 'content': prompt},
    ];
    return _limiter.executeChat(
      messages: messages,
      temperature: 0.1,
      maxTokens: maxTokens,
      label: 'Çeviri',
    );
  }

  /// Bir dilim (list) halindeki İngilizce metinleri topluca çevirir (örn: Autocomplete sonuçları).
  /// Geriye aynı sırayla çevrilmiş metin listesini döndürür.
  Future<List<String>> translateTexts(List<String> texts, {bool isTurkish = true}) async {
    if (texts.isEmpty) return [];
    if (!isTurkish) {
      return List.from(texts);
    }

    // Önce cache'de olanları bul
    final List<String> results = List.filled(texts.length, '');
    final List<int> unchachedIndices = [];
    final List<String> textsToTranslate = [];

    for (int i = 0; i < texts.length; i++) {
      final text = texts[i];
      if (_textCache.containsKey(text)) {
        results[i] = _textCache[text]!;
      } else {
        unchachedIndices.add(i);
        textsToTranslate.add(text);
      }
    }

    // Hepsi cache'de varsa direkt dön
    if (textsToTranslate.isEmpty) {
      return results;
    }

    // Cache'de olmayanları topluca Groq'a sor — rate limiter ile
    try {
      final prompt = '''
Gıda isimlerini ve besin terimlerini İngilizceden Türkçeye çevir. 
Porsiyon birimlerini (cup, tbsp, oz vb.) Türk karşılıklarına çevir (su bardağı, yemek kaşığı, gram vb.).

Format:
{
  "translations": ["türkçe metin", ...]
}

Çevrilecek Metinler:
${jsonEncode(textsToTranslate)}
''';

      final responseText = await _generate(prompt);

      if (responseText.isNotEmpty) {
        // Remove code block markdown if present
        final String cleanJson = responseText
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        final Map<String, dynamic> jsonResponse = jsonDecode(cleanJson);
        final List<dynamic> translations = jsonResponse['translations'] ?? [];

        if (translations.length == textsToTranslate.length) {
          for (int i = 0; i < unchachedIndices.length; i++) {
            final translatedText = translations[i].toString();
            final originalText = textsToTranslate[i];
            
            // Cache'e kaydet
            _textCache[originalText] = translatedText;
            
            // Sonuçları yerleştir
            results[unchachedIndices[i]] = translatedText;
          }
        } else {
          // Sayı uyuşmazlığı olursa orijinal metinleri kullan
          for (int i = 0; i < unchachedIndices.length; i++) {
            results[unchachedIndices[i]] = textsToTranslate[i];
          }
        }
      }
    } catch (e) {
      debugPrint('Groq Çeviri Hatası (translateTexts): $e');
      // Hata durumunda cache'de olmayanları orijinal haliyle bırak
      for (int i = 0; i < unchachedIndices.length; i++) {
        results[unchachedIndices[i]] = textsToTranslate[i];
      }
    }

    return results;
  }

  /// Besin listesinin sadece isimlerini ve tiplerini çevirir.
  /// Açıklama, alerjen, porsiyon detayları detay ekranı açıldığında çevrilir.
  /// Payload ~%90 küçülür → güvenilir JSON yanıtı.
  Future<void> translateFoodItems(List<FoodItem> foods, {bool isTurkish = true}) async {
    if (foods.isEmpty) return;

    if (!isTurkish) {
      for (var food in foods) {
        food.foodNameTr = food.foodName;
        food.foodDescriptionTr = food.foodDescription;
        food.foodTypeTr = food.foodType;
        food.subCategoriesTr = List.from(food.subCategories);
        food.allergensTr = List.from(food.allergens);
        for (var s in food.servings) {
          s.servingDescriptionTr = s.servingDescription;
        }
      }
      return;
    }

    // Sadece henüz çevrilmemiş öğeleri al
    final needsTranslation = foods
        .where((f) => f.foodNameTr == f.foodName)
        .toList();

    if (needsTranslation.isEmpty) return;

    // foodType yerel olarak çevrilir — API israfı yok
    for (var food in needsTranslation) {
      food.foodTypeTr = _translateFoodType(food.foodType);
    }

    // İsimleri 20'li batch'ler halinde sırayla çevir (rate limit tetiklenmemesi için sequential olarak)
    const batchSize = 20;
    for (int i = 0; i < needsTranslation.length; i += batchSize) {
      final batch = needsTranslation.sublist(
        i, (i + batchSize).clamp(0, needsTranslation.length));
      await _translateNamesBatch(batch);
    }
  }

  /// Generic/Brand gibi tipleri API çağrısı yapmadan çevirir.
  String _translateFoodType(String type) {
    switch (type.toLowerCase()) {
      case 'generic': return 'Genel';
      case 'brand':   return 'Markalı';
      default:        return type;
    }
  }

  /// Sadece isimleri çevirir. Basit array in → array out formatı.
  Future<void> _translateNamesBatch(List<FoodItem> items) async {
    if (items.isEmpty) return;
    try {
      final names = items.map((f) => f.foodName).toList();
      final prompt =
          'Translate these food names from English to Turkish. '
          'Return ONLY a valid JSON array with the same number of items in the same order. '
          'Example: ["Rice Bread","Egg"] → ["Pirinç Ekmeği","Yumurta"]\n\n'
          'Names: ${jsonEncode(names)}';

      final responseText = await _generate(prompt);
      if (responseText.isEmpty) return;

      // Temizle ve parse et
      final raw = responseText
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      // İlk '[' ile son ']' arasını al
      final start = raw.indexOf('[');
      final end = raw.lastIndexOf(']');
      if (start == -1 || end == -1 || end <= start) {
        debugPrint('Çeviri: Geçerli JSON array bulunamadı → ${raw.substring(0, raw.length.clamp(0, 100))}');
        return;
      }

      final List<dynamic> translations = jsonDecode(raw.substring(start, end + 1));

      if (translations.length != items.length) {
        debugPrint('Çeviri: Boyut uyuşmazlığı (${translations.length} vs ${items.length})');
        return;
      }

      for (int i = 0; i < items.length; i++) {
        final tr = translations[i]?.toString();
        if (tr != null && tr.isNotEmpty) {
          items[i].foodNameTr = tr;
        }
      }
    } catch (e) {
      debugPrint('_translateNamesBatch HATA: $e');
      debugPrint('  Çevirilecek isimler: ${items.map((f) => f.foodName).toList()}');
    }
  }

  /// Detay sayfası açıldığında çağrılır: açıklama, alerjenler ve tüm porsiyon tanımları Türkçeye çevrilir.
  /// Zaten çevrildiyse API'ye gidilmez.
  Future<void> translateFoodDetail(FoodItem food, {bool isTurkish = true}) async {
    if (!isTurkish) {
      food.foodDescriptionTr = food.foodDescription;
      food.allergensTr = List.from(food.allergens);
      for (var s in food.servings) {
        s.servingDescriptionTr = s.servingDescription;
      }
      return;
    }

    final descNeedsTranslation = food.foodDescriptionTr == food.foodDescription &&
        food.foodDescription.isNotEmpty;
    final allergensNeedTranslation = food.allergens.isNotEmpty &&
        food.allergensTr.isNotEmpty &&
        food.allergensTr.first == food.allergens.first;

    final servingsToTranslate = food.servings
        .where((s) => s.servingDescriptionTr == s.servingDescription && s.servingDescription.isNotEmpty)
        .toList();

    if (!descNeedsTranslation && !allergensNeedTranslation && servingsToTranslate.isEmpty) return;

    try {
      final parts = <String>[];
      if (descNeedsTranslation) parts.add(food.foodDescription);
      if (allergensNeedTranslation) parts.addAll(food.allergens);
      for (var s in servingsToTranslate) {
        parts.add(s.servingDescription);
      }

      if (parts.isEmpty) return;

      final prompt =
          'Translate these food-related English texts to Turkish. '
          'Translate serving sizes (like "1 cup", "1 slice", "1 container") to their natural Turkish equivalents '
          '(like "1 su bardağı", "1 dilim", "1 paket/kase"). '
          'Return ONLY a valid JSON array with the same number of items in the same order.\n\n'
          'Texts: ${jsonEncode(parts)}';

      final responseText = await _generate(prompt);
      if (responseText.isEmpty) return;

      final raw = responseText
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final start = raw.indexOf('[');
      final end = raw.lastIndexOf(']');
      if (start == -1 || end == -1 || end <= start) return;

      final List<dynamic> translations =
          jsonDecode(raw.substring(start, end + 1));
      if (translations.length != parts.length) return;

      int idx = 0;
      if (descNeedsTranslation) {
        food.foodDescriptionTr = translations[idx]?.toString() ?? food.foodDescription;
        idx++;
      }
      if (allergensNeedTranslation) {
        food.allergensTr = translations
            .sublist(idx, idx + food.allergens.length)
            .map((e) => e?.toString() ?? '')
            .where((e) => e.isNotEmpty)
            .toList();
        idx += food.allergens.length;
      }
      for (var s in servingsToTranslate) {
        if (idx < translations.length) {
          s.servingDescriptionTr = translations[idx]?.toString() ?? s.servingDescription;
          idx++;
        }
      }
    } catch (e) {
      debugPrint('translateFoodDetail hata: $e');
    }
  }

  /// Kategori objelerinin listesini Türkçeye çevirir.
  /// Kategoriler bir kez çevrilince bir daha API'ye gidilmez.
  Future<void> translateCategories(List<FoodCategory> categories, {bool isTurkish = true}) async {
    if (categories.isEmpty || _categoriesTranslated) return;

    if (!isTurkish) {
      for (var cat in categories) {
        cat.categoryNameTr = cat.categoryName;
      }
      _categoriesTranslated = true;
      return;
    }

    final List<Map<String, String>> requests = [];
    for (var cat in categories) {
      if (cat.categoryNameTr == cat.categoryName) {
         requests.add({
           'id': cat.categoryId.toString(),
           'name': cat.categoryName,
         });
      }
    }

    if (requests.isEmpty) return;

    try {
      final prompt = '''
Sen bir beslenme terimleri çevirmenisin.
Aşağıda verilen yiyecek kategori isimlerini ("name") İngilizceden Türkçeye tam uyumlu ve kısa şekilde çevir.
Örnek: "Baked Goods" -> "Unlu Mamüller", "Beverages" -> "İçecekler".
SADECE GEÇERLİ JSON FORMATINDA YANIT VER.

Örnek Yanıt:
{
  "results": [
    {"id": "1", "name_tr": "Unlu Mamüller"}
  ]
}

Çevrilecek Kategoriler:
${jsonEncode(requests)}
''';

      final responseText = await _generate(prompt);

      if (responseText.isNotEmpty) {
        final String cleanJson = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
        final Map<String, dynamic> jsonResponse = jsonDecode(cleanJson);
        final List<dynamic> results = jsonResponse['results'] ?? [];
        
        final transMap = {
          for (var item in results)
            item['id'].toString(): item['name_tr']?.toString() ?? ''
        };

        for (var cat in categories) {
          if (transMap.containsKey(cat.categoryId.toString())) {
            cat.categoryNameTr = transMap[cat.categoryId.toString()]!;
          }
        }
        _categoriesTranslated = true;
      }
    } catch (e) {
      debugPrint('Groq Çeviri Hatası (translateCategories): $e');
    }
  }

  Future<String> translateToEnglish(String query) async {
    if (query.trim().isEmpty) return query;
    if (_textCache.containsKey('toEng_$query')) {
      return _textCache['toEng_$query']!;
    }
    try {
      final prompt = '''
Sen uzman bir çevirmensin. Verilen yiyecek veya yemek adının dilini algıla.
Yukarıda belirtildiği gibi, yiyecek veya yemek adını tamamen İngilizceye çevir. 
Eğer zaten İngilizce ise veya evrensel bir markaysa orijinal metni olduğu gibi bırak.

SADECE aşağıdaki JSON formatında yanıt ver:
{
  "translation": "translated or original text"
}

Metin: $query
''';

      final responseText = await _generate(prompt);

      if (responseText.isNotEmpty) {
        final cleanJson = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
        try {
          final Map<String, dynamic> jsonResponse = jsonDecode(cleanJson);
          final result = jsonResponse['translation']?.toString().trim();
          if (result != null && result.isNotEmpty) {
            _textCache['toEng_$query'] = result;
            return result;
          }
        } catch (e) {
          final result = cleanJson;
          _textCache['toEng_$query'] = result;
          return result;
        }
      }
    } catch (e) {
      debugPrint('Groq Çeviri Hatası (translateToEnglish): $e');
    }
    return query;
  }
}
