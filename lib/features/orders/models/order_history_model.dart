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

  String get itemCountLabel => itemCount == 1 ? '1 item' : '$itemCount items';

  String get deliveryTypeLabel {
    switch (deliveryType.trim().toLowerCase()) {
      case 'local_pickup':
        return 'Pickup';
      case 'home_delivery':
        return 'Home delivery';
      default:
        return 'Delivery';
    }
  }

  String get paymentMethodLabel {
    switch (paymentMethod.trim().toLowerCase()) {
      case 'cod':
        return 'Cash on delivery';
      case 'card':
        return 'Card payment';
      default:
        return paymentMethod.isEmpty ? 'Payment' : _titleize(paymentMethod);
    }
  }

  String get customerDisplayStatus {
    final s = status.trim().toLowerCase();
    final a = adminStatus.trim().toLowerCase();
    final d = deliveryStatus.trim().toLowerCase();
    final isPickup = deliveryType.trim().toLowerCase() == 'local_pickup';

    if (s == 'cancelled' || a == 'cancelled') {
      return 'Cancelled';
    }

    if (isPickup) {
      if (d == 'delivered' || d == 'collected' || s == 'collected') {
        return 'Collected';
      }
      if (d == 'ready_for_pickup' || d == 'ready for pickup') {
        return 'Ready for pickup';
      }
    } else {
      if (d == 'delivered') {
        return 'Delivered';
      }
      if (d == 'out_for_delivery' || d == 'out for delivery') {
        return 'On the way';
      }
    }

    if (displayStatus.trim().isNotEmpty) {
      final normalized = _normalizeIncomingDisplayStatus(displayStatus);
      if (normalized.isNotEmpty) return normalized;
    }

    return 'Order received';
  }

  bool get isCompleted {
    final value = customerDisplayStatus;
    return value == 'Delivered' || value == 'Collected';
  }

  bool get isActive {
    final value = customerDisplayStatus;
    return value == 'Order received' ||
        value == 'On the way' ||
        value == 'Ready for pickup';
  }

  bool get isCancelled => customerDisplayStatus == 'Cancelled';

  bool get canCustomerCancel => status.trim().toLowerCase() == 'placed';

  String get statusMessage {
    switch (customerDisplayStatus) {
      case 'Delivered':
        return 'Your order has been delivered successfully.';
      case 'Collected':
        return 'Your order was collected successfully.';
      case 'On the way':
        return 'Your order is on the way.';
      case 'Ready for pickup':
        return 'Your order is ready for collection.';
      case 'Order received':
        return 'We have received your order and will begin processing it shortly.';
      case 'Cancelled':
        return 'This order has been cancelled.';
      default:
        return 'Open this order to review items, totals, and updates.';
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
        return 'On the way';
      case 'ready_for_pickup':
      case 'ready for pickup':
        return 'Ready for pickup';
      case 'cancelled':
        return 'Cancelled';
      case 'order placed':
      case 'placed':
      case 'packed':
      case 'packing':
      case 'preparing':
      case 'confirmed':
      case 'payment_pending':
      case 'payment pending':
        return 'Order received';
      default:
        return '';
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
