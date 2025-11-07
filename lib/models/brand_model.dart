class BrandModel {
  final String id;
  final String name;
  final String slug;
  final bool isActive;

  BrandModel(
      {required this.id,
      required this.name,
      required this.slug,
      required this.isActive});

  factory BrandModel.fromMap(Map<String, dynamic> m) => BrandModel(
        id: m['id'],
        name: m['name'],
        slug: m['slug'],
        isActive: m['is_active'] ?? true,
      );
}
