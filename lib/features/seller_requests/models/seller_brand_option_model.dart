class SellerBrandOptionModel {
  final String id;
  final String name;
  final String? slug;

  const SellerBrandOptionModel({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory SellerBrandOptionModel.fromMap(Map<String, dynamic> map) {
    return SellerBrandOptionModel(
      id: map['id'] as String,
      name: (map['name'] ?? '') as String,
      slug: map['slug'] as String?,
    );
  }
}
