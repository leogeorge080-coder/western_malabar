class CheckoutAddress {
  final String fullName;
  final String phone;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String postcode;

  const CheckoutAddress({
    required this.fullName,
    required this.phone,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.postcode,
  });

  const CheckoutAddress.empty()
      : fullName = '',
        phone = '',
        addressLine1 = '',
        addressLine2 = '',
        city = '',
        postcode = '';

  bool get isValid =>
      fullName.trim().isNotEmpty &&
      phone.trim().isNotEmpty &&
      addressLine1.trim().isNotEmpty &&
      city.trim().isNotEmpty &&
      postcode.trim().isNotEmpty;

  CheckoutAddress copyWith({
    String? fullName,
    String? phone,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? postcode,
  }) {
    return CheckoutAddress(
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      postcode: postcode ?? this.postcode,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customer_name': fullName,
      'phone': phone,
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'city': city,
      'postcode': postcode,
    };
  }
}
