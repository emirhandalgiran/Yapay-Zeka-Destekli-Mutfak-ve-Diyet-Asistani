/// FatSecret API'den dönen yiyecek modeli
class FoodItem {
  final int foodId;
  final String foodName;
  final String foodDescription;
  final String foodType; // 'Generic' veya 'Brand'
  String foodTypeTr; // Groq API'den asenkron çeviri
  final String? brandName;
  final String? imageUrl;
  final List<FoodServing> servings;
  final List<String> subCategories;
  List<String> subCategoriesTr;
  
  // Asenkron olarak gelecek Türkçe çeviriler.
  String foodNameTr;
  String foodDescriptionTr;
  
  final List<String> allergens;
  List<String> allergensTr;

  FoodItem({
    required this.foodId,
    required this.foodName,
    required this.foodDescription,
    required this.foodType,
    required this.foodTypeTr,
    this.brandName,
    this.imageUrl,
    this.servings = const [],
    this.subCategories = const [],
    required this.subCategoriesTr,
    this.allergens = const [],
    required this.allergensTr,
    required this.foodNameTr,
    required this.foodDescriptionTr,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    // Description ve Name alanlarını olduğu gibi al
    final name = json['food_name'] as String? ?? '';
    var description = json['food_description'] as String? ?? '';
    final type = json['food_type']?.toString() ?? 'Generic';

    // Açıklamanın başındaki porsiyon miktarını al
    if (description.contains('-')) {
      description = description.split('-').first.trim();
    }

    // Servings parse
    List<FoodServing> servings = [];
    final servingsData = json['servings'];
    if (servingsData != null) {
      final servingList = servingsData is Map
          ? (servingsData['serving'] is List
              ? servingsData['serving'] as List
              : [servingsData['serving']])
          : [];
      servings = servingList
          .where((s) => s != null)
          .map((s) => FoodServing.fromJson(s as Map<String, dynamic>))
          .toList();
    }

    // Sub categories parse
    List<String> subCategories = [];
    final subCatsData = json['food_sub_categories'];
    if (subCatsData != null) {
      final catList = subCatsData is Map
          ? (subCatsData['food_sub_category'] is List
              ? subCatsData['food_sub_category'] as List
              : [subCatsData['food_sub_category']])
          : [];
      subCategories = catList
          .where((c) => c != null)
          .map((c) => c.toString())
          .toList();
    }

    // Allergens parse
    List<String> allergens = [];
    final allergensData = json['allergens'];
    if (allergensData != null) {
      final aList = allergensData is Map
          ? (allergensData['allergen'] is List
              ? allergensData['allergen'] as List
              : [allergensData['allergen']])
          : [];
      allergens = aList
          .where((a) => a != null)
          .map((a) => a is Map ? (a['name']?.toString() ?? '') : a.toString())
          .toList();
    }

    // Görsel
    String? imageUrl;
    final imageData = json['food_images'];
    if (imageData != null) {
      final imgList = imageData is Map
          ? (imageData['food_image'] is List
              ? imageData['food_image'] as List
              : [imageData['food_image']])
          : [];
      if (imgList.isNotEmpty && imgList.first != null) {
        imageUrl = (imgList.first as Map<String, dynamic>)['image_url']?.toString();
      }
    }

    return FoodItem(
      foodId: int.tryParse(json['food_id']?.toString() ?? '0') ?? 0,
      foodName: name,
      foodNameTr: name,
      foodDescription: description,
      foodDescriptionTr: description,
      foodType: type,
      foodTypeTr: type, // Groq çevirene kadar orjinal
      brandName: json['brand_name']?.toString(),
      imageUrl: imageUrl, 
      servings: servings,
      subCategories: subCategories,
      subCategoriesTr: List.from(subCategories), // Çevrilene kadar orjinal liste
      allergens: allergens,
      allergensTr: List.from(allergens), // Çevrilene kadar orjinal liste
    );
  }
}

/// Porsiyon/besin değeri modeli
class FoodServing {
  final int servingId;
  final String servingDescription;
  String servingDescriptionTr;
  final String metricServingAmount;
  final String metricServingUnit;
  final double calories;
  final double fat;
  final double saturatedFat;
  final double carbohydrate;
  final double fiber;
  final double sugar;
  final double protein;
  final double sodium;
  final double cholesterol;

  FoodServing({
    required this.servingId,
    required this.servingDescription,
    required this.servingDescriptionTr,
    required this.metricServingAmount,
    required this.metricServingUnit,
    required this.calories,
    required this.fat,
    required this.saturatedFat,
    required this.carbohydrate,
    required this.fiber,
    required this.sugar,
    required this.protein,
    required this.sodium,
    required this.cholesterol,
  });

  factory FoodServing.fromJson(Map<String, dynamic> json) {
    final desc = json['serving_description']?.toString() ?? '';
    return FoodServing(
      servingId: int.tryParse(json['serving_id']?.toString() ?? '0') ?? 0,
      servingDescription: desc,
      servingDescriptionTr: desc, // Groq API
      metricServingAmount: json['metric_serving_amount']?.toString() ?? '',
      metricServingUnit: json['metric_serving_unit']?.toString() ?? '',
      calories: double.tryParse(json['calories']?.toString() ?? '0') ?? 0,
      fat: double.tryParse(json['fat']?.toString() ?? '0') ?? 0,
      saturatedFat: double.tryParse(json['saturated_fat']?.toString() ?? '0') ?? 0,
      carbohydrate: double.tryParse(json['carbohydrate']?.toString() ?? '0') ?? 0,
      fiber: double.tryParse(json['fiber']?.toString() ?? '0') ?? 0,
      sugar: double.tryParse(json['sugar']?.toString() ?? '0') ?? 0,
      protein: double.tryParse(json['protein']?.toString() ?? '0') ?? 0,
      sodium: double.tryParse(json['sodium']?.toString() ?? '0') ?? 0,
      cholesterol: double.tryParse(json['cholesterol']?.toString() ?? '0') ?? 0,
    );
  }
}
