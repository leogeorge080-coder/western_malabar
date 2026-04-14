class OrderItemModel {
  final String id;
  final String orderId;
  final String productId;
  final String productName;
  final String? brandName;
  final String? image;
  final int unitPriceCents;
  final int qty;
  final int lineTotalCents;

  const OrderItemModel({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.brandName,
    required this.image,
    required this.unitPriceCents,
    required this.qty,
    required this.lineTotalCents,
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      id: (map['id'] ?? '').toString(),
      orderId: (map['order_id'] ?? '').toString(),
      productId: (map['product_id'] ?? '').toString(),
      productName: (map['product_name'] ?? '').toString(),
      brandName: map['brand_name']?.toString(),
      image: map['image']?.toString(),
      unitPriceCents: (map['unit_price_cents'] as num?)?.toInt() ?? 0,
      qty: (map['qty'] as num?)?.toInt() ?? 0,
      lineTotalCents: (map['line_total_cents'] as num?)?.toInt() ?? 0,
    );
  }

  String get unitPriceFormatted =>
      '£${(unitPriceCents / 100).toStringAsFixed(2)}';

  String get lineTotalFormatted =>
      '£${(lineTotalCents / 100).toStringAsFixed(2)}';
}
