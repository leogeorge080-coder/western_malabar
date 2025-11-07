class CategoryModel {
  final String id;
  final String name;
  final String slug;
  final String? icon;
  final int sortOrder;
  final bool isActive;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
    required this.sortOrder,
    required this.isActive,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> m) => CategoryModel(
        id: m['id'] as String,
        name: m['name'] as String,
        slug: m['slug'] as String,
        icon: m['icon'] as String?,
        sortOrder: (m['sort_order'] as int?) ?? 0,
        isActive: (m['is_active'] as bool?) ?? true,
      );
}
