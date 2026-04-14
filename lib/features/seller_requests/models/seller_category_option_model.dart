class SellerCategoryOptionModel {
  final String id;
  final String name;
  final String? slug;

  const SellerCategoryOptionModel({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory SellerCategoryOptionModel.fromMap(Map<String, dynamic> map) {
    return SellerCategoryOptionModel(
      id: map['id'] as String,
      name: (map['name'] ?? '') as String,
      slug: map['slug'] as String?,
    );
  }
}
