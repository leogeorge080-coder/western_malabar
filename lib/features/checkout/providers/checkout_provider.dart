import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:western_malabar/features/checkout/models/address_model.dart';
import 'package:western_malabar/features/checkout/models/checkout_address.dart';
import 'package:western_malabar/shared/services/postcode_lookup_service.dart';

class CheckoutState {
  final CheckoutAddress address;
  final String deliveryType;
  final String deliverySlot;
  final String paymentMethod;
  final bool useRewards;
  final int availableRewardPence;
  final int appliedRewardPence;
  final int pointsToNextReward;
  final bool rewardsLoading;
  final String rewardsMessage;
  final int backendSubtotalCents;
  final int backendEligibleSubtotalCents;
  final int backendDeliveryFeeCents;
  final int backendRewardDiscountCents;
  final int backendTotalCents;
  final int backendPointsToRedeem;
  final bool backendSummaryLoading;
  final bool backendSummaryLoaded;
  final String backendSummaryError;
  final bool isPlacingOrder;
  final bool isLookingUpAddress;
  final bool isCheckingPostcode;
  final bool postcodeEligible;
  final String postcodeStatusMessage;
  final String selectedAddressLabel;
  final AddressModel? selectedSavedAddress;

  const CheckoutState({
    required this.address,
    required this.deliveryType,
    required this.deliverySlot,
    required this.paymentMethod,
    required this.useRewards,
    required this.availableRewardPence,
    required this.appliedRewardPence,
    required this.pointsToNextReward,
    required this.rewardsLoading,
    required this.rewardsMessage,
    this.backendSubtotalCents = 0,
    this.backendEligibleSubtotalCents = 0,
    this.backendDeliveryFeeCents = 0,
    this.backendRewardDiscountCents = 0,
    this.backendTotalCents = 0,
    this.backendPointsToRedeem = 0,
    this.backendSummaryLoading = false,
    this.backendSummaryLoaded = false,
    this.backendSummaryError = '',
    required this.isPlacingOrder,
    required this.isLookingUpAddress,
    required this.isCheckingPostcode,
    required this.postcodeEligible,
    required this.postcodeStatusMessage,
    required this.selectedAddressLabel,
    required this.selectedSavedAddress,
  });

  factory CheckoutState.initial() {
    return const CheckoutState(
      address: CheckoutAddress.empty(),
      deliveryType: 'home_delivery',
      deliverySlot: 'Tomorrow • 6 PM - 8 PM',
      paymentMethod: 'cod',
      useRewards: false,
      availableRewardPence: 0,
      appliedRewardPence: 0,
      pointsToNextReward: 0,
      rewardsLoading: false,
      rewardsMessage: '',
      isPlacingOrder: false,
      isLookingUpAddress: false,
      isCheckingPostcode: false,
      postcodeEligible: false,
      postcodeStatusMessage: '',
      selectedAddressLabel: '',
      selectedSavedAddress: null,
    );
  }

  CheckoutState copyWith({
    CheckoutAddress? address,
    String? deliveryType,
    String? deliverySlot,
    String? paymentMethod,
    bool? useRewards,
    int? availableRewardPence,
    int? appliedRewardPence,
    int? pointsToNextReward,
    bool? rewardsLoading,
    String? rewardsMessage,
    int? backendSubtotalCents,
    int? backendEligibleSubtotalCents,
    int? backendDeliveryFeeCents,
    int? backendRewardDiscountCents,
    int? backendTotalCents,
    int? backendPointsToRedeem,
    bool? backendSummaryLoading,
    bool? backendSummaryLoaded,
    String? backendSummaryError,
    bool? isPlacingOrder,
    bool? isLookingUpAddress,
    bool? isCheckingPostcode,
    bool? postcodeEligible,
    String? postcodeStatusMessage,
    String? selectedAddressLabel,
    AddressModel? selectedSavedAddress,
    bool clearSelectedSavedAddress = false,
  }) {
    return CheckoutState(
      address: address ?? this.address,
      deliveryType: deliveryType ?? this.deliveryType,
      deliverySlot: deliverySlot ?? this.deliverySlot,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      useRewards: useRewards ?? this.useRewards,
      availableRewardPence: availableRewardPence ?? this.availableRewardPence,
      appliedRewardPence: appliedRewardPence ?? this.appliedRewardPence,
      pointsToNextReward: pointsToNextReward ?? this.pointsToNextReward,
      rewardsLoading: rewardsLoading ?? this.rewardsLoading,
      rewardsMessage: rewardsMessage ?? this.rewardsMessage,
      backendSubtotalCents: backendSubtotalCents ?? this.backendSubtotalCents,
      backendEligibleSubtotalCents:
          backendEligibleSubtotalCents ?? this.backendEligibleSubtotalCents,
      backendDeliveryFeeCents:
          backendDeliveryFeeCents ?? this.backendDeliveryFeeCents,
      backendRewardDiscountCents:
          backendRewardDiscountCents ?? this.backendRewardDiscountCents,
      backendTotalCents: backendTotalCents ?? this.backendTotalCents,
      backendPointsToRedeem:
          backendPointsToRedeem ?? this.backendPointsToRedeem,
      backendSummaryLoading:
          backendSummaryLoading ?? this.backendSummaryLoading,
      backendSummaryLoaded: backendSummaryLoaded ?? this.backendSummaryLoaded,
      backendSummaryError: backendSummaryError ?? this.backendSummaryError,
      isPlacingOrder: isPlacingOrder ?? this.isPlacingOrder,
      isLookingUpAddress: isLookingUpAddress ?? this.isLookingUpAddress,
      isCheckingPostcode: isCheckingPostcode ?? this.isCheckingPostcode,
      postcodeEligible: postcodeEligible ?? this.postcodeEligible,
      postcodeStatusMessage:
          postcodeStatusMessage ?? this.postcodeStatusMessage,
      selectedAddressLabel: selectedAddressLabel ?? this.selectedAddressLabel,
      selectedSavedAddress: clearSelectedSavedAddress
          ? null
          : (selectedSavedAddress ?? this.selectedSavedAddress),
    );
  }
}

class CheckoutNotifier extends StateNotifier<CheckoutState> {
  CheckoutNotifier() : super(CheckoutState.initial());

  void reset() {
    state = CheckoutState.initial();
  }

  void resetAddressState() {
    state = state.copyWith(
      address: CheckoutAddress.empty(),
      postcodeEligible: false,
      postcodeStatusMessage: '',
      selectedAddressLabel: '',
      clearSelectedSavedAddress: true,
      isCheckingPostcode: false,
      isLookingUpAddress: false,
    );
  }

  void _clearSavedAddressSelection() {
    state = state.copyWith(
      selectedAddressLabel: '',
      clearSelectedSavedAddress: true,
    );
  }

  void updateFullName(String value) {
    final selectedSaved = state.selectedSavedAddress;
    final shouldClear =
        selectedSaved != null && value != selectedSaved.fullName;

    state = state.copyWith(
      address: state.address.copyWith(fullName: value),
      selectedAddressLabel: shouldClear ? '' : null,
      clearSelectedSavedAddress: shouldClear,
    );
  }

  void updatePhone(String value) {
    final selectedSaved = state.selectedSavedAddress;
    final shouldClear = selectedSaved != null && value != selectedSaved.phone;

    state = state.copyWith(
      address: state.address.copyWith(phone: value),
      selectedAddressLabel: shouldClear ? '' : null,
      clearSelectedSavedAddress: shouldClear,
    );
  }

  void updateAddressLine1(String value) {
    final selectedSaved = state.selectedSavedAddress;
    final shouldClear =
        selectedSaved != null && value != selectedSaved.addressLine1;

    state = state.copyWith(
      address: state.address.copyWith(addressLine1: value),
      selectedAddressLabel: shouldClear ? '' : null,
      clearSelectedSavedAddress: shouldClear,
    );
  }

  void updateAddressLine2(String value) {
    final selectedSaved = state.selectedSavedAddress;
    final shouldClear =
        selectedSaved != null && value != selectedSaved.addressLine2;

    state = state.copyWith(
      address: state.address.copyWith(addressLine2: value),
      selectedAddressLabel: shouldClear ? '' : null,
      clearSelectedSavedAddress: shouldClear,
    );
  }

  void updateCity(String value) {
    final selectedSaved = state.selectedSavedAddress;
    final shouldClear = selectedSaved != null && value != selectedSaved.city;

    state = state.copyWith(
      address: state.address.copyWith(city: value),
      selectedAddressLabel: shouldClear ? '' : null,
      clearSelectedSavedAddress: shouldClear,
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
      clearSelectedSavedAddress: true,
    );
  }

  void applySavedAddress(AddressModel address) {
    state = state.copyWith(
      address: state.address.copyWith(
        fullName: address.fullName,
        phone: address.phone,
        postcode: address.postcode,
        addressLine1: address.addressLine1,
        addressLine2: address.addressLine2,
        city: address.city,
      ),
      selectedSavedAddress: address,
      selectedAddressLabel: address.shortDisplay,
      postcodeEligible: true,
      postcodeStatusMessage: '',
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

  void setRewardsLoading(bool value) {
    if (state.rewardsLoading == value) return;
    state = state.copyWith(rewardsLoading: value);
  }

  void setRewardsSummary({
    required int availableRewardPence,
    required int pointsToNextReward,
    String? message,
  }) {
    final safeAvailable = availableRewardPence < 0 ? 0 : availableRewardPence;
    final safePointsToNext = pointsToNextReward < 0 ? 0 : pointsToNextReward;
    final nextApplied = state.appliedRewardPence > safeAvailable
        ? safeAvailable
        : state.appliedRewardPence;
    final nextUseRewards = state.useRewards && safeAvailable > 0;
    final nextMessage = message ?? state.rewardsMessage;

    if (state.availableRewardPence == safeAvailable &&
        state.pointsToNextReward == safePointsToNext &&
        state.appliedRewardPence == nextApplied &&
        state.useRewards == nextUseRewards &&
        state.rewardsLoading == false &&
        state.rewardsMessage == nextMessage) {
      return;
    }

    state = state.copyWith(
      availableRewardPence: safeAvailable,
      appliedRewardPence: nextApplied,
      pointsToNextReward: safePointsToNext,
      rewardsLoading: false,
      rewardsMessage: nextMessage,
      useRewards: nextUseRewards,
    );
  }

  void setRewardsMessage(String value) {
    if (state.rewardsMessage == value) return;
    state = state.copyWith(rewardsMessage: value);
  }

  void setBackendSummaryLoading(bool value) {
    state = state.copyWith(
      backendSummaryLoading: value,
      backendSummaryError: value ? '' : state.backendSummaryError,
    );
  }

  void setBackendSummary({
    required int subtotalCents,
    required int eligibleSubtotalCents,
    required int deliveryFeeCents,
    required int rewardDiscountCents,
    required int totalCents,
    required int pointsToRedeem,
  }) {
    state = state.copyWith(
      backendSubtotalCents: subtotalCents,
      backendEligibleSubtotalCents: eligibleSubtotalCents,
      backendDeliveryFeeCents: deliveryFeeCents,
      backendRewardDiscountCents: rewardDiscountCents,
      backendTotalCents: totalCents,
      backendPointsToRedeem: pointsToRedeem,
      backendSummaryLoading: false,
      backendSummaryLoaded: true,
      backendSummaryError: '',
    );
  }

  void setBackendSummaryError(String message) {
    state = state.copyWith(
      backendSummaryLoading: false,
      backendSummaryLoaded: false,
      backendSummaryError: message,
    );
  }

  void toggleUseRewards([bool? value]) {
    final nextUseRewards = value ?? !state.useRewards;

    if (!nextUseRewards || state.availableRewardPence <= 0) {
      if (!state.useRewards && state.appliedRewardPence == 0) return;
      state = state.copyWith(
        useRewards: false,
        appliedRewardPence: 0,
      );
      return;
    }

    final nextApplied = state.appliedRewardPence > 0
        ? (state.appliedRewardPence > state.availableRewardPence
            ? state.availableRewardPence
            : state.appliedRewardPence)
        : state.availableRewardPence;

    if (state.useRewards && state.appliedRewardPence == nextApplied) return;

    state = state.copyWith(
      useRewards: true,
      appliedRewardPence: nextApplied,
    );
  }

  void setAppliedRewardPence(int value) {
    final safeValue = value < 0
        ? 0
        : (value > state.availableRewardPence
            ? state.availableRewardPence
            : value);
    final nextUseRewards = safeValue > 0;

    if (state.appliedRewardPence == safeValue &&
        state.useRewards == nextUseRewards) {
      return;
    }

    state = state.copyWith(
      appliedRewardPence: safeValue,
      useRewards: nextUseRewards,
    );
  }

  void clearRewards() {
    if (!state.useRewards &&
        state.availableRewardPence == 0 &&
        state.appliedRewardPence == 0 &&
        state.pointsToNextReward == 0 &&
        !state.rewardsLoading &&
        state.rewardsMessage.isEmpty) {
      return;
    }

    state = state.copyWith(
      useRewards: false,
      availableRewardPence: 0,
      appliedRewardPence: 0,
      pointsToNextReward: 0,
      rewardsLoading: false,
      rewardsMessage: '',
    );
  }

  void reconcileRewardUsage({
    required int eligibleSubtotalCents,
  }) {
    final cappedAvailable =
        state.availableRewardPence < 0 ? 0 : state.availableRewardPence;
    final safeEligibleSubtotal =
        eligibleSubtotalCents < 0 ? 0 : eligibleSubtotalCents;
    final safeMaxUsable = safeEligibleSubtotal > cappedAvailable
        ? cappedAvailable
        : safeEligibleSubtotal;
    final nextApplied = state.useRewards ? safeMaxUsable : 0;
    final nextUseRewards = state.useRewards && nextApplied > 0;

    if (state.appliedRewardPence == nextApplied &&
        state.useRewards == nextUseRewards) {
      return;
    }

    state = state.copyWith(
      appliedRewardPence: nextApplied,
      useRewards: nextUseRewards,
    );
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
      clearSelectedSavedAddress: true,
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
      clearSelectedSavedAddress: true,
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
