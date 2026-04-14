class ProductModel {
  final String id;
  final String name;
  final String? brandName;
  final String? image;

  /// Base/original price
  final int? priceCents;

  /// Sale/discounted price if available
  final int? salePriceCents;

  final double? avgRating;
  final int? ratingCount;

  final String? categoryName;
  final String? categorySlug;

  final bool isFrozen;
  final String? barcode;

  final String? sellerId;
  final int? sellerBasePriceCents;
  final bool isWeeklyDeal;
  final String? dealBadgeText;

  /// Optional, useful for product detail / stock messaging / disabling add
  final int? stockQty;

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
    this.sellerId,
    this.sellerBasePriceCents,
    this.isWeeklyDeal = false,
    this.dealBadgeText,
    this.stockQty,
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
    String? sellerId,
    int? sellerBasePriceCents,
    bool? isWeeklyDeal,
    String? dealBadgeText,
    int? stockQty,
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
      sellerId: sellerId ?? this.sellerId,
      sellerBasePriceCents: sellerBasePriceCents ?? this.sellerBasePriceCents,
      isWeeklyDeal: isWeeklyDeal ?? this.isWeeklyDeal,
      dealBadgeText: dealBadgeText ?? this.dealBadgeText,
      stockQty: stockQty ?? this.stockQty,
    );
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      brandName: map['brand_name'] as String?,
      image: map['image'] as String?,
      priceCents: (map['price_cents'] as num?)?.toInt(),
      salePriceCents: (map['sale_price_cents'] as num?)?.toInt(),
      avgRating: map['avg_rating'] != null
          ? (map['avg_rating'] as num).toDouble()
          : null,
      ratingCount: (map['rating_count'] as num?)?.toInt(),
      categoryName: map['category_name'] as String?,
      categorySlug: map['category_slug'] as String?,
      isFrozen: map['is_frozen'] as bool? ?? false,
      barcode: map['barcode'] as String?,
      sellerId: map['seller_id'] as String?,
      sellerBasePriceCents: (map['seller_base_price_cents'] as num?)?.toInt(),
      isWeeklyDeal: map['is_weekly_deal'] as bool? ?? false,
      dealBadgeText: map['deal_badge_text'] as String?,
      stockQty: (map['stock_qty'] as num?)?.toInt(),
    );
  }

  // ----------------------------
  // Derived commerce helpers
  // ----------------------------

  bool get hasImage => image != null && image!.trim().isNotEmpty;

  bool get hasRatings => (ratingCount ?? 0) > 0 && avgRating != null;

  int get displayPriceCents {
    final sale = salePriceCents;
    if (sale != null && sale > 0) return sale;
    return priceCents ?? 0;
  }

  int? get originalPriceCents {
    if (hasDiscount) return priceCents;
    return null;
  }

  bool get hasDiscount {
    final base = priceCents;
    final sale = salePriceCents;
    if (base == null || sale == null) return false;
    if (base <= 0 || sale <= 0) return false;
    return sale < base;
  }

  int? get savingCents {
    if (!hasDiscount) return null;
    return priceCents! - salePriceCents!;
  }

  int? get discountPercent {
    if (!hasDiscount) return null;
    final base = priceCents!;
    final sale = salePriceCents!;
    if (base <= 0) return null;
    return (((base - sale) / base) * 100).round();
  }

  bool get inStock {
    final qty = stockQty;
    if (qty == null) return true; // optimistic fallback if stock unknown
    return qty > 0;
  }

  bool get isLowStock {
    final qty = stockQty;
    if (qty == null) return false;
    return qty > 0 && qty <= 5;
  }

  String get effectiveBrandName {
    final b = brandName?.trim();
    return (b == null || b.isEmpty) ? '' : b;
  }
}
