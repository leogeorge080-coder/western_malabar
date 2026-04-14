class OrderHistoryModel {
  final String id;
  final String orderNumber;
  final DateTime? createdAt;
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
  final String displayStatus;
  final int itemCount;

  const OrderHistoryModel({
    required this.id,
    required this.orderNumber,
    required this.createdAt,
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
    required this.displayStatus,
    required this.itemCount,
  });

  factory OrderHistoryModel.fromMap(Map<String, dynamic> map) {
    return OrderHistoryModel(
      id: (map['id'] ?? '').toString(),
      orderNumber: (map['order_number'] ?? '').toString(),
      createdAt: map['created_at'] == null
          ? null
          : DateTime.tryParse(map['created_at'].toString())?.toLocal(),
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
      displayStatus: (map['display_status'] ?? '').toString(),
      itemCount: (map['item_count'] as num?)?.toInt() ?? 0,
    );
  }

  String get totalFormatted => '£${(totalCents / 100).toStringAsFixed(2)}';

  String get itemCountLabel {
    if (itemCount == 1) return '1 item';
    return '$itemCount items';
  }

  String get deliveryTypeLabel {
    switch (deliveryType.trim().toLowerCase()) {
      case 'local_pickup':
        return 'Pickup';
      case 'home_delivery':
        return 'Home Delivery';
      default:
        return 'Delivery';
    }
  }

  String get paymentMethodLabel {
    switch (paymentMethod.trim().toLowerCase()) {
      case 'cod':
        return 'Cash on Delivery';
      case 'card':
        return 'Card Payment';
      default:
        return paymentMethod.isEmpty ? 'Payment' : _titleize(paymentMethod);
    }
  }

  String get normalizedDisplayStatus {
    final s = status.trim().toLowerCase();
    final a = adminStatus.trim().toLowerCase();
    final d = deliveryStatus.trim().toLowerCase();
    final p = paymentStatus.trim().toLowerCase();
    final isPickup = deliveryType.trim().toLowerCase() == 'local_pickup';

    if (s == 'cancelled' || a == 'cancelled' || d == 'cancelled') {
      return 'Cancelled';
    }

    if (isPickup) {
      if (d == 'delivered' || d == 'collected' || s == 'collected') {
        return 'Collected';
      }
      if (d == 'ready_for_pickup' ||
          d == 'ready for pickup' ||
          a == 'ready_for_pickup' ||
          a == 'ready for pickup') {
        return 'Ready for Pickup';
      }
    } else {
      if (d == 'delivered') {
        return 'Delivered';
      }
      if (d == 'out_for_delivery' || d == 'out for delivery') {
        return 'Out for Delivery';
      }
    }

    if (a == 'packed' || s == 'packed') {
      return 'Packing';
    }

    if (a == 'preparing' || s == 'preparing') {
      return 'Preparing';
    }

    if (a == 'confirmed' || s == 'confirmed') {
      return 'Confirmed';
    }

    if (p == 'pending' && (s.isEmpty || s == 'placed')) {
      return 'Payment Pending';
    }

    if (displayStatus.trim().isNotEmpty) {
      return _normalizeIncomingDisplayStatus(displayStatus);
    }

    return 'Order Placed';
  }

  bool get isCompleted {
    final value = normalizedDisplayStatus;
    return value == 'Delivered' || value == 'Collected';
  }

  bool get isActive {
    final value = normalizedDisplayStatus;
    return value == 'Confirmed' ||
        value == 'Preparing' ||
        value == 'Packing' ||
        value == 'Out for Delivery' ||
        value == 'Ready for Pickup' ||
        value == 'Payment Pending';
  }

  bool get isCancelled => normalizedDisplayStatus == 'Cancelled';

  String get statusMessage {
    switch (normalizedDisplayStatus) {
      case 'Delivered':
        return 'This order has been delivered successfully.';
      case 'Collected':
        return 'This order was collected successfully.';
      case 'Out for Delivery':
        return 'Your order is on the way.';
      case 'Ready for Pickup':
        return 'Your order is ready to collect.';
      case 'Packing':
        return 'Your items are being packed for dispatch.';
      case 'Preparing':
        return 'Your order is being prepared.';
      case 'Confirmed':
        return 'Your order has been confirmed and will move soon.';
      case 'Payment Pending':
        return 'Your payment is still pending confirmation.';
      case 'Cancelled':
        return 'This order was cancelled.';
      default:
        return 'Tap to view full order details and updates.';
    }
  }

  static String _normalizeIncomingDisplayStatus(String raw) {
    final value = raw.trim().toLowerCase();

    switch (value) {
      case 'delivered':
        return 'Delivered';
      case 'collected':
        return 'Collected';
      case 'out_for_delivery':
      case 'out for delivery':
        return 'Out for Delivery';
      case 'ready_for_pickup':
      case 'ready for pickup':
        return 'Ready for Pickup';
      case 'packed':
      case 'packing':
        return 'Packing';
      case 'preparing':
        return 'Preparing';
      case 'confirmed':
        return 'Confirmed';
      case 'payment_pending':
      case 'payment pending':
        return 'Payment Pending';
      case 'cancelled':
        return 'Cancelled';
      case 'order placed':
      case 'placed':
        return 'Order Placed';
      default:
        return _titleize(raw);
    }
  }

  static String _titleize(String raw) {
    return raw
        .replaceAll('_', ' ')
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .map((part) {
      final clean = part.trim();
      return '${clean[0].toUpperCase()}${clean.substring(1).toLowerCase()}';
    }).join(' ');
  }
}
