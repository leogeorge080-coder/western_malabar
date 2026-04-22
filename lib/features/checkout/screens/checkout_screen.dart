import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:western_malabar/features/admin/providers/admin_orders_provider.dart';
import 'package:western_malabar/features/cart/providers/cart_provider.dart';
import 'package:western_malabar/features/cart/services/cart_pricing.dart';
import 'package:western_malabar/features/checkout/models/address_model.dart';
import 'package:western_malabar/features/checkout/models/checkout_address.dart';
import 'package:western_malabar/features/checkout/providers/address_provider.dart';
import 'package:western_malabar/features/checkout/providers/checkout_provider.dart';
import 'package:western_malabar/features/checkout/screens/order_success_screen.dart';
import 'package:western_malabar/features/checkout/services/address_service.dart';
import 'package:western_malabar/features/checkout/services/checkout_service.dart';
import 'package:western_malabar/features/checkout/services/stripe_payment_service.dart';
import 'package:western_malabar/features/checkout/utils/checkout_error_formatter.dart';
import 'package:western_malabar/features/profile/models/profile_model.dart';
import 'package:western_malabar/features/profile/providers/profile_provider.dart';
import 'package:western_malabar/shared/services/postcode_lookup_service.dart';

const _wmCheckoutBg = Color(0xFFF7F7F7);
const _wmCheckoutSurface = Colors.white;
const _wmCheckoutBorder = Color(0xFFE5E7EB);

const _wmCheckoutTextStrong = Color(0xFF111827);
const _wmCheckoutTextSoft = Color(0xFF6B7280);
const _wmCheckoutTextMuted = Color(0xFF9CA3AF);

const _wmCheckoutPrimary = Color(0xFF2A2F3A);
const _wmCheckoutSuccess = Color(0xFF15803D);
const _wmCheckoutSuccessSoft = Color(0xFFECFDF5);

const _wmCheckoutDanger = Color(0xFFDC2626);
const _wmCheckoutDangerSoft = Color(0xFFFEF2F2);

const _wmCheckoutAmber = Color(0xFFF59E0B);
const _wmCheckoutAmberSoft = Color(0xFFFFF7ED);

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool get _isGuestCheckout {
    final user = Supabase.instance.client.auth.currentUser;
    return user == null || user.isAnonymous;
  }

  bool _isValidEmail(String value) {
    final email = value.trim();
    if (email.isEmpty) return false;

    final emailRegex = RegExp(
      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
    );
    return emailRegex.hasMatch(email);
  }

  String _guestCheckoutBenefitsText() {
    return 'Sign in or create an account to collect rewards, save addresses, and track your orders.';
  }

  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _postcodeController;
  late final TextEditingController _address1Controller;
  late final TextEditingController _address2Controller;
  late final TextEditingController _cityController;

  final StripePaymentService _stripePaymentService =
      const StripePaymentService();
  final AddressService _addressService = AddressService();

  StreamSubscription<AuthState>? _authStateSub;
  String? _lastUserId;

  bool _showManualAddressForm = false;
  String? _autoAppliedAddressId;
  String? _lastSummaryRefreshKey;
  bool _summaryRefreshInFlight = false;

  @override
  void initState() {
    super.initState();

    final checkout = ref.read(checkoutProvider);
    _lastUserId = Supabase.instance.client.auth.currentUser?.id;

    _fullNameController =
        TextEditingController(text: checkout.address.fullName);
    _phoneController = TextEditingController(text: checkout.address.phone);
    _emailController = TextEditingController(
      text: Supabase.instance.client.auth.currentUser?.email?.trim() ?? '',
    );
    _postcodeController =
        TextEditingController(text: checkout.address.postcode);
    _address1Controller =
        TextEditingController(text: checkout.address.addressLine1);
    _address2Controller =
        TextEditingController(text: checkout.address.addressLine2);
    _cityController = TextEditingController(text: checkout.address.city);

    _authStateSub =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final currentUserId = data.session?.user.id;

      if (currentUserId == _lastUserId) return;
      _lastUserId = currentUserId;

      if (!mounted) return;

      ref.read(checkoutProvider.notifier).reset();
      ref.invalidate(addressesProvider);
      ref.invalidate(defaultAddressProvider);

      _autoAppliedAddressId = null;
      _showManualAddressForm = false;
      _clearControllers(preserveEmail: false);
    });

    ref.listenManual(profileProvider, (previous, next) {
      final notifier = ref.read(checkoutProvider.notifier);

      next.when(
        loading: () {
          notifier.setRewardsLoading(true);
        },
        error: (_, __) {
          notifier.setRewardsLoading(false);
          notifier.setRewardsMessage('Could not load rewards right now.');
        },
        data: (ProfileModel? profile) {
          notifier.setRewardsLoading(false);

          if (profile == null) {
            notifier.setRewardsSummary(
              availableRewardPence: 0,
              pointsToNextReward: 200,
              message: '',
            );
            return;
          }

          final rewardPoints = (profile.rewardPoints as int?) ?? 0;
          const pointsPerRewardBlock = 200;
          const rewardBlockValuePence = 200;

          final unlockedBlocks = rewardPoints ~/ pointsPerRewardBlock;
          final availableRewardPence = unlockedBlocks * rewardBlockValuePence;
          final pointsIntoNext = rewardPoints % pointsPerRewardBlock;
          final pointsToNext = rewardPoints == 0
              ? pointsPerRewardBlock
              : (pointsPerRewardBlock - pointsIntoNext);

          notifier.setRewardsSummary(
            availableRewardPence: availableRewardPence,
            pointsToNextReward: pointsToNext,
            message: '',
          );
        },
      );
    });
  }

  @override
  void dispose() {
    _authStateSub?.cancel();
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _postcodeController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _clearControllers({bool preserveEmail = true}) {
    final existingEmail = _emailController.text.trim();
    final authEmail =
        Supabase.instance.client.auth.currentUser?.email?.trim() ?? '';

    _fullNameController.clear();
    _phoneController.clear();
    _postcodeController.clear();
    _address1Controller.clear();
    _address2Controller.clear();
    _cityController.clear();

    _emailController.text = preserveEmail
        ? (existingEmail.isNotEmpty ? existingEmail : authEmail)
        : authEmail;
  }

  void _applyCheckoutAddressToControllers({
    required String fullName,
    required String phone,
    required String postcode,
    required String addressLine1,
    required String addressLine2,
    required String city,
  }) {
    _fullNameController.text = fullName;
    _phoneController.text = phone;
    _postcodeController.text = postcode;
    _address1Controller.text = addressLine1;
    _address2Controller.text = addressLine2;
    _cityController.text = city;
  }

  void _applySavedAddressToControllers(AddressModel address) {
    _applyCheckoutAddressToControllers(
      fullName: address.fullName,
      phone: address.phone,
      postcode: address.postcode,
      addressLine1: address.addressLine1,
      addressLine2: address.addressLine2,
      city: address.city,
    );
  }

  void _ensureSavedAddressSelection(List<AddressModel> addresses) {
    if (addresses.isEmpty) return;
    if (_showManualAddressForm) return;

    final checkout = ref.read(checkoutProvider);
    final selectedSaved = checkout.selectedSavedAddress;

    if (selectedSaved != null) {
      final stillExists = addresses.any((a) => a.id == selectedSaved.id);
      if (stillExists) return;
    }

    final preferred = addresses.cast<AddressModel?>().firstWhere(
          (a) => a?.isDefault == true,
          orElse: () => addresses.first,
        );

    if (preferred == null) return;
    if (_autoAppliedAddressId == preferred.id) return;

    _autoAppliedAddressId = preferred.id;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(checkoutProvider.notifier).applySavedAddress(preferred);
      _applySavedAddressToControllers(preferred);
    });
  }

  void _openManualAddressMode() {
    setState(() {
      _showManualAddressForm = true;
      _autoAppliedAddressId = null;
    });
    ref.read(checkoutProvider.notifier).resetAddressState();
    _clearControllers(preserveEmail: true);
  }

  Future<void> _showSavedAddressesSheet(List<AddressModel> addresses) async {
    final notifier = ref.read(checkoutProvider.notifier);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SavedAddressPickerSheet(
        items: addresses,
        onSelected: (address) {
          notifier.applySavedAddress(address);
          _applySavedAddressToControllers(address);
          if (mounted) {
            setState(() {
              _showManualAddressForm = false;
              _autoAppliedAddressId = address.id;
            });
          }
        },
      ),
    );
  }

  Future<void> _findAddress() async {
    final notifier = ref.read(checkoutProvider.notifier);
    final query = _postcodeController.text.trim();

    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter postcode first')),
      );
      return;
    }

    try {
      notifier.setCheckingPostcode(true);

      final eligible = PostcodeLookupService.isDeliveryArea(query);
      final message = PostcodeLookupService.availabilityMessage(query);

      notifier.setPostcodeEligibility(
        eligible: eligible,
        message: message,
      );

      if (!eligible) {
        return;
      }

      notifier.setLookingUpAddress(true);

      final results = await PostcodeLookupService.findAddresses(query);

      if (!mounted) return;

      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No addresses found')),
        );
        return;
      }

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _AddressPickerSheet(
          items: results,
          onSelected: (item) {
            notifier.applyLookupAddress(
              line1: item.line1,
              line2: item.line2,
              city: item.city,
              postcode: item.postcode,
              label: item.displayText,
            );

            _address1Controller.text = item.line1;
            _address2Controller.text = item.line2;
            _cityController.text = item.city;
            _postcodeController.text = item.postcode;
          },
        ),
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Address lookup failed: $e');
        debugPrint('$st');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not find the address right now. Please try again.',
          ),
        ),
      );
    } finally {
      notifier.setCheckingPostcode(false);
      notifier.setLookingUpAddress(false);
    }
  }

  Future<void> _saveAddressAfterSuccessfulOrder() async {
    final checkout = ref.read(checkoutProvider);

    if (checkout.deliveryType != 'home_delivery') {
      return;
    }

    final selectedSaved = checkout.selectedSavedAddress;
    if (selectedSaved != null && selectedSaved.id.isNotEmpty) {
      return;
    }

    final fullName = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();
    final postcode = _postcodeController.text.trim();
    final addressLine1 = _address1Controller.text.trim();
    final addressLine2 = _address2Controller.text.trim();
    final city = _cityController.text.trim();

    if (fullName.isEmpty ||
        phone.isEmpty ||
        postcode.isEmpty ||
        addressLine1.isEmpty ||
        city.isEmpty) {
      return;
    }

    await _addressService.saveAddressFromCheckout(
      fullName: fullName,
      phone: phone,
      postcode: postcode,
      addressLine1: addressLine1,
      addressLine2: addressLine2,
      city: city,
      label: checkout.selectedAddressLabel.isNotEmpty
          ? checkout.selectedAddressLabel
          : 'Home',
    );

    ref.invalidate(addressesProvider);
    ref.invalidate(defaultAddressProvider);
    ref.invalidate(profileProvider);
  }

  String _emailDeliveryTypeLabel(String value) {
    switch (value) {
      case 'home_delivery':
        return 'Home Delivery';
      case 'local_pickup':
        return 'Local Pickup';
      default:
        return value.trim().isEmpty ? 'Delivery' : value;
    }
  }

  String _resolveCustomerName(CheckoutState checkout) {
    final fullName = _fullNameController.text.trim();
    if (fullName.isNotEmpty) return fullName;

    final savedName = checkout.selectedSavedAddress?.fullName.trim();
    if (savedName != null && savedName.isNotEmpty) return savedName;

    final addressName = checkout.address.fullName.trim();
    if (addressName.isNotEmpty) return addressName;

    final user = Supabase.instance.client.auth.currentUser;
    final metaName = (user?.userMetadata?['full_name'] as String?)?.trim();
    if (metaName != null && metaName.isNotEmpty) return metaName;

    final email = user?.email?.trim();
    if (email != null && email.isNotEmpty) {
      final at = email.indexOf('@');
      if (at > 0) return email.substring(0, at);
    }

    return 'Customer';
  }

  String _getCheckoutEmail() {
    final typedEmail = _emailController.text.trim();
    if (typedEmail.isNotEmpty) return typedEmail;

    final authEmail =
        Supabase.instance.client.auth.currentUser?.email?.trim() ?? '';
    if (authEmail.isNotEmpty) return authEmail;

    return '';
  }

  List<Map<String, dynamic>> _buildEmailItems(List<dynamic> cartItems) {
    return cartItems.map<Map<String, dynamic>>((item) {
      final cartItem = item as dynamic;
      final product = cartItem.product;

      final dynamic productName = product?.name ??
          cartItem.name ??
          cartItem.productName ??
          cartItem.title ??
          'Item';

      final dynamic qty = cartItem.qty ?? cartItem.quantity ?? 1;

      final dynamic priceCents = product?.salePriceCents ??
          product?.priceCents ??
          cartItem.priceCents ??
          cartItem.salePriceCents ??
          cartItem.unitPriceCents;

      return {
        'name': productName.toString(),
        'qty': qty is int ? qty : int.tryParse(qty.toString()) ?? 1,
        if (priceCents != null)
          'priceCents': priceCents is int
              ? priceCents
              : int.tryParse(priceCents.toString()),
      };
    }).toList();
  }

  Future<void> _sendOrderConfirmationEmail({
    required CheckoutState checkout,
    required dynamic placedOrder,
    required int totalCents,
    required List<dynamic> cartItems,
  }) async {
    final email = _getCheckoutEmail();

    if (email.isEmpty) {
      debugPrint('EMAIL SKIPPED: empty email');
      return;
    }

    final payload = {
      'email': email,
      'customerName': _resolveCustomerName(checkout),
      'orderNumber': placedOrder.orderNumber,
      'totalCents': totalCents,
      'items': _buildEmailItems(cartItems),
      'deliveryType': _emailDeliveryTypeLabel(checkout.deliveryType),
      'deliverySlot': checkout.deliverySlot,
    };

    final response = await Supabase.instance.client.functions.invoke(
      'send-order-email',
      body: payload,
    );

    if (response.status != 200) {
      throw Exception('send-order-email failed: ${response.data}');
    }
  }

  Future<void> _refreshBackendSummary() async {
    final checkout = ref.read(checkoutProvider);
    final cartItems = ref.read(cartProvider);
    final notifier = ref.read(checkoutProvider.notifier);

    final requestKey = '${checkout.deliveryType}|${checkout.useRewards}|'
        '${cartItems.map((e) => '${e.product.id}:${e.qty}').join(',')}';

    if (cartItems.isEmpty || checkout.deliveryType.isEmpty) {
      notifier.setBackendSummary(
        subtotalCents: 0,
        eligibleSubtotalCents: 0,
        deliveryFeeCents: 0,
        rewardDiscountCents: 0,
        totalCents: 0,
        pointsToRedeem: 0,
      );
      return;
    }

    try {
      notifier.setBackendSummaryLoading(true);

      final summary = await ref
          .read(checkoutServiceProvider)
          .getCheckoutSummary(
            deliveryType: checkout.deliveryType,
            useRewards: checkout.useRewards,
            cartItems: cartItems,
            postcode: checkout.deliveryType == 'home_delivery'
                ? (checkout.selectedSavedAddress?.postcode.isNotEmpty == true
                    ? checkout.selectedSavedAddress?.postcode
                    : checkout.address.postcode)
                : null,
          );

      final blockers = (summary['blockers'] as List<dynamic>? ?? const []);
      if ((summary['can_place_order'] == false) && blockers.isNotEmpty) {
        final firstBlocker = blockers.first;
        if (firstBlocker is Map<String, dynamic>) {
          final message = firstBlocker['message']?.toString().trim();
          if (message != null && message.isNotEmpty) {
            throw Exception(message);
          }
        } else if (firstBlocker is Map) {
          final message = firstBlocker['message']?.toString().trim();
          if (message != null && message.isNotEmpty) {
            throw Exception(message);
          }
        }
      }

      final latestCheckout = ref.read(checkoutProvider);
      final latestCartItems = ref.read(cartProvider);
      final latestKey =
          '${latestCheckout.deliveryType}|${latestCheckout.useRewards}|'
          '${latestCartItems.map((e) => '${e.product.id}:${e.qty}').join(',')}';

      if (requestKey != latestKey) return;

      notifier.setBackendSummary(
        subtotalCents: (summary['subtotal_cents'] as num?)?.toInt() ?? 0,
        eligibleSubtotalCents:
            (summary['eligible_subtotal_cents'] as num?)?.toInt() ??
                (summary['subtotal_cents'] as num?)?.toInt() ??
                0,
        deliveryFeeCents: (summary['delivery_fee_cents'] as num?)?.toInt() ?? 0,
        rewardDiscountCents:
            (summary['reward_discount_cents'] as num?)?.toInt() ?? 0,
        totalCents: (summary['total_cents'] as num?)?.toInt() ?? 0,
        pointsToRedeem: (summary['points_to_redeem'] as num?)?.toInt() ??
            (summary['points_redeemed'] as num?)?.toInt() ??
            0,
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Backend checkout summary failed: $e');
        debugPrint('$st');
      }
      notifier.setBackendSummaryError(
        friendlyCheckoutError(e),
      );
    }
  }

  void _handleSummaryRefresh(String key) {
    if (_summaryRefreshInFlight) return;
    if (_lastSummaryRefreshKey == key) return;

    _lastSummaryRefreshKey = key;
    _summaryRefreshInFlight = true;

    _refreshBackendSummary().whenComplete(() {
      _summaryRefreshInFlight = false;
    });
  }

  CheckoutAddress _currentManualAddress() {
    return CheckoutAddress(
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim(),
      addressLine1: _address1Controller.text.trim(),
      addressLine2: _address2Controller.text.trim(),
      city: _cityController.text.trim(),
      postcode: _postcodeController.text.trim(),
    );
  }

  bool _canPlaceOrder(
    CheckoutState checkout, {
    CheckoutAddress? manualAddress,
  }) {
    if (!_isValidEmail(_getCheckoutEmail())) return false;

    if (checkout.deliveryType.isEmpty ||
        checkout.deliverySlot.isEmpty ||
        checkout.paymentMethod.isEmpty) {
      return false;
    }

    if (checkout.deliveryType == 'local_pickup') {
      return true;
    }

    if (checkout.selectedSavedAddress != null) {
      return true;
    }

    return (manualAddress ?? checkout.address).isValid;
  }

  Future<void> _onPlaceOrder() async {
    final current = ref.read(checkoutProvider);
    if (current.isPlacingOrder) return;

    final checkout = current;
    final checkoutNotifier = ref.read(checkoutProvider.notifier);
    final cartItems = ref.read(cartProvider);
    final selectedSavedAddress = checkout.selectedSavedAddress;
    final checkoutEmail = _getCheckoutEmail();
    final manualAddress = _currentManualAddress();
    final effectiveAddress =
        selectedSavedAddress == null ? manualAddress : checkout.address;

    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty')),
      );
      return;
    }

    if (!_isValidEmail(_getCheckoutEmail())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please enter a valid email address for order updates.'),
        ),
      );
      return;
    }

    if (!_canPlaceOrder(checkout, manualAddress: manualAddress)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete the required checkout details'),
        ),
      );
      return;
    }

    if (checkout.deliveryType == 'home_delivery' &&
        selectedSavedAddress == null &&
        !PostcodeLookupService.isDeliveryArea(manualAddress.postcode)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sorry, we do not deliver to this postcode area yet. We currently deliver to: ${PostcodeLookupService.deliveryAreas.join(", ")}',
          ),
        ),
      );
      return;
    }

    try {
      checkoutNotifier.setPlacingOrder(true);

      await ensureSupabaseUser();
      await _refreshBackendSummary();
      final refreshedCheckout = ref.read(checkoutProvider);

      if (refreshedCheckout.backendSummaryError.isNotEmpty) {
        throw Exception(refreshedCheckout.backendSummaryError);
      }

      final confirmedTotalCents = refreshedCheckout.backendTotalCents;

      if (checkout.paymentMethod == 'card' && confirmedTotalCents > 0) {
        final paymentResult =
            await _stripePaymentService.createCheckoutPaymentIntent(
          address: effectiveAddress,
          addressId: selectedSavedAddress?.id,
          deliveryType: checkout.deliveryType,
          deliverySlot: checkout.deliverySlot,
          paymentMethod: checkout.paymentMethod,
          useRewards: checkout.useRewards,
          cartItems: cartItems,
        );

        final placedOrder =
            await ref.read(checkoutServiceProvider).placeOrderAfterPayment(
                  paymentIntentId: paymentResult.paymentIntentId,
                  address: effectiveAddress,
                  checkoutEmail: checkoutEmail,
                  addressId: selectedSavedAddress?.id,
                  deliveryType: checkout.deliveryType,
                  deliverySlot: checkout.deliverySlot,
                  paymentMethod: checkout.paymentMethod,
                  useRewards: checkout.useRewards,
                  cartItems: cartItems,
                );

        try {
          await _saveAddressAfterSuccessfulOrder();
        } catch (e, st) {
          debugPrint('SAVE ADDRESS AFTER ORDER FAILED: $e');
          debugPrint('$st');
        }

        try {
          await _sendOrderConfirmationEmail(
            checkout: checkout,
            placedOrder: placedOrder,
            totalCents: confirmedTotalCents,
            cartItems: cartItems,
          );
        } catch (e, st) {
          if (kDebugMode) {
            debugPrint('SEND ORDER EMAIL FAILED: $e');
            debugPrint('$st');
          }
        }

        ref.read(cartProvider.notifier).clear();
        ref.invalidate(adminOrdersProvider);

        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => OrderSuccessScreen(
              orderId: placedOrder.orderId,
              orderNumber: placedOrder.orderNumber,
            ),
          ),
        );

        return;
      }

      final paymentStatus = confirmedTotalCents == 0 ? 'paid' : 'cod_pending';

      final placedOrder = await ref.read(checkoutServiceProvider).placeOrder(
            address: effectiveAddress,
            checkoutEmail: checkoutEmail,
            addressId: selectedSavedAddress?.id,
            deliveryType: checkout.deliveryType,
            deliverySlot: checkout.deliverySlot,
            paymentMethod: checkout.paymentMethod,
            useRewards: checkout.useRewards,
            cartItems: cartItems,
            paymentStatus: paymentStatus,
            stripePaymentIntentId: null,
          );

      try {
        await _saveAddressAfterSuccessfulOrder();
      } catch (e, st) {
        debugPrint('SAVE ADDRESS AFTER ORDER FAILED: $e');
        debugPrint('$st');
      }

      try {
        await _sendOrderConfirmationEmail(
          checkout: checkout,
          placedOrder: placedOrder,
          totalCents: confirmedTotalCents,
          cartItems: cartItems,
        );
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('SEND ORDER EMAIL FAILED: $e');
          debugPrint('$st');
        }
      }

      ref.read(cartProvider.notifier).clear();
      ref.invalidate(adminOrdersProvider);

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => OrderSuccessScreen(
            orderId: placedOrder.orderId,
            orderNumber: placedOrder.orderNumber,
          ),
        ),
      );
    } on StripeException catch (e) {
      if (!mounted) return;

      final message = e.error.localizedMessage ?? 'Payment cancelled';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Failed to place order: $e');
        debugPrint('$st');
      }
      final friendlyMessage = friendlyCheckoutError(e);
      ref
          .read(checkoutProvider.notifier)
          .setBackendSummaryError(friendlyMessage);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            friendlyMessage,
          ),
        ),
      );
    } finally {
      checkoutNotifier.setPlacingOrder(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final checkout = ref.watch(checkoutProvider);
    final cartItems = ref.watch(cartProvider);
    final addressesAsync = ref.watch(addressesProvider);

    final summaryRefreshKey = '${checkout.deliveryType}|${checkout.useRewards}|'
        '${cartItems.map((e) => '${e.product.id}:${e.qty}').join(',')}';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _handleSummaryRefresh(summaryRefreshKey);
    });

    final pricing = CartPricing.fromItems(
      cartItems,
      deliveryType: checkout.deliveryType,
      rewardDiscountCents:
          checkout.useRewards ? checkout.appliedRewardPence : 0,
    );

    final hasBackendSummary = checkout.backendSummaryLoaded;

    final subtotalCents = hasBackendSummary
        ? checkout.backendSubtotalCents
        : pricing.subtotalCents;

    final eligibleSubtotalCents = hasBackendSummary
        ? checkout.backendEligibleSubtotalCents
        : pricing.eligibleSubtotalCents;

    final deliveryFeeCents = hasBackendSummary
        ? checkout.backendDeliveryFeeCents
        : pricing.deliveryFeeCents;

    final appliedRewardCents = hasBackendSummary
        ? checkout.backendRewardDiscountCents
        : pricing.rewardDiscountCents;

    final totalCents =
        hasBackendSummary ? checkout.backendTotalCents : pricing.totalCents;
    final maxRewardUsableCents =
        checkout.availableRewardPence.clamp(0, eligibleSubtotalCents);

    final effectiveRewardDiscountCents = hasBackendSummary
        ? checkout.backendRewardDiscountCents
        : pricing.rewardDiscountCents;

    if (checkout.useRewards &&
        checkout.appliedRewardPence != effectiveRewardDiscountCents) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(checkoutProvider.notifier)
            .setAppliedRewardPence(effectiveRewardDiscountCents);
      });
    }

    if (!checkout.useRewards && checkout.appliedRewardPence != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(checkoutProvider.notifier).setAppliedRewardPence(0);
      });
    }

    final isGuestCheckout = _isGuestCheckout;

    return Scaffold(
      backgroundColor: _wmCheckoutBg,
      body: SafeArea(
        child: Column(
          children: [
            const _CheckoutHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                children: [
                  addressesAsync.when(
                    loading: () => const _SectionCard(
                      title: 'Delivery Address',
                      child: _InlineLoadingRow(
                        text: 'Loading saved addresses...',
                      ),
                    ),
                    error: (_, __) => _buildAddressSection(
                      checkout: checkout,
                      addresses: const [],
                    ),
                    data: (addresses) {
                      _ensureSavedAddressSelection(addresses);
                      return _buildAddressSection(
                        checkout: checkout,
                        addresses: addresses,
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Delivery',
                    child: Column(
                      children: [
                        _ChoiceTile(
                          title: 'Home Delivery',
                          subtitle: 'Delivered to your address',
                          selected: checkout.deliveryType == 'home_delivery',
                          onTap: () => ref
                              .read(checkoutProvider.notifier)
                              .updateDeliveryType('home_delivery'),
                        ),
                        const SizedBox(height: 10),
                        _ChoiceTile(
                          title: 'Local Pickup',
                          subtitle: 'Collect from store',
                          selected: checkout.deliveryType == 'local_pickup',
                          onTap: () => ref
                              .read(checkoutProvider.notifier)
                              .updateDeliveryType('local_pickup'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Delivery Slot',
                    child: Column(
                      children: [
                        _ChoiceTile(
                          title: 'Tomorrow • 6 PM - 8 PM',
                          selected:
                              checkout.deliverySlot == 'Tomorrow • 6 PM - 8 PM',
                          onTap: () => ref
                              .read(checkoutProvider.notifier)
                              .updateDeliverySlot('Tomorrow • 6 PM - 8 PM'),
                        ),
                        const SizedBox(height: 10),
                        _ChoiceTile(
                          title: 'Tomorrow • 8 PM - 10 PM',
                          selected: checkout.deliverySlot ==
                              'Tomorrow • 8 PM - 10 PM',
                          onTap: () => ref
                              .read(checkoutProvider.notifier)
                              .updateDeliverySlot('Tomorrow • 8 PM - 10 PM'),
                        ),
                        const SizedBox(height: 10),
                        _ChoiceTile(
                          title: 'Saturday • 10 AM - 12 PM',
                          selected: checkout.deliverySlot ==
                              'Saturday • 10 AM - 12 PM',
                          onTap: () => ref
                              .read(checkoutProvider.notifier)
                              .updateDeliverySlot('Saturday • 10 AM - 12 PM'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Payment Method',
                    child: Column(
                      children: [
                        _ChoiceTile(
                          title: 'Cash on Delivery',
                          subtitle: 'Pay when your order arrives',
                          selected: checkout.paymentMethod == 'cod',
                          onTap: () => ref
                              .read(checkoutProvider.notifier)
                              .updatePaymentMethod('cod'),
                        ),
                        const SizedBox(height: 10),
                        _ChoiceTile(
                          title: 'Card / Apple Pay / Google Pay',
                          subtitle: 'Secure online payment with Stripe',
                          selected: checkout.paymentMethod == 'card',
                          onTap: () => ref
                              .read(checkoutProvider.notifier)
                              .updatePaymentMethod('card'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _RewardsCheckoutCard(
                    availableRewardPence: checkout.availableRewardPence,
                    appliedRewardPence: appliedRewardCents,
                    pointsToNextReward: checkout.pointsToNextReward,
                    useRewards: checkout.useRewards,
                    maxRedeemablePence: maxRewardUsableCents,
                    isLoading: checkout.rewardsLoading,
                    message: isGuestCheckout
                        ? _guestCheckoutBenefitsText()
                        : checkout.rewardsMessage,
                    isGuestCheckout: isGuestCheckout,
                    onToggle: (value) {
                      if (isGuestCheckout) return;

                      final notifier = ref.read(checkoutProvider.notifier);
                      notifier.toggleUseRewards(value);
                      notifier.setAppliedRewardPence(
                        value ? maxRewardUsableCents : 0,
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Order Summary',
                    child: Column(
                      children: [
                        if (checkout.backendSummaryLoading) ...[
                          const _InlineLoadingRow(
                            text: 'Confirming latest total...',
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (checkout.backendSummaryError.isNotEmpty) ...[
                          _AmazonInfoBanner(
                            icon: Icons.info_outline_rounded,
                            text: checkout.backendSummaryError,
                          ),
                          const SizedBox(height: 12),
                        ],
                        _PriceRow(
                          label: 'Items',
                          value:
                              '${cartItems.fold<int>(0, (sum, item) => sum + item.qty)}',
                        ),
                        const SizedBox(height: 10),
                        _PriceRow(
                          label: 'Subtotal',
                          value: _money(subtotalCents),
                        ),
                        if (appliedRewardCents > 0) ...[
                          const SizedBox(height: 10),
                          _PriceRow(
                            label: 'Rewards',
                            value: '-${_money(appliedRewardCents)}',
                            valueColor: _wmCheckoutSuccess,
                          ),
                        ],
                        const SizedBox(height: 10),
                        _PriceRow(
                          label: 'Delivery Fee',
                          value: _money(deliveryFeeCents),
                        ),
                        const Divider(height: 24),
                        _PriceRow(
                          label: 'Total',
                          value: _money(totalCents),
                          bold: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              decoration: const BoxDecoration(
                color: _wmCheckoutSurface,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 10,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: checkout.isPlacingOrder ? null : _onPlaceOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _wmCheckoutPrimary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: checkout.isPlacingOrder
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Place Order • ${_money(totalCents)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection({
    required CheckoutState checkout,
    required List<AddressModel> addresses,
  }) {
    final hasSavedAddresses = addresses.isNotEmpty;
    final selectedSaved = checkout.selectedSavedAddress;
    final matchedSelectedSaved = selectedSaved == null
        ? null
        : addresses.cast<AddressModel?>().firstWhere(
              (a) => a?.id == selectedSaved.id,
              orElse: () => null,
            );

    final preferredSavedAddress = matchedSelectedSaved ??
        (hasSavedAddresses
            ? addresses.cast<AddressModel?>().firstWhere(
                  (a) => a?.isDefault == true,
                  orElse: () => addresses.first,
                )
            : null);

    final shouldShowManualForm = !hasSavedAddresses ||
        _showManualAddressForm ||
        checkout.deliveryType == 'local_pickup';

    return _SectionCard(
      title: 'Delivery Address',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CheckoutTextField(
            label: 'Email Address',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) {},
          ),
          const SizedBox(height: 12),
          if (_isGuestCheckout) ...[
            const _AmazonInfoBanner(
              icon: Icons.stars_rounded,
              text:
                  'Guest checkout is available. Sign in to collect rewards, save addresses, and track your orders more easily.',
            ),
            const SizedBox(height: 12),
          ],
          if (checkout.deliveryType == 'local_pickup')
            const _AmazonInfoBanner(
              icon: Icons.storefront_outlined,
              text:
                  'Pickup selected. You can collect your order from the store.',
            )
          else if (hasSavedAddresses && !shouldShowManualForm) ...[
            if (preferredSavedAddress != null)
              _CompactSavedAddressCard(
                address: preferredSavedAddress,
                onChangeTap: () => _showSavedAddressesSheet(addresses),
                onNewAddressTap: _openManualAddressMode,
              )
            else
              _SavedAddressesEntryCard(
                count: addresses.length,
                onTap: () => _showSavedAddressesSheet(addresses),
                onNewAddressTap: _openManualAddressMode,
              ),
          ] else ...[
            if (hasSavedAddresses) ...[
              _SavedAddressesEntryCard(
                count: addresses.length,
                onTap: () => _showSavedAddressesSheet(addresses),
                onNewAddressTap: _openManualAddressMode,
              ),
              const SizedBox(height: 12),
            ],
            if (checkout.deliveryType == 'home_delivery')
              const _AmazonInfoBanner(
                icon: Icons.info_outline_rounded,
                text:
                    'Search by postcode to prefill your address, then review or complete the delivery details manually below.',
              ),
            if (checkout.deliveryType == 'home_delivery') ...[
              const SizedBox(height: 14),
              _CheckoutTextField(
                label: 'Full Name',
                controller: _fullNameController,
                onChanged: ref.read(checkoutProvider.notifier).updateFullName,
              ),
              const SizedBox(height: 12),
              _CheckoutTextField(
                label: 'Phone Number',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                onChanged: ref.read(checkoutProvider.notifier).updatePhone,
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _wmCheckoutBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          color: _wmCheckoutPrimary,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Find Address By Postcode',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: _wmCheckoutTextStrong,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Use postcode search for speed, or continue with manual entry below and edit anything that needs changing.',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _wmCheckoutTextSoft,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _CheckoutTextField(
                            label: 'Postcode',
                            controller: _postcodeController,
                            onChanged: ref
                                .read(checkoutProvider.notifier)
                                .updatePostcode,
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: (checkout.isCheckingPostcode ||
                                    checkout.isLookingUpAddress)
                                ? null
                                : _findAddress,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _wmCheckoutPrimary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: (checkout.isCheckingPostcode ||
                                    checkout.isLookingUpAddress)
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.search_rounded),
                            label: const Text(
                              'Search',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (checkout.postcodeStatusMessage.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: checkout.postcodeEligible
                        ? _wmCheckoutSuccessSoft
                        : _wmCheckoutDangerSoft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: checkout.postcodeEligible
                          ? const Color(0xFFBBF7D0)
                          : const Color(0xFFFECACA),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        checkout.postcodeEligible
                            ? Icons.check_circle_rounded
                            : Icons.info_rounded,
                        color: checkout.postcodeEligible
                            ? _wmCheckoutSuccess
                            : _wmCheckoutDanger,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          checkout.postcodeStatusMessage,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _wmCheckoutTextStrong,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (checkout.selectedAddressLabel.isNotEmpty) ...[
                const SizedBox(height: 12),
                _AmazonSelectionCard(
                  icon: Icons.home_rounded,
                  title: 'Address Found',
                  subtitle:
                      '${checkout.selectedAddressLabel}\nReview the fields below before placing the order.',
                  accent: _wmCheckoutPrimary,
                ),
              ],
              const SizedBox(height: 14),
              const Text(
                'Delivery Details',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: _wmCheckoutTextStrong,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Manual entry is always available. Postcode search simply helps fill the address faster.',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: _wmCheckoutTextSoft,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              _CheckoutTextField(
                label: 'Address Line 1',
                controller: _address1Controller,
                onChanged:
                    ref.read(checkoutProvider.notifier).updateAddressLine1,
              ),
              const SizedBox(height: 12),
              _CheckoutTextField(
                label: 'Address Line 2',
                controller: _address2Controller,
                onChanged:
                    ref.read(checkoutProvider.notifier).updateAddressLine2,
              ),
              const SizedBox(height: 12),
              _CheckoutTextField(
                label: 'City',
                controller: _cityController,
                onChanged: ref.read(checkoutProvider.notifier).updateCity,
              ),
              if (hasSavedAddresses) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showManualAddressForm = false;
                      });
                      _ensureSavedAddressSelection(addresses);
                    },
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text(
                      'Use saved address instead',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: _wmCheckoutPrimary,
                    ),
                  ),
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }

  static String _money(int cents) => '£${(cents / 100).toStringAsFixed(2)}';
}

class _CompactSavedAddressCard extends StatelessWidget {
  final AddressModel address;
  final VoidCallback onChangeTap;
  final VoidCallback onNewAddressTap;

  const _CompactSavedAddressCard({
    required this.address,
    required this.onChangeTap,
    required this.onNewAddressTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _wmCheckoutBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: _wmCheckoutPrimary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Deliver to ${address.label}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: _wmCheckoutTextStrong,
                  ),
                ),
              ),
              if (address.isDefault)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _wmCheckoutPrimary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Default',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            address.fullDisplay,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _wmCheckoutTextSoft,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              TextButton.icon(
                onPressed: onChangeTap,
                icon: const Icon(Icons.swap_horiz_rounded),
                label: const Text(
                  'Change',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: _wmCheckoutPrimary,
                ),
              ),
              TextButton.icon(
                onPressed: onNewAddressTap,
                icon: const Icon(Icons.add_location_alt_outlined),
                label: const Text(
                  'New address',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: _wmCheckoutPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SavedAddressesEntryCard extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  final VoidCallback onNewAddressTap;

  const _SavedAddressesEntryCard({
    required this.count,
    required this.onTap,
    required this.onNewAddressTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _wmCheckoutBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _wmCheckoutSurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.bookmark_border_rounded,
              color: _wmCheckoutPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Use a saved address',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: _wmCheckoutTextStrong,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count saved address(es) available for this account',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _wmCheckoutTextSoft,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: onTap,
                      style: TextButton.styleFrom(
                        foregroundColor: _wmCheckoutPrimary,
                      ),
                      child: const Text(
                        'Choose',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    TextButton(
                      onPressed: onNewAddressTap,
                      style: TextButton.styleFrom(
                        foregroundColor: _wmCheckoutPrimary,
                      ),
                      child: const Text(
                        'New address',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineLoadingRow extends StatelessWidget {
  final String text;

  const _InlineLoadingRow({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            color: _wmCheckoutPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _wmCheckoutTextSoft,
            ),
          ),
        ),
      ],
    );
  }
}

class _SavedAddressPickerSheet extends StatelessWidget {
  final List<AddressModel> items;
  final ValueChanged<AddressModel> onSelected;

  const _SavedAddressPickerSheet({
    required this.items,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 560,
      decoration: const BoxDecoration(
        color: _wmCheckoutSurface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 14),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.bookmark_border_rounded,
                  color: _wmCheckoutPrimary,
                ),
                SizedBox(width: 8),
                Text(
                  'Choose saved address',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _wmCheckoutTextStrong,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.home_rounded,
                      color: _wmCheckoutPrimary,
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: _wmCheckoutTextStrong,
                          ),
                        ),
                      ),
                      if (item.isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _wmCheckoutPrimary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Default',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      item.fullDisplay,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _wmCheckoutTextSoft,
                        height: 1.35,
                      ),
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: _wmCheckoutTextMuted,
                  ),
                  onTap: () {
                    onSelected(item);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressPickerSheet extends StatelessWidget {
  final List<AddressLookupItem> items;
  final ValueChanged<AddressLookupItem> onSelected;

  const _AddressPickerSheet({
    required this.items,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 520,
      decoration: const BoxDecoration(
        color: _wmCheckoutSurface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 14),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  color: _wmCheckoutPrimary,
                ),
                SizedBox(width: 8),
                Text(
                  'Select your address',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _wmCheckoutTextStrong,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.home_rounded,
                      color: _wmCheckoutPrimary,
                    ),
                  ),
                  title: Text(
                    item.line1.isEmpty ? item.displayText : item.line1,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: _wmCheckoutTextStrong,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      item.displayText,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _wmCheckoutTextSoft,
                      ),
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: _wmCheckoutTextMuted,
                  ),
                  onTap: () {
                    onSelected(item);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutHeader extends StatelessWidget {
  const _CheckoutHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: _wmCheckoutSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _wmCheckoutBorder),
            ),
            child: IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _wmCheckoutPrimary,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Checkout',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: _wmCheckoutTextStrong,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _wmCheckoutSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _wmCheckoutBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _wmCheckoutTextStrong,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _CheckoutTextField extends StatelessWidget {
  final String label;
  final void Function(String) onChanged;
  final TextInputType? keyboardType;
  final TextEditingController? controller;

  const _CheckoutTextField({
    required this.label,
    required this.onChanged,
    this.keyboardType,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: _wmCheckoutTextSoft,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _wmCheckoutBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: _wmCheckoutPrimary,
            width: 1.2,
          ),
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceTile({
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? _wmCheckoutPrimary : _wmCheckoutBorder;
    final bgColor = selected ? const Color(0xFFF9FAFB) : _wmCheckoutSurface;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: _wmCheckoutTextStrong,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: _wmCheckoutTextSoft,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? _wmCheckoutPrimary : _wmCheckoutTextMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardsCheckoutCard extends StatelessWidget {
  final int availableRewardPence;
  final int appliedRewardPence;
  final int pointsToNextReward;
  final int maxRedeemablePence;
  final bool useRewards;
  final bool isLoading;
  final bool isGuestCheckout;
  final String message;
  final ValueChanged<bool> onToggle;

  const _RewardsCheckoutCard({
    required this.availableRewardPence,
    required this.appliedRewardPence,
    required this.pointsToNextReward,
    required this.maxRedeemablePence,
    required this.useRewards,
    required this.isLoading,
    required this.isGuestCheckout,
    required this.message,
    required this.onToggle,
  });

  static String _money(int cents) => '£${(cents / 100).toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final canRedeem = !isGuestCheckout &&
        availableRewardPence > 0 &&
        maxRedeemablePence > 0 &&
        !isLoading;

    final effectiveRedeemable =
        availableRewardPence.clamp(0, maxRedeemablePence);

    final titleText = isGuestCheckout
        ? 'Sign in to collect rewards'
        : canRedeem
            ? '${_money(effectiveRedeemable)} available'
            : 'No rewards available yet';

    final subtitleText = isGuestCheckout
        ? 'Create an account or sign in to earn points on this order, unlock rewards, save addresses, and track future orders.'
        : canRedeem
            ? appliedRewardPence > 0
                ? '${_money(appliedRewardPence)} reward discount applied to this order.'
                : 'Apply your rewards to reduce this order total.'
            : pointsToNextReward > 0
                ? 'Only $pointsToNextReward more points to unlock your next £2 reward.'
                : 'Rewards will appear here once available.';

    return _SectionCard(
      title: 'Rewards',
      child: isLoading
          ? const _InlineLoadingRow(text: 'Checking your rewards...')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isGuestCheckout
                        ? _wmCheckoutAmberSoft
                        : canRedeem
                            ? const Color(0xFFF9FAFB)
                            : const Color(0xFFFBFBFB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isGuestCheckout
                          ? const Color(0xFFFED7AA)
                          : canRedeem
                              ? _wmCheckoutBorder
                              : const Color(0xFFEAEAEA),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: isGuestCheckout
                              ? _wmCheckoutAmber
                              : canRedeem
                                  ? _wmCheckoutPrimary
                                  : const Color(0xFFD7D7D7),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          isGuestCheckout
                              ? Icons.stars_rounded
                              : Icons.card_giftcard_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titleText,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: _wmCheckoutTextStrong,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitleText,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: _wmCheckoutTextSoft,
                                height: 1.35,
                              ),
                            ),
                            if (message.trim().isNotEmpty &&
                                !isGuestCheckout) ...[
                              const SizedBox(height: 6),
                              Text(
                                message,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _wmCheckoutTextMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (!isGuestCheckout)
                        Switch.adaptive(
                          value: canRedeem ? useRewards : false,
                          onChanged: canRedeem ? onToggle : null,
                          activeThumbColor: _wmCheckoutPrimary,
                          activeTrackColor:
                              _wmCheckoutPrimary.withValues(alpha: 0.35),
                        ),
                    ],
                  ),
                ),
                if (canRedeem && availableRewardPence > maxRedeemablePence) ...[
                  const SizedBox(height: 10),
                  const _AmazonInfoBanner(
                    icon: Icons.info_outline_rounded,
                    text:
                        'Only product subtotal can be discounted. Delivery fee is not reduced by rewards.',
                  ),
                ],
              ],
            ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _PriceRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      fontSize: bold ? 17 : 15,
      fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
      color: bold ? _wmCheckoutTextStrong : _wmCheckoutTextStrong,
    );

    final resolvedValueColor =
        valueColor ?? (bold ? _wmCheckoutPrimary : _wmCheckoutTextStrong);

    final valueStyle = TextStyle(
      fontSize: bold ? 17 : 15,
      fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
      color: resolvedValueColor,
    );

    return Row(
      children: [
        Text(label, style: labelStyle),
        const Spacer(),
        Text(value, style: valueStyle),
      ],
    );
  }
}

class _AmazonInfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;

  const _AmazonInfoBanner({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _wmCheckoutAmberSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFFB45309)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF78350F),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmazonSelectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;

  const _AmazonSelectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _wmCheckoutSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: _wmCheckoutTextStrong,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _wmCheckoutTextSoft,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
