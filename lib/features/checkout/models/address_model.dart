class AddressModel {
  final String id;
  final String userId;
  final String label;
  final String fullName;
  final String phone;
  final String postcode;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String? county;
  final String? deliveryNote;
  final bool isDefault;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AddressModel({
    required this.id,
    required this.userId,
    required this.label,
    required this.fullName,
    required this.phone,
    required this.postcode,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    this.county,
    this.deliveryNote,
    required this.isDefault,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.updatedAt,
  });

  factory AddressModel.fromMap(Map<String, dynamic> map) {
    return AddressModel(
      id: (map['id'] ?? '').toString(),
      userId: (map['user_id'] ?? '').toString(),
      label: (map['label'] ?? 'Home').toString(),
      fullName: (map['full_name'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      postcode: (map['postcode'] ?? '').toString(),
      addressLine1: (map['address_line1'] ?? '').toString(),
      addressLine2: (map['address_line2'] ?? '').toString(),
      city: (map['city'] ?? '').toString(),
      county: map['county']?.toString(),
      deliveryNote: map['delivery_note']?.toString(),
      isDefault: map['is_default'] == true,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'user_id': userId,
      'label': label,
      'full_name': fullName,
      'phone': phone,
      'postcode': postcode,
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'city': city,
      'county': county,
      'delivery_note': deliveryNote,
      'is_default': isDefault,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  AddressModel copyWith({
    String? id,
    String? userId,
    String? label,
    String? fullName,
    String? phone,
    String? postcode,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? county,
    String? deliveryNote,
    bool? isDefault,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AddressModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      label: label ?? this.label,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      postcode: postcode ?? this.postcode,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      county: county ?? this.county,
      deliveryNote: deliveryNote ?? this.deliveryNote,
      isDefault: isDefault ?? this.isDefault,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get shortDisplay {
    final parts = [
      addressLine1,
      if (addressLine2.trim().isNotEmpty) addressLine2,
      city,
      postcode,
    ].where((e) => e.trim().isNotEmpty).toList();

    return parts.join(', ');
  }

  String get fullDisplay {
    final parts = [
      fullName,
      if (phone.trim().isNotEmpty) phone,
      addressLine1,
      if (addressLine2.trim().isNotEmpty) addressLine2,
      city,
      if ((county ?? '').trim().isNotEmpty) county!,
      postcode,
    ].where((e) => e.trim().isNotEmpty).toList();

    return parts.join(', ');
  }
}
