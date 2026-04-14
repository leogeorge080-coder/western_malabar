class SellerProductRequestModel {
  final String id;
  final String sellerId;
  final String productName;
  final String? normalizedName;
  final String? slug;
  final String? categoryId;
  final String? brandId;
  final String? description;
  final String? barcode;
  final List<String> requestedImages;
  final String? requestedImageUrl;
  final int? requestedPriceCents;
  final int? requestedSalePriceCents;
  final String status;
  final String duplicateStatus;
  final double duplicateConfidence;
  final String? suggestedProductId;
  final List<String> issueFlags;
  final String? reviewSummary;
  final String? adminNote;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  const SellerProductRequestModel({
    required this.id,
    required this.sellerId,
    required this.productName,
    required this.normalizedName,
    required this.slug,
    required this.categoryId,
    required this.brandId,
    required this.description,
    required this.barcode,
    required this.requestedImages,
    required this.requestedImageUrl,
    required this.requestedPriceCents,
    required this.requestedSalePriceCents,
    required this.status,
    required this.duplicateStatus,
    required this.duplicateConfidence,
    required this.suggestedProductId,
    required this.issueFlags,
    required this.reviewSummary,
    required this.adminNote,
    required this.createdAt,
    required this.reviewedAt,
  });

  factory SellerProductRequestModel.fromMap(Map<String, dynamic> map) {
    final rawFlags = map['issue_flags'];
    final flags = rawFlags is List
        ? rawFlags.map((e) => e.toString()).toList()
        : <String>[];
    final rawImages = map['requested_images'];
    final images = rawImages is List
        ? rawImages
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList()
        : <String>[];

    return SellerProductRequestModel(
      id: map['id'] as String,
      sellerId: map['seller_id'] as String,
      productName: (map['product_name'] ?? '') as String,
      normalizedName: map['normalized_name'] as String?,
      slug: map['slug'] as String?,
      categoryId: map['category_id'] as String?,
      brandId: map['brand_id'] as String?,
      description: map['description'] as String?,
      barcode: map['barcode'] as String?,
      requestedImages: images,
      requestedImageUrl: map['requested_image_url'] as String? ??
          (images.isNotEmpty ? images.first : null),
      requestedPriceCents: (map['requested_price_cents'] as num?)?.toInt(),
      requestedSalePriceCents:
          (map['requested_sale_price_cents'] as num?)?.toInt(),
      status: (map['status'] ?? 'pending') as String,
      duplicateStatus: (map['duplicate_status'] ?? 'unchecked') as String,
      duplicateConfidence:
          ((map['duplicate_confidence'] ?? 0) as num).toDouble(),
      suggestedProductId: map['suggested_product_id'] as String?,
      issueFlags: flags,
      reviewSummary: map['review_summary'] as String?,
      adminNote: map['admin_note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      reviewedAt: map['reviewed_at'] == null
          ? null
          : DateTime.parse(map['reviewed_at'] as String),
    );
  }
}
