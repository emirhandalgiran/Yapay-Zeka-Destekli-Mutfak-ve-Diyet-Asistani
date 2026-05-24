/// FatSecret API'den dönen marka modeli
class FoodBrand {
  final int brandId;
  final String brandName;
  final String brandType;

  FoodBrand({
    required this.brandId,
    required this.brandName,
    required this.brandType,
  });

  factory FoodBrand.fromJson(Map<String, dynamic> json) {
    return FoodBrand(
      brandId: int.tryParse(json['brand_id']?.toString() ?? '0') ?? 0,
      brandName: json['brand_name']?.toString() ?? '',
      brandType: json['brand_type']?.toString() ?? '',
    );
  }
}
