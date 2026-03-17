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
      id: map['id'] as String,
      orderId: map['order_id'] as String,
      productId: map['product_id'] as String?,
      productName: (map['product_name'] as String?) ?? 'Unknown Product',
      brandName: map['brand_name'] as String?,
      image: map['image'] as String?,
      qty: map['qty'] as int? ?? 1,
      unitPriceCents: map['unit_price_cents'] as int?,
      lineTotalCents: map['line_total_cents'] as int?,
      isFrozen: map['is_frozen'] as bool? ?? false,
      pickingStatus: (map['picking_status'] as String?) ?? 'pending',
      pickedQty: map['picked_qty'] as int? ?? 0,
      packedQty: map['packed_qty'] as int? ?? 0,
      pickedAt: map['picked_at'] != null
          ? DateTime.tryParse(map['picked_at'] as String)
          : null,
      packedAt: map['packed_at'] != null
          ? DateTime.tryParse(map['packed_at'] as String)
          : null,
    );
  }
}




