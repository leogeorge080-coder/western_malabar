class Product {
  final String id; // uuid
  final String name;
  final String slug;
  final String? description;
  final String? categoryId; // uuid
  final String? brandId; // uuid
  final List<String> images; // urls
  final bool isActive;
  final DateTime createdAt;
  final int? priceCents;
  final int? salePriceCents;

  const Product({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.categoryId,
    this.brandId,
    this.images = const [],
    required this.isActive,
    required this.createdAt,
    this.priceCents,
    this.salePriceCents,
  });

  factory Product.fromMap(Map<String, dynamic> m) {
    final imgs = <String>[];
    final raw = m['images'];
    if (raw is List) {
      for (final e in raw) {
        if (e is String) imgs.add(e);
      }
    } else if (raw is String) {
      imgs.add(raw);
    }
    return Product(
      id: m['id'] as String,
      name: m['name'] as String,
      slug: m['slug'] as String,
      description: m['description'] as String?,
      categoryId: m['category_id'] as String?,
      brandId: m['brand_id'] as String?,
      images: imgs,
      isActive: (m['is_active'] as bool?) ?? true,
      createdAt: DateTime.parse(m['created_at'] as String),
      priceCents: m['price_cents'] as int?,
      salePriceCents: m['sale_price_cents'] as int?,
    );
  }

  /// Convenience getters
  double? get price => priceCents == null ? null : (priceCents! / 100.0);
  double? get salePrice =>
      salePriceCents == null ? null : (salePriceCents! / 100.0);

  String get displayPrice {
    final p = salePrice ?? price;
    return p == null ? '£—' : '£${p.toStringAsFixed(2)}';
  }

  String? get firstImageUrl => images.isNotEmpty ? images.first : null;
}
