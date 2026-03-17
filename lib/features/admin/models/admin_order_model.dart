class AdminOrderModel {
  final String id;
  final String? orderNumber;
  final String? customerName;
  final String? phone;
  final String? deliverySlot;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? status;
  final String? adminStatus;
  final int? totalCents;
  final bool hasFrozenItems;
  final String? freezerStatus;
  final String? deliveryStatus;
  final DateTime? createdAt;

  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? postcode;

  final double? latitude;
  final double? longitude;

  final DateTime? outForDeliveryAt;
  final DateTime? deliveredAt;

  const AdminOrderModel({
    required this.id,
    this.orderNumber,
    this.customerName,
    this.phone,
    this.deliverySlot,
    this.paymentMethod,
    this.paymentStatus,
    this.status,
    this.adminStatus,
    this.totalCents,
    this.hasFrozenItems = false,
    this.freezerStatus,
    this.deliveryStatus,
    this.createdAt,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.postcode,
    this.latitude,
    this.longitude,
    this.outForDeliveryAt,
    this.deliveredAt,
  });

  factory AdminOrderModel.fromMap(Map<String, dynamic> map) {
    return AdminOrderModel(
      id: map['id'] as String,
      orderNumber: map['order_number'] as String?,
      customerName: map['customer_name'] as String?,
      phone: map['phone'] as String?,
      deliverySlot: map['delivery_slot'] as String?,
      paymentMethod: map['payment_method'] as String?,
      paymentStatus: map['payment_status'] as String?,
      status: map['status'] as String?,
      adminStatus: map['admin_status'] as String?,
      totalCents: map['total_cents'] as int?,
      hasFrozenItems: map['has_frozen_items'] as bool? ?? false,
      freezerStatus: map['freezer_status'] as String?,
      deliveryStatus: map['delivery_status'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
      addressLine1: map['address_line1'] as String?,
      addressLine2: map['address_line2'] as String?,
      city: map['city'] as String?,
      postcode: map['postcode'] as String?,
      latitude:
          map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null
          ? (map['longitude'] as num).toDouble()
          : null,
      outForDeliveryAt: map['out_for_delivery_at'] != null
          ? DateTime.tryParse(map['out_for_delivery_at'] as String)
          : null,
      deliveredAt: map['delivered_at'] != null
          ? DateTime.tryParse(map['delivered_at'] as String)
          : null,
    );
  }

  String get safeStatus => (status ?? '').trim().toLowerCase();
  String get safeAdminStatus => (adminStatus ?? '').trim().toLowerCase();
  String get safeDeliveryStatus => (deliveryStatus ?? '').trim().toLowerCase();
  String get safePaymentStatus => (paymentStatus ?? '').trim().toLowerCase();

  bool get isDelivered {
    return safeDeliveryStatus == 'delivered' ||
        safeStatus == 'delivered' ||
        safeAdminStatus == 'delivered' ||
        deliveredAt != null;
  }

  bool get isOutForDelivery {
    if (isDelivered) return false;

    return safeDeliveryStatus == 'out_for_delivery' ||
        safeStatus == 'out_for_delivery' ||
        outForDeliveryAt != null;
  }

  bool get isPacked {
    if (isDelivered || isOutForDelivery) return false;

    return safeStatus == 'packed' ||
        safeAdminStatus == 'packed' ||
        safeAdminStatus == 'frozen_staged';
  }

  bool get isPicking {
    if (isDelivered || isOutForDelivery || isPacked) return false;

    return safeAdminStatus == 'picking';
  }

  bool get isPending {
    return !isDelivered && !isOutForDelivery && !isPacked && !isPicking;
  }

  bool get isFrozenStaged => safeAdminStatus == 'frozen_staged';

  bool get canDispatch => isPacked && !isOutForDelivery && !isDelivered;
  bool get canDeliver => isOutForDelivery && !isDelivered;
  bool get isActiveDeliveryOrder => canDispatch || canDeliver;

  String get displayStatusLabel {
    if (isDelivered) return 'DELIVERED';
    if (isOutForDelivery) return 'OUT FOR DELIVERY';
    if (isPacked) return hasFrozenItems || isFrozenStaged ? 'PACKED' : 'PACKED';
    if (isPicking) return 'PICKING';
    return 'PENDING';
  }

  String get operationalBucket {
    if (isDelivered) return 'delivered';
    if (isOutForDelivery) return 'out_for_delivery';
    if (isPacked) return 'packed';
    if (isPicking) return 'picking';
    return 'pending';
  }

  int get statusPriority {
    if (isDelivered) return 0;
    if (isOutForDelivery) return 1;
    if (isPacked) return 2;
    if (isPicking) return 3;
    return 4;
  }

  bool get hasPinnedLocation => latitude != null && longitude != null;

  String get fullAddress {
    final parts = [
      addressLine1,
      addressLine2,
      city,
      postcode,
    ].where((e) => e != null && e.trim().isNotEmpty).cast<String>().toList();

    return parts.join(', ');
  }
}
