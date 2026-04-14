import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:western_malabar/features/auth/utils/require_checkout_login.dart';
import 'package:western_malabar/features/cart/services/cart_pricing.dart';
import 'package:western_malabar/features/checkout/screens/checkout_screen.dart';
import 'package:western_malabar/features/catalog/models/product_model.dart';
import 'package:western_malabar/features/catalog/services/product_service.dart';
import 'package:western_malabar/features/cart/providers/cart_provider.dart';
import 'package:western_malabar/shared/theme/theme.dart';
import 'package:western_malabar/shared/theme/wm_gradients.dart';
import 'package:western_malabar/shared/widgets/product_card.dart';
import 'package:western_malabar/shared/widgets/wm_product_image.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    final totalItems = cartItems.fold<int>(0, (sum, item) => sum + item.qty);

    final pricing = CartPricing.fromItems(
      cartItems,
      deliveryType: 'home_delivery',
    );

    final subtotalCents = pricing.subtotalCents;
    final unlockedFreeDelivery = pricing.unlockedFreeDelivery;
    final appliedDeliveryFeeCents = pricing.deliveryFeeCents;
    final totalCents = pricing.totalCents;
    final hasInvalidPricedItems = cartItems.any((e) {
      final cents = e.product.salePriceCents ?? e.product.priceCents ?? 0;
      return cents <= 0;
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: WMGradients.pageBackground,
        ),
        child: SafeArea(
          child: Column(
            children: [
              const _CartHeader(),
              Expanded(
                child: cartItems.isEmpty
                    ? const _EmptyCartView()
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        children: [
                          _CartTopSummaryCard(
                            totalItems: totalItems,
                            subtotalCents: subtotalCents,
                            deliveryFeeCents: appliedDeliveryFeeCents,
                            totalCents: totalCents,
                            unlockedFreeDelivery: unlockedFreeDelivery,
                            freeDeliveryThresholdCents:
                                pricing.freeDeliveryThresholdCents,
                            hasInvalidPricedItems: hasInvalidPricedItems,
                            onCheckout: () async {
                              final canContinue =
                                  await requireCheckoutLogin(context);
                              if (!canContinue) return;

                              if (!context.mounted) return;
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const CheckoutScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          ...List.generate(cartItems.length, (i) {
                            final item = cartItems[i];
                            final p = item.product;
                            final unitCents =
                                p.salePriceCents ?? p.priceCents ?? 0;
                            final lineTotalCents = unitCents * item.qty;

                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: i == cartItems.length - 1 ? 0 : 12,
                              ),
                              child: _CartItemCard(
                                name: p.name,
                                brandName: p.brandName,
                                imageUrl: p.image,
                                qty: item.qty,
                                unitCents: unitCents,
                                lineTotalCents: lineTotalCents,
                                onDec: () => cartNotifier.dec(p),
                                onInc: () => cartNotifier.inc(p),
                                onRemove: () => cartNotifier.remove(p),
                              ),
                            );
                          }),
                          const SizedBox(height: 16),
                          const _YouMayAlsoLikeSection(),
                          const SizedBox(height: 8),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartHeader extends StatelessWidget {
  const _CartHeader();

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
              'Your Cart',
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

class _EmptyCartView extends StatelessWidget {
  const _EmptyCartView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F0FB),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  size: 34,
                  color: WMTheme.royalPurple,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your cart is empty',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add your favourite Kerala groceries, snacks, and essentials to get started.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.maybePop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WMTheme.royalPurple,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Start Shopping',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
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
}

class FreeDeliveryProgressCard extends StatelessWidget {
  const FreeDeliveryProgressCard({
    super.key,
    required this.cartTotalCents,
    this.freeDeliveryThresholdCents = 2000,
  });

  final int cartTotalCents;
  final int freeDeliveryThresholdCents;

  bool get _unlocked => cartTotalCents >= freeDeliveryThresholdCents;

  int get _remainingCents {
    final remaining = freeDeliveryThresholdCents - cartTotalCents;
    return remaining > 0 ? remaining : 0;
  }

  double get _progress {
    if (freeDeliveryThresholdCents <= 0) return 0;
    return (cartTotalCents / freeDeliveryThresholdCents).clamp(0.0, 1.0);
  }

  String _money(int cents) => '£${(cents / 100).toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final bg = _unlocked ? const Color(0xFFF1FAF3) : const Color(0xFFFFF9EE);
    final border =
        _unlocked ? const Color(0xFFBFE3C7) : const Color(0xFFF4D98B);
    final accent = _unlocked ? const Color(0xFF2E9B57) : WMTheme.royalPurple;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _unlocked
                  ? Icons.check_circle_rounded
                  : Icons.local_shipping_rounded,
              color: accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _unlocked
                      ? 'You’ve unlocked free delivery'
                      : 'Add ${_money(_remainingCents)} more for free delivery',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _unlocked
                      ? 'Nice — your order now qualifies for free delivery.'
                      : 'Keep shopping to save on delivery charges.',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 10,
                    backgroundColor: Colors.white,
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      _money(cartTotalCents),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _money(freeDeliveryThresholdCents),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.black54,
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

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.name,
    required this.brandName,
    required this.imageUrl,
    required this.qty,
    required this.unitCents,
    required this.lineTotalCents,
    required this.onDec,
    required this.onInc,
    required this.onRemove,
  });

  final String name;
  final String? brandName;
  final String? imageUrl;
  final int qty;
  final int unitCents;
  final int lineTotalCents;
  final VoidCallback onDec;
  final VoidCallback onInc;
  final VoidCallback onRemove;

  String _money(int cents) => '£${(cents / 100).toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final hasBrand = (brandName ?? '').trim().isNotEmpty;
    final hasValidPrice = unitCents > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFEFE8F6),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CartItemImage(imageUrl: imageUrl),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasBrand) ...[
                  Text(
                    brandName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                    height: 1.2,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      hasValidPrice
                          ? '${_money(unitCents)} each'
                          : 'Price unavailable',
                      style: TextStyle(
                        color:
                            hasValidPrice ? Colors.black54 : Colors.redAccent,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Colors.black26,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      hasValidPrice
                          ? 'Line total ${_money(lineTotalCents)}'
                          : 'Unavailable',
                      style: TextStyle(
                        color: hasValidPrice
                            ? WMTheme.royalPurple
                            : Colors.redAccent,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _QtyStepper(
                      qty: qty,
                      onDec: onDec,
                      onInc: onInc,
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: onRemove,
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                      ),
                      label: const Text(
                        'Remove',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

class _CartItemImage extends StatelessWidget {
  const _CartItemImage({
    required this.imageUrl,
  });

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return WmProductImage(
      imageUrl: imageUrl,
      width: 86,
      height: 86,
      borderRadius: 14,
      placeholderIcon: Icons.image_outlined,
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.qty,
    required this.onDec,
    required this.onInc,
  });

  final int qty;
  final VoidCallback onDec;
  final VoidCallback onInc;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F2FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE6D9F6),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyIconButton(
            icon: Icons.remove,
            onTap: onDec,
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 34),
            alignment: Alignment.center,
            child: Text(
              '$qty',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
          ),
          _QtyIconButton(
            icon: Icons.add,
            onTap: onInc,
          ),
        ],
      ),
    );
  }
}

class _QtyIconButton extends StatelessWidget {
  const _QtyIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            size: 18,
            color: WMTheme.royalPurple,
          ),
        ),
      ),
    );
  }
}

class _CartTopSummaryCard extends StatelessWidget {
  const _CartTopSummaryCard({
    required this.totalItems,
    required this.subtotalCents,
    required this.deliveryFeeCents,
    required this.totalCents,
    required this.unlockedFreeDelivery,
    required this.freeDeliveryThresholdCents,
    required this.hasInvalidPricedItems,
    required this.onCheckout,
  });

  final int totalItems;
  final int subtotalCents;
  final int deliveryFeeCents;
  final int totalCents;
  final bool unlockedFreeDelivery;
  final int freeDeliveryThresholdCents;
  final bool hasInvalidPricedItems;
  final VoidCallback onCheckout;

  String _money(int cents) => '£${(cents / 100).toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subtotal ${_money(subtotalCents)}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$totalItems item${totalItems == 1 ? '' : 's'} in your cart',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 14),
          if (hasInvalidPricedItems) ...[
            const Text(
              'Some items in your basket need price correction before checkout',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: hasInvalidPricedItems ? null : onCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: WMTheme.royalPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Proceed to Checkout • ${_money(totalCents)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FreeDeliveryProgressCard(
            cartTotalCents: subtotalCents,
            freeDeliveryThresholdCents: freeDeliveryThresholdCents,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F6FC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEDE4F7)),
            ),
            child: Column(
              children: [
                _SummaryRow(
                  label: 'Items',
                  value: _money(subtotalCents),
                ),
                const SizedBox(height: 10),
                _SummaryRow(
                  label: 'Delivery',
                  value:
                      unlockedFreeDelivery ? 'FREE' : _money(deliveryFeeCents),
                  valueColor: unlockedFreeDelivery
                      ? const Color(0xFF2E9B57)
                      : Colors.black87,
                ),
                const Divider(height: 22),
                _SummaryRow(
                  label: 'Order Total',
                  value: _money(totalCents),
                  bold: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      fontSize: bold ? 16 : 14,
      fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
      color: bold ? Colors.black87 : Colors.black54,
    );

    final valueStyle = TextStyle(
      fontSize: bold ? 18 : 14,
      fontWeight: bold ? FontWeight.w900 : FontWeight.w800,
      color: valueColor ?? (bold ? WMTheme.royalPurple : Colors.black87),
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

class _YouMayAlsoLikeSection extends ConsumerStatefulWidget {
  const _YouMayAlsoLikeSection();

  @override
  ConsumerState<_YouMayAlsoLikeSection> createState() =>
      _YouMayAlsoLikeSectionState();
}

class _YouMayAlsoLikeSectionState
    extends ConsumerState<_YouMayAlsoLikeSection> {
  final _svc = ProductService();

  bool _loading = true;
  List<ProductModel> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final dto = await _svc.fetchTodaysPicks(limit: 12);
      if (!mounted) return;

      final cartIds = ref.read(cartProvider).map((e) => e.product.id).toSet();

      final items = dto
          .where((p) => !cartIds.contains(p.id))
          .map(
            (p) => ProductModel(
              id: p.id,
              name: p.name,
              brandName: p.brandName,
              image: p.firstImageUrl,
              priceCents: p.priceCents,
              salePriceCents:
                  p.variants.isEmpty ? null : p.variants.first.salePriceCents,
              avgRating: p.avgRating,
              ratingCount: p.ratingCount,
              categoryName: null,
              categorySlug: null,
              isFrozen: p.isFrozen,
              barcode: p.barcode,
              sellerId: p.sellerId,
              sellerBasePriceCents: p.sellerBasePriceCents,
            ),
          )
          .take(8)
          .toList();

      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You may also like',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: WMTheme.royalPurple,
              ),
            ),
            SizedBox(height: 14),
            SizedBox(
              height: 230,
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2.2),
              ),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'You may also like',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: WMTheme.royalPurple,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Popular picks to complete your order',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 248,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final p = _items[i];
                return ProductCard(
                  p: p,
                  width: 176,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Open "${p.name}"')),
                    );
                  },
                  onAdd: () {
                    ref.read(cartProvider.notifier).add(p);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${p.name} added to cart'),
                        duration: const Duration(milliseconds: 900),
                      ),
                    );
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
