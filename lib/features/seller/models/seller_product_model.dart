class SellerVariantModel {
  final String id;
  final String? sku;
  final int priceCents;
  final int? salePriceCents;
  final int stockQty;

  const SellerVariantModel({
    required this.id,
    required this.sku,
    required this.priceCents,
    required this.salePriceCents,
    required this.stockQty,
  });

  int get effectivePriceCents => salePriceCents ?? priceCents;

  factory SellerVariantModel.fromMap(Map<String, dynamic> map) {
    return SellerVariantModel(
      id: map['id'] as String,
      sku: map['sku'] as String?,
      priceCents: (map['price_cents'] ?? 0) as int,
      salePriceCents: map['sale_price_cents'] as int?,
      stockQty: (map['stock_qty'] ?? 0) as int,
    );
  }
}

class SellerProductModel {
  final String id;
  final String name;
  final String slug;
  final bool isAvailable;
  final int availableQty;
  final String? sellerNotes;
  final bool priceChangeLocked;
  final List<SellerVariantModel> variants;
  final String? barcode;
  final List<String>? images;

  const SellerProductModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.isAvailable,
    required this.availableQty,
    required this.sellerNotes,
    required this.priceChangeLocked,
    required this.variants,
    this.barcode,
    this.images,
  });

  SellerVariantModel? get primaryVariant =>
      variants.isEmpty ? null : variants.first;

  bool get canRequestPriceChange => priceChangeLocked && primaryVariant != null;

  factory SellerProductModel.fromMap(Map<String, dynamic> map) {
    final rawVariants = map['product_variants'];
    final variants = rawVariants is List
        ? rawVariants
            .map((e) =>
                SellerVariantModel.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList()
        : <SellerVariantModel>[];

    final rawImages = map['images'];
    final images = rawImages is List
        ? rawImages.map((e) => (e ?? '') as String).toList()
        : null;

    return SellerProductModel(
      id: map['id'] as String,
      name: (map['name'] ?? '') as String,
      slug: (map['slug'] ?? '') as String,
      isAvailable: (map['is_available'] ?? true) as bool,
      availableQty: (map['available_qty'] ?? 0) as int,
      sellerNotes: map['seller_notes'] as String?,
      priceChangeLocked: (map['price_change_locked'] ?? true) as bool,
      variants: variants,
      barcode: map['barcode'] as String?,
      images: images,
    );
  }
}
