/// FatSecret API'den dönen kategori modeli
class FoodCategory {
  final int categoryId;
  final String categoryName;
  String categoryNameTr;
  final String? categoryDescription;

  FoodCategory({
    required this.categoryId,
    required this.categoryName,
    required this.categoryNameTr,
    this.categoryDescription,
  });

  factory FoodCategory.fromJson(Map<String, dynamic> json) {
    final name = json['food_category_name']?.toString() ?? '';
    return FoodCategory(
      categoryId: int.tryParse(json['food_category_id']?.toString() ?? '0') ?? 0,
      categoryName: name,
      categoryNameTr: name, // Groq ile çevrilecek
      categoryDescription: json['food_category_description']?.toString(),
    );
  }
}
