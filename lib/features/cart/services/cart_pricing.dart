import 'package:western_malabar/features/cart/providers/cart_provider.dart';

class CartPricing {
  final int subtotalCents;
  final int eligibleSubtotalCents;
  final int deliveryFeeCents;
  final int rewardDiscountCents;
  final int totalCents;
  final int freeDeliveryThresholdCents;
  final bool unlockedFreeDelivery;

  const CartPricing({
    required this.subtotalCents,
    required this.eligibleSubtotalCents,
    required this.deliveryFeeCents,
    required this.rewardDiscountCents,
    required this.totalCents,
    required this.freeDeliveryThresholdCents,
    required this.unlockedFreeDelivery,
  });

  factory CartPricing.fromItems(
    List<CartItem> items, {
    required String deliveryType,
    int rewardDiscountCents = 0,
    int freeDeliveryThresholdCents = 2000,
  }) {
    final subtotal = items.fold<int>(
      0,
      (sum, item) {
        final unitPrice =
            item.product.salePriceCents ?? item.product.priceCents ?? 0;
        return sum + (unitPrice * item.qty);
      },
    );

    final eligibleSubtotal = subtotal;

    final unlockedFreeDelivery = deliveryType == 'home_delivery' &&
        subtotal >= freeDeliveryThresholdCents;

    final deliveryFee =
        deliveryType == 'home_delivery' ? (unlockedFreeDelivery ? 0 : 250) : 0;

    final safeRewardDiscount = rewardDiscountCents.clamp(0, eligibleSubtotal);
    final total =
        (subtotal + deliveryFee - safeRewardDiscount).clamp(0, 1 << 31);

    return CartPricing(
      subtotalCents: subtotal,
      eligibleSubtotalCents: eligibleSubtotal,
      deliveryFeeCents: deliveryFee,
      rewardDiscountCents: safeRewardDiscount,
      totalCents: total,
      freeDeliveryThresholdCents: freeDeliveryThresholdCents,
      unlockedFreeDelivery: unlockedFreeDelivery,
    );
  }
}
