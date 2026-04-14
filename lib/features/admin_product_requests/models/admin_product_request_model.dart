import 'package:western_malabar/features/seller_requests/models/seller_product_request_model.dart';

class AdminProductRequestModel extends SellerProductRequestModel {
  final String? sellerName;
  final String? sellerEmail;

  const AdminProductRequestModel({
    required super.id,
    required super.sellerId,
    required super.productName,
    required super.normalizedName,
    required super.slug,
    required super.categoryId,
    required super.brandId,
    required super.description,
    required super.barcode,
    required super.requestedImages,
    required super.requestedImageUrl,
    required super.requestedPriceCents,
    required super.requestedSalePriceCents,
    required super.status,
    required super.duplicateStatus,
    required super.duplicateConfidence,
    required super.suggestedProductId,
    required super.issueFlags,
    required super.reviewSummary,
    required super.adminNote,
    required super.createdAt,
    required super.reviewedAt,
    this.sellerName,
    this.sellerEmail,
  });

  factory AdminProductRequestModel.fromMap(Map<String, dynamic> map) {
    final base = SellerProductRequestModel.fromMap(map);

    final sellerProfileRaw = map['seller_profile'];
    final sellerProfile = sellerProfileRaw is Map
        ? Map<String, dynamic>.from(sellerProfileRaw)
        : null;

    return AdminProductRequestModel(
      id: base.id,
      sellerId: base.sellerId,
      productName: base.productName,
      normalizedName: base.normalizedName,
      slug: base.slug,
      categoryId: base.categoryId,
      brandId: base.brandId,
      description: base.description,
      barcode: base.barcode,
      requestedImages: base.requestedImages,
      requestedImageUrl: base.requestedImageUrl,
      requestedPriceCents: base.requestedPriceCents,
      requestedSalePriceCents: base.requestedSalePriceCents,
      status: base.status,
      duplicateStatus: base.duplicateStatus,
      duplicateConfidence: base.duplicateConfidence,
      suggestedProductId: base.suggestedProductId,
      issueFlags: base.issueFlags,
      reviewSummary: base.reviewSummary,
      adminNote: base.adminNote,
      createdAt: base.createdAt,
      reviewedAt: base.reviewedAt,
      sellerName: (sellerProfile?['full_name'] as String?)?.trim(),
      sellerEmail: (sellerProfile?['email'] as String?)?.trim(),
    );
  }

  String get sellerDisplayName {
    final name = (sellerName ?? '').trim();
    if (name.isNotEmpty) return name;

    final email = (sellerEmail ?? '').trim();
    if (email.isNotEmpty) return email;

    return sellerId;
  }

  String get sellerShortId {
    if (sellerId.length <= 12) return sellerId;
    return '${sellerId.substring(0, 8)}...';
  }
}
