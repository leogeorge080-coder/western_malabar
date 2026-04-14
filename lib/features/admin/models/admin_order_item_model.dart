class AdminOrderItemModel {
  final String id;
  final String orderId;
  final String? productId;
  final String productName;
  final String? brandName;
  final String? image;
  final int qty;
  final int? unitPriceCents;
  final int? lineTotalCents;
  final bool isFrozen;
  final String pickingStatus;
  final int pickedQty;
  final int packedQty;
  final DateTime? pickedAt;
  final DateTime? packedAt;

  const AdminOrderItemModel({
    required this.id,
    required this.orderId,
    this.productId,
    required this.productName,
    this.brandName,
    this.image,
    required this.qty,
    this.unitPriceCents,
    this.lineTotalCents,
    this.isFrozen = false,
    this.pickingStatus = 'pending',
    this.pickedQty = 0,
    this.packedQty = 0,
    this.pickedAt,
    this.packedAt,
  });

  factory AdminOrderItemModel.fromMap(Map<String, dynamic> map) {
    return AdminOrderItemModel(
      id: (map['id'] ?? '').toString(),
      orderId: (map['order_id'] ?? '').toString(),
      productId: map['product_id']?.toString(),
      productName: (map['product_name'] ?? 'Unknown Product').toString(),
      brandName: map['brand_name']?.toString(),
      image: map['image']?.toString(),
      qty: (map['qty'] as num?)?.toInt() ?? 1,
      unitPriceCents: (map['unit_price_cents'] as num?)?.toInt(),
      lineTotalCents: (map['line_total_cents'] as num?)?.toInt(),
      isFrozen: map['is_frozen'] == true,
      pickingStatus: (map['picking_status'] ?? 'pending').toString(),
      pickedQty: (map['picked_qty'] as num?)?.toInt() ?? 0,
      packedQty: (map['packed_qty'] as num?)?.toInt() ?? 0,
      pickedAt: map['picked_at'] != null
          ? DateTime.tryParse(map['picked_at'].toString())
          : null,
      packedAt: map['packed_at'] != null
          ? DateTime.tryParse(map['packed_at'].toString())
          : null,
    );
  }
}
