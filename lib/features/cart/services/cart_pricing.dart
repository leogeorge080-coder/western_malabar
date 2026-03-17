import 'package:western_malabar/features/cart/providers/cart_provider.dart';

class CartPricingBreakdown {
  final int subtotalCents;
  final int deliveryFeeCents;
  final int totalCents;
  final bool unlockedFreeDelivery;
  final int freeDeliveryThresholdCents;

  const CartPricingBreakdown({
    required this.subtotalCents,
    required this.deliveryFeeCents,
    required this.totalCents,
    required this.unlockedFreeDelivery,
    required this.freeDeliveryThresholdCents,
  });
}

class CartPricing {
  static const int freeDeliveryThresholdCents = 2000; // £20
  static const int standardDeliveryFeeCents = 250; // £2.50

  static int subtotalFromItems(List<CartItem> items) {
    int sum = 0;
    for (final e in items) {
      final cents = e.product.salePriceCents ?? e.product.priceCents ?? 0;
      sum += cents * e.qty;
    }
    return sum;
  }

  static CartPricingBreakdown fromItems(
    List<CartItem> items, {
    required String deliveryType,
  }) {
    final subtotalCents = subtotalFromItems(items);

    final isHomeDelivery = deliveryType == 'home_delivery';
    final unlockedFreeDelivery =
        isHomeDelivery && subtotalCents >= freeDeliveryThresholdCents;

    final deliveryFeeCents = !isHomeDelivery
        ? 0
        : (unlockedFreeDelivery ? 0 : standardDeliveryFeeCents);

    final totalCents = subtotalCents + deliveryFeeCents;

    return CartPricingBreakdown(
      subtotalCents: subtotalCents,
      deliveryFeeCents: deliveryFeeCents,
      totalCents: totalCents,
      unlockedFreeDelivery: unlockedFreeDelivery,
      freeDeliveryThresholdCents: freeDeliveryThresholdCents,
    );
  }
}


