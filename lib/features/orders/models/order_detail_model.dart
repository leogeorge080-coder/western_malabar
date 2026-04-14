class OrderDetailModel {
  final String id;
  final String orderNumber;
  final DateTime? createdAt;
  final String customerName;
  final String phone;
  final String postcode;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String deliveryType;
  final String deliverySlot;
  final String paymentMethod;
  final String paymentStatus;
  final int subtotalCents;
  final int deliveryFeeCents;
  final int totalCents;
  final String status;
  final String adminStatus;
  final String deliveryStatus;
  final DateTime? packedAt;
  final DateTime? dispatchedAt;
  final DateTime? outForDeliveryAt;
  final DateTime? deliveredAt;
  final String displayStatus;

  const OrderDetailModel({
    required this.id,
    required this.orderNumber,
    required this.createdAt,
    required this.customerName,
    required this.phone,
    required this.postcode,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.deliveryType,
    required this.deliverySlot,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.subtotalCents,
    required this.deliveryFeeCents,
    required this.totalCents,
    required this.status,
    required this.adminStatus,
    required this.deliveryStatus,
    required this.packedAt,
    required this.dispatchedAt,
    required this.outForDeliveryAt,
    required this.deliveredAt,
    required this.displayStatus,
  });

  factory OrderDetailModel.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString())?.toLocal();
    }

    return OrderDetailModel(
      id: (map['id'] ?? '').toString(),
      orderNumber: (map['order_number'] ?? '').toString(),
      createdAt: parseDate(map['created_at']),
      customerName: (map['customer_name'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      postcode: (map['postcode'] ?? '').toString(),
      addressLine1: (map['address_line1'] ?? '').toString(),
      addressLine2: (map['address_line2'] ?? '').toString(),
      city: (map['city'] ?? '').toString(),
      deliveryType: (map['delivery_type'] ?? '').toString(),
      deliverySlot: (map['delivery_slot'] ?? '').toString(),
      paymentMethod: (map['payment_method'] ?? '').toString(),
      paymentStatus: (map['payment_status'] ?? '').toString(),
      subtotalCents: (map['subtotal_cents'] as num?)?.toInt() ?? 0,
      deliveryFeeCents: (map['delivery_fee_cents'] as num?)?.toInt() ?? 0,
      totalCents: (map['total_cents'] as num?)?.toInt() ?? 0,
      status: (map['status'] ?? '').toString(),
      adminStatus: (map['admin_status'] ?? '').toString(),
      deliveryStatus: (map['delivery_status'] ?? '').toString(),
      packedAt: parseDate(map['packed_at']),
      dispatchedAt: parseDate(map['dispatched_at']),
      outForDeliveryAt: parseDate(map['out_for_delivery_at']),
      deliveredAt: parseDate(map['delivered_at']),
      displayStatus: (map['display_status'] ?? 'Order Placed').toString(),
    );
  }

  String get totalFormatted => '£${(totalCents / 100).toStringAsFixed(2)}';

  String get subtotalFormatted =>
      '£${(subtotalCents / 100).toStringAsFixed(2)}';

  String get deliveryFeeFormatted =>
      '£${(deliveryFeeCents / 100).toStringAsFixed(2)}';

  String get paymentMethodLabel {
    switch (paymentMethod) {
      case 'cod':
        return 'Cash on Delivery';
      case 'card':
        return 'Card Payment';
      default:
        return paymentMethod.isEmpty ? 'Payment' : paymentMethod;
    }
  }

  String get deliveryTypeLabel {
    switch (deliveryType) {
      case 'local_pickup':
        return 'Local Pickup';
      case 'home_delivery':
        return 'Home Delivery';
      default:
        return 'Delivery';
    }
  }

  String get paymentStatusLabel {
    switch (paymentStatus) {
      case 'paid':
        return 'Paid';
      case 'cod_pending':
        return 'Pay on delivery';
      case 'pending':
        return 'Pending';
      default:
        return paymentStatus.isEmpty ? 'Pending' : paymentStatus;
    }
  }

  String get fullAddress {
    final parts = <String>[
      addressLine1,
      addressLine2,
      city,
      postcode,
    ].where((e) => e.trim().isNotEmpty).toList();

    return parts.join(', ');
  }
}
