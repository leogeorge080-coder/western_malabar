import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:western_malabar/features/checkout/models/checkout_address.dart';
import 'package:western_malabar/services/postcode_lookup_service.dart';

class CheckoutState {
  final CheckoutAddress address;
  final String deliveryType;
  final String deliverySlot;
  final String paymentMethod;
  final bool isPlacingOrder;
  final bool isLookingUpAddress;
  final bool isCheckingPostcode;
  final bool postcodeEligible;
  final String postcodeStatusMessage;
  final String selectedAddressLabel;

  const CheckoutState({
    required this.address,
    required this.deliveryType,
    required this.deliverySlot,
    required this.paymentMethod,
    required this.isPlacingOrder,
    required this.isLookingUpAddress,
    required this.isCheckingPostcode,
    required this.postcodeEligible,
    required this.postcodeStatusMessage,
    required this.selectedAddressLabel,
  });

  factory CheckoutState.initial() {
    return const CheckoutState(
      address: CheckoutAddress.empty(),
      deliveryType: 'home_delivery',
      deliverySlot: 'Tomorrow • 6 PM - 8 PM',
      paymentMethod: 'cod',
      isPlacingOrder: false,
      isLookingUpAddress: false,
      isCheckingPostcode: false,
      postcodeEligible: false,
      postcodeStatusMessage: '',
      selectedAddressLabel: '',
    );
  }

  CheckoutState copyWith({
    CheckoutAddress? address,
    String? deliveryType,
    String? deliverySlot,
    String? paymentMethod,
    bool? isPlacingOrder,
    bool? isLookingUpAddress,
    bool? isCheckingPostcode,
    bool? postcodeEligible,
    String? postcodeStatusMessage,
    String? selectedAddressLabel,
  }) {
    return CheckoutState(
      address: address ?? this.address,
      deliveryType: deliveryType ?? this.deliveryType,
      deliverySlot: deliverySlot ?? this.deliverySlot,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isPlacingOrder: isPlacingOrder ?? this.isPlacingOrder,
      isLookingUpAddress: isLookingUpAddress ?? this.isLookingUpAddress,
      isCheckingPostcode: isCheckingPostcode ?? this.isCheckingPostcode,
      postcodeEligible: postcodeEligible ?? this.postcodeEligible,
      postcodeStatusMessage:
          postcodeStatusMessage ?? this.postcodeStatusMessage,
      selectedAddressLabel: selectedAddressLabel ?? this.selectedAddressLabel,
    );
  }
}

class CheckoutNotifier extends StateNotifier<CheckoutState> {
  CheckoutNotifier() : super(CheckoutState.initial());

  void updateFullName(String value) {
    state = state.copyWith(
      address: state.address.copyWith(fullName: value),
    );
  }

  void updatePhone(String value) {
    state = state.copyWith(
      address: state.address.copyWith(phone: value),
    );
  }

  void updateAddressLine1(String value) {
    state = state.copyWith(
      address: state.address.copyWith(addressLine1: value),
    );
  }

  void updateAddressLine2(String value) {
    state = state.copyWith(
      address: state.address.copyWith(addressLine2: value),
    );
  }

  void updateCity(String value) {
    state = state.copyWith(
      address: state.address.copyWith(city: value),
    );
  }

  void updatePostcode(String value) {
    state = state.copyWith(
      address: state.address.copyWith(
        postcode: value,
        addressLine1: '',
        addressLine2: '',
        city: '',
      ),
      postcodeEligible: false,
      postcodeStatusMessage: '',
      selectedAddressLabel: '',
    );
  }

  void updateDeliveryType(String value) {
    state = state.copyWith(deliveryType: value);
  }

  void updateDeliverySlot(String value) {
    state = state.copyWith(deliverySlot: value);
  }

  void updatePaymentMethod(String value) {
    state = state.copyWith(paymentMethod: value);
  }

  void setPlacingOrder(bool value) {
    state = state.copyWith(isPlacingOrder: value);
  }

  void setLookingUpAddress(bool value) {
    state = state.copyWith(isLookingUpAddress: value);
  }

  void setCheckingPostcode(bool value) {
    state = state.copyWith(isCheckingPostcode: value);
  }

  void setPostcodeEligibility({
    required bool eligible,
    required String message,
  }) {
    state = state.copyWith(
      postcodeEligible: eligible,
      postcodeStatusMessage: message,
    );
  }

  void applyLookupAddress({
    required String line1,
    required String line2,
    required String city,
    required String postcode,
    required String label,
  }) {
    state = state.copyWith(
      address: state.address.copyWith(
        addressLine1: line1,
        addressLine2: line2,
        city: city,
        postcode: postcode,
      ),
      selectedAddressLabel: label,
    );
  }

  void applySelectedLookupAddress(AddressLookupItem item) {
    applyLookupAddress(
      line1: item.line1,
      line2: item.line2,
      city: item.city,
      postcode: item.postcode,
      label: item.displayText,
    );
  }

  void resetLookupState() {
    state = state.copyWith(
      postcodeEligible: false,
      postcodeStatusMessage: '',
      selectedAddressLabel: '',
      isCheckingPostcode: false,
      isLookingUpAddress: false,
    );
  }

  Future<void> checkPostcodeEligibility() async {
    final postcode = state.address.postcode.trim();

    if (postcode.isEmpty) {
      state = state.copyWith(
        postcodeEligible: false,
        postcodeStatusMessage: 'Please enter a postcode',
      );
      return;
    }

    state = state.copyWith(isCheckingPostcode: true);

    try {
      final eligible = PostcodeLookupService.isDeliveryArea(postcode);
      final message = PostcodeLookupService.availabilityMessage(postcode);

      state = state.copyWith(
        postcodeEligible: eligible,
        postcodeStatusMessage: message,
      );
    } finally {
      state = state.copyWith(isCheckingPostcode: false);
    }
  }

  Future<List<AddressLookupItem>> findAddresses() async {
    final postcode = state.address.postcode.trim();

    if (postcode.isEmpty) {
      throw Exception('Please enter a postcode');
    }

    if (!state.postcodeEligible) {
      throw Exception('Please check postcode eligibility first');
    }

    state = state.copyWith(isLookingUpAddress: true);

    try {
      return await PostcodeLookupService.findAddresses(postcode);
    } finally {
      state = state.copyWith(isLookingUpAddress: false);
    }
  }

  bool validate() {
    return state.address.isValid &&
        state.deliveryType.isNotEmpty &&
        state.deliverySlot.isNotEmpty &&
        state.paymentMethod.isNotEmpty;
  }
}

final checkoutProvider = StateNotifierProvider<CheckoutNotifier, CheckoutState>(
  (ref) => CheckoutNotifier(),
);
