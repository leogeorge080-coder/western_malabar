import 'checkout_address.dart';

class CheckoutOrderRequest {
  final CheckoutAddress address;
  final String deliveryType; // home_delivery / local_pickup
  final String deliverySlot;
  final String paymentMethod; // cod / card
  final int subtotalCents;
  final int deliveryFeeCents;
  final int totalCents;

  const CheckoutOrderRequest({
    required this.address,
    required this.deliveryType,
    required this.deliverySlot,
    required this.paymentMethod,
    required this.subtotalCents,
    required this.deliveryFeeCents,
    required this.totalCents,
  });
}




