class ProductModel {
  final String id;
  final String name;
  final String? brandName;
  final String? image;
  final int? priceCents;
  final int? salePriceCents;
  final double? avgRating;
  final int? ratingCount;
  final String? categoryName;
  final String? categorySlug;
  final bool isFrozen;
  final String? barcode;

  const ProductModel({
    required this.id,
    required this.name,
    this.brandName,
    this.image,
    this.priceCents,
    this.salePriceCents,
    this.avgRating,
    this.ratingCount,
    this.categoryName,
    this.categorySlug,
    this.isFrozen = false,
    this.barcode,
  });

  ProductModel copyWith({
    String? id,
    String? name,
    String? brandName,
    String? image,
    int? priceCents,
    int? salePriceCents,
    double? avgRating,
    int? ratingCount,
    String? categoryName,
    String? categorySlug,
    bool? isFrozen,
    String? barcode,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      brandName: brandName ?? this.brandName,
      image: image ?? this.image,
      priceCents: priceCents ?? this.priceCents,
      salePriceCents: salePriceCents ?? this.salePriceCents,
      avgRating: avgRating ?? this.avgRating,
      ratingCount: ratingCount ?? this.ratingCount,
      categoryName: categoryName ?? this.categoryName,
      categorySlug: categorySlug ?? this.categorySlug,
      isFrozen: isFrozen ?? this.isFrozen,
      barcode: barcode ?? this.barcode,
    );
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as String,
      name: map['name'] as String,
      brandName: map['brand_name'] as String?,
      image: map['image'] as String?,
      priceCents: map['price_cents'] as int?,
      salePriceCents: map['sale_price_cents'] as int?,
      avgRating: map['avg_rating'] != null
          ? (map['avg_rating'] as num).toDouble()
          : null,
      ratingCount: map['rating_count'] as int?,
      categoryName: map['category_name'] as String?,
      categorySlug: map['category_slug'] as String?,
      isFrozen: map['is_frozen'] as bool? ?? false,
      barcode: map['barcode'] as String?,
    );
  }
}
