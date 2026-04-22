class AdminProductEditModel {
  final String id;
  final String name;
  final String slug;
  final String? brandId;
  final String? categoryId;
  final List<String> images;
  final String? description;
  final bool isActive;
  final bool isAvailable;
  final bool isFrozen;
  final String? barcode;
  final bool isWeeklyDeal;
  final int? dealPriceCents;
  final DateTime? dealStartsAt;
  final DateTime? dealEndsAt;
  final String? dealBadgeText;
  final int? priceCents;
  final int? salePriceCents;
  final int? sellerBasePriceCents;
  final String? firstVariantId;
  final int? availableQty;
  final int? stockQty;

  const AdminProductEditModel({
    required this.id,
    required this.name,
    required this.slug,
    this.brandId,
    this.categoryId,
    required this.images,
    required this.isActive,
    required this.isAvailable,
    required this.isFrozen,
    this.description,
    this.barcode,
    this.isWeeklyDeal = false,
    this.dealPriceCents,
    this.dealStartsAt,
    this.dealEndsAt,
    this.dealBadgeText,
    this.priceCents,
    this.salePriceCents,
    this.sellerBasePriceCents,
    this.firstVariantId,
    this.availableQty,
    this.stockQty,
  });

  factory AdminProductEditModel.fromMap(Map<String, dynamic> map) {
    final rawImages = map['images'];
    final List<String> parsedImages;

    if (rawImages is List) {
      parsedImages = rawImages.map((e) => e.toString()).toList();
    } else {
      parsedImages = const [];
    }

    final variants = (map['product_variants'] as List?) ?? const [];
    final firstVariant = variants.isNotEmpty
        ? Map<String, dynamic>.from(variants.first as Map)
        : null;

    final variantPrice = (firstVariant?['price_cents'] as num?)?.toInt();
    final fallbackBase = (map['seller_base_price_cents'] as num?)?.toInt();

    return AdminProductEditModel(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      slug: map['slug'] as String? ?? '',
      brandId: map['brand_id'] as String?,
      categoryId: map['category_id'] as String?,
      images: parsedImages,
      description: map['description'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      isAvailable: map['is_available'] as bool? ?? true,
      isFrozen: map['is_frozen'] as bool? ?? false,
      barcode: map['barcode'] as String?,
      isWeeklyDeal: map['is_weekly_deal'] as bool? ?? false,
      dealPriceCents: (map['deal_price_cents'] as num?)?.toInt(),
      dealStartsAt: map['deal_starts_at'] != null
          ? DateTime.tryParse(map['deal_starts_at'].toString())
          : null,
      dealEndsAt: map['deal_ends_at'] != null
          ? DateTime.tryParse(map['deal_ends_at'].toString())
          : null,
      dealBadgeText: map['deal_badge_text'] as String?,
      priceCents: variantPrice ?? fallbackBase,
      salePriceCents: (firstVariant?['sale_price_cents'] as num?)?.toInt(),
      sellerBasePriceCents: fallbackBase,
      firstVariantId: firstVariant?['id']?.toString(),
      availableQty: (map['available_qty'] as num?)?.toInt(),
      stockQty: (map['stock_qty'] as num?)?.toInt() ??
          (firstVariant?['stock_qty'] as num?)?.toInt(),
    );
  }

  AdminProductEditModel copyWith({
    String? id,
    String? name,
    String? slug,
    String? brandId,
    String? categoryId,
    List<String>? images,
    String? description,
    bool? isActive,
    bool? isAvailable,
    bool? isFrozen,
    String? barcode,
    bool? isWeeklyDeal,
    int? dealPriceCents,
    DateTime? dealStartsAt,
    DateTime? dealEndsAt,
    String? dealBadgeText,
    int? priceCents,
    int? salePriceCents,
    int? sellerBasePriceCents,
    String? firstVariantId,
    int? availableQty,
    int? stockQty,
  }) {
    return AdminProductEditModel(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      brandId: brandId ?? this.brandId,
      categoryId: categoryId ?? this.categoryId,
      images: images ?? this.images,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      isAvailable: isAvailable ?? this.isAvailable,
      isFrozen: isFrozen ?? this.isFrozen,
      barcode: barcode ?? this.barcode,
      isWeeklyDeal: isWeeklyDeal ?? this.isWeeklyDeal,
      dealPriceCents: dealPriceCents ?? this.dealPriceCents,
      dealStartsAt: dealStartsAt ?? this.dealStartsAt,
      dealEndsAt: dealEndsAt ?? this.dealEndsAt,
      dealBadgeText: dealBadgeText ?? this.dealBadgeText,
      priceCents: priceCents ?? this.priceCents,
      salePriceCents: salePriceCents ?? this.salePriceCents,
      sellerBasePriceCents: sellerBasePriceCents ?? this.sellerBasePriceCents,
      firstVariantId: firstVariantId ?? this.firstVariantId,
      availableQty: availableQty ?? this.availableQty,
      stockQty: stockQty ?? this.stockQty,
    );
  }

  bool get hasImage => images.isNotEmpty && images.first.trim().isNotEmpty;
  bool get hasBarcode => (barcode ?? '').trim().isNotEmpty;

  bool get hasDeal =>
      isWeeklyDeal && dealPriceCents != null && dealPriceCents! > 0;

  int? get originalPriceCents {
    if (priceCents != null && priceCents! > 0) return priceCents;
    if (sellerBasePriceCents != null && sellerBasePriceCents! > 0) {
      return sellerBasePriceCents;
    }
    return null;
  }

  int? get effectiveDisplayPriceCents {
    if (hasDeal) return dealPriceCents;
    if (salePriceCents != null && salePriceCents! > 0) return salePriceCents;
    return originalPriceCents;
  }

  int get completenessScore {
    int score = 0;
    if (hasImage) score++;
    if (hasBarcode) score++;
    return score;
  }
}

class AdminBrandOption {
  final String id;
  final String name;
  final String slug;

  const AdminBrandOption({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory AdminBrandOption.fromMap(Map<String, dynamic> map) {
    return AdminBrandOption(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      slug: map['slug'] as String? ?? '',
    );
  }
}

class AdminCategoryOption {
  final String id;
  final String name;
  final String slug;
  final String? parentId;

  const AdminCategoryOption({
    required this.id,
    required this.name,
    required this.slug,
    this.parentId,
  });

  factory AdminCategoryOption.fromMap(Map<String, dynamic> map) {
    return AdminCategoryOption(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      slug: map['slug'] as String? ?? '',
      parentId: map['parent_id'] as String?,
    );
  }
}
