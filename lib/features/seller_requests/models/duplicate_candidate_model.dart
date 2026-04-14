class DuplicateCandidateModel {
  final String productId;
  final String productName;
  final String? productSlug;
  final String? barcode;
  final double similarityScore;
  final String reason;

  const DuplicateCandidateModel({
    required this.productId,
    required this.productName,
    required this.productSlug,
    required this.barcode,
    required this.similarityScore,
    required this.reason,
  });

  factory DuplicateCandidateModel.fromMap(Map<String, dynamic> map) {
    return DuplicateCandidateModel(
      productId: map['product_id'] as String,
      productName: (map['product_name'] ?? '') as String,
      productSlug: map['product_slug'] as String?,
      barcode: map['barcode'] as String?,
      similarityScore: ((map['similarity_score'] ?? 0) as num).toDouble(),
      reason: (map['reason'] ?? '') as String,
    );
  }
}
