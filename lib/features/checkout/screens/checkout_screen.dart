import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'package:western_malabar/core/pricing/cart_pricing.dart';
import 'package:western_malabar/features/admin/providers/admin_orders_provider.dart';
import 'package:western_malabar/features/checkout/providers/checkout_provider.dart';
import 'package:western_malabar/features/checkout/screens/order_success_screen.dart';
import 'package:western_malabar/features/checkout/services/checkout_service.dart';
import 'package:western_malabar/features/checkout/services/stripe_payment_service.dart';
import 'package:western_malabar/services/postcode_lookup_service.dart';
import 'package:western_malabar/state/cart_provider.dart';
import 'package:western_malabar/theme.dart';
import 'package:western_malabar/theme/wm_gradients.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _postcodeController;
  late final TextEditingController _address1Controller;
  late final TextEditingController _address2Controller;
  late final TextEditingController _cityController;

  final StripePaymentService _stripePaymentService =
      const StripePaymentService();

  @override
  void initState() {
    super.initState();
    final checkout = ref.read(checkoutProvider);

    _fullNameController =
        TextEditingController(text: checkout.address.fullName);
    _phoneController = TextEditingController(text: checkout.address.phone);
    _postcodeController =
        TextEditingController(text: checkout.address.postcode);
    _address1Controller =
        TextEditingController(text: checkout.address.addressLine1);
    _address2Controller =
        TextEditingController(text: checkout.address.addressLine2);
    _cityController = TextEditingController(text: checkout.address.city);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _postcodeController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    super.dispose();
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Address lookup failed: $e')),
      );
    } finally {
      notifier.setCheckingPostcode(false);
      notifier.setLookingUpAddress(false);
    }
  }

  Future<void> _onPlaceOrder() async {
    final checkout = ref.read(checkoutProvider);
    final checkoutNotifier = ref.read(checkoutProvider.notifier);
    final cartItems = ref.read(cartProvider);

    final pricing = CartPricing.fromItems(
      cartItems,
      deliveryType: checkout.deliveryType,
    );

    final subtotalCents = pricing.subtotalCents;
    final deliveryFeeCents = pricing.deliveryFeeCents;
    final totalCents = pricing.totalCents;

    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty')),
      );
      return;
    }

    if (!checkoutNotifier.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required checkout details'),
        ),
      );
      return;
    }

    if (checkout.deliveryType == 'home_delivery' &&
        !PostcodeLookupService.isDeliveryArea(checkout.address.postcode)) {
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

      String? stripePaymentIntentId;
      String paymentStatus = 'pending';

      if (checkout.paymentMethod == 'card') {
        final result = await _stripePaymentService.pay(
          amountCents: totalCents,
          currency: 'GBP',
          customerName: checkout.address.fullName,
          customerPhone: checkout.address.phone,
          customerEmail: '',
          orderLabel: 'Malabar Hub Order',
        );

        stripePaymentIntentId = result.paymentIntentId;
        paymentStatus = 'paid';
      } else {
        paymentStatus = 'cod_pending';
      }

      await ensureSupabaseUser();

      final placedOrder = await ref.read(checkoutServiceProvider).placeOrder(
            address: checkout.address,
            deliveryType: checkout.deliveryType,
            deliverySlot: checkout.deliverySlot,
            paymentMethod: checkout.paymentMethod,
            subtotalCents: subtotalCents,
            deliveryFeeCents: deliveryFeeCents,
            totalCents: totalCents,
            cartItems: cartItems,
            paymentStatus: paymentStatus,
            stripePaymentIntentId: stripePaymentIntentId,
          );

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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to place order: $e')),
      );
    } finally {
      checkoutNotifier.setPlacingOrder(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final checkout = ref.watch(checkoutProvider);
    final cartItems = ref.watch(cartProvider);

    final pricing = CartPricing.fromItems(
      cartItems,
      deliveryType: checkout.deliveryType,
    );

    final subtotalCents = pricing.subtotalCents;
    final deliveryFeeCents = pricing.deliveryFeeCents;
    final totalCents = pricing.totalCents;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Container(
        decoration: const BoxDecoration(
          gradient: WMGradients.pageBackground,
        ),
        child: SafeArea(
          child: Column(
            children: [
              const _CheckoutHeader(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                  children: [
                    _SectionCard(
                      title: 'Delivery Address',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _AmazonInfoBanner(
                            icon: Icons.info_outline_rounded,
                            text:
                                'Enter your postcode, find your address, and confirm your delivery details.',
                          ),
                          const SizedBox(height: 14),
                          _CheckoutTextField(
                            label: 'Full Name',
                            controller: _fullNameController,
                            onChanged: ref
                                .read(checkoutProvider.notifier)
                                .updateFullName,
                          ),
                          const SizedBox(height: 12),
                          _CheckoutTextField(
                            label: 'Phone Number',
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            onChanged:
                                ref.read(checkoutProvider.notifier).updatePhone,
                          ),
                          const SizedBox(height: 12),
                          Row(
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
                                    backgroundColor: WMTheme.royalPurple,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
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
                                    'Find Address',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (checkout.postcodeStatusMessage.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: checkout.postcodeEligible
                                    ? const Color(0xFFF1FAF3)
                                    : const Color(0xFFFFF4F4),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: checkout.postcodeEligible
                                      ? const Color(0xFFBFE3C7)
                                      : const Color(0xFFFFD1D1),
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
                                        ? Colors.green
                                        : Colors.redAccent,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      checkout.postcodeStatusMessage,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
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
                              title: 'Selected Address',
                              subtitle: checkout.selectedAddressLabel,
                              accent: WMTheme.royalPurple,
                            ),
                          ],
                          const SizedBox(height: 12),
                          _CheckoutTextField(
                            label: 'Address Line 1',
                            controller: _address1Controller,
                            onChanged: ref
                                .read(checkoutProvider.notifier)
                                .updateAddressLine1,
                          ),
                          const SizedBox(height: 12),
                          _CheckoutTextField(
                            label: 'Address Line 2',
                            controller: _address2Controller,
                            onChanged: ref
                                .read(checkoutProvider.notifier)
                                .updateAddressLine2,
                          ),
                          const SizedBox(height: 12),
                          _CheckoutTextField(
                            label: 'City',
                            controller: _cityController,
                            onChanged:
                                ref.read(checkoutProvider.notifier).updateCity,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: 'Delivery Type',
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
                            selected: checkout.deliverySlot ==
                                'Tomorrow • 6 PM - 8 PM',
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
                    _SectionCard(
                      title: 'Order Summary',
                      child: Column(
                        children: [
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
                  color: Colors.white,
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
                        backgroundColor: WMTheme.royalPurple,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(54),
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
      ),
    );
  }

  static String _money(int cents) => '£${(cents / 100).toStringAsFixed(2)}';
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
        color: Colors.white,
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
                  color: WMTheme.royalPurple,
                ),
                SizedBox(width: 8),
                Text(
                  'Select your address',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
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
                      color: const Color(0xFFF6F0FB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.home_rounded,
                      color: WMTheme.royalPurple,
                    ),
                  ),
                  title: Text(
                    item.line1.isEmpty ? item.displayText : item.line1,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      item.displayText,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.black38,
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
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
          const Expanded(
            child: Text(
              'Checkout',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
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
        filled: true,
        fillColor: const Color(0xFFF9F6FC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
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
    final borderColor =
        selected ? WMTheme.royalPurple : const Color(0xFFE7E0EF);
    final bgColor = selected ? const Color(0xFFF6F0FB) : Colors.white;

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
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: Colors.black54,
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
                color: selected ? WMTheme.royalPurple : Colors.black38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _PriceRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: bold ? 17 : 15,
      fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
      color: bold ? WMTheme.royalPurple : Colors.black87,
    );

    return Row(
      children: [
        Text(label, style: style),
        const Spacer(),
        Text(value, style: style),
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
        color: const Color(0xFFFFF8E7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0D98D)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF8A6700)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B5400),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withOpacity(0.20)),
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
              color: accent.withOpacity(0.10),
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
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
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
