import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:western_malabar/features/cart/services/cart_pricing.dart';
import 'package:western_malabar/shared/navigation/product_navigation.dart';
import 'package:western_malabar/features/checkout/screens/checkout_screen.dart';
import 'package:western_malabar/features/catalog/models/product_model.dart';
import 'package:western_malabar/features/catalog/services/product_service.dart';
import 'package:western_malabar/features/cart/providers/cart_provider.dart';
import 'package:western_malabar/features/search/screens/global_product_search_screen.dart';
import 'package:western_malabar/shared/widgets/product_card.dart';
import 'package:western_malabar/shared/widgets/wm_product_image.dart';

const _wmCartBg = Color(0xFFF7F7F7);
const _wmCartSurface = Colors.white;
const _wmCartBorder = Color(0xFFE5E7EB);

const _wmCartTextStrong = Color(0xFF111827);
const _wmCartTextSoft = Color(0xFF6B7280);
const _wmCartTextMuted = Color(0xFF9CA3AF);

const _wmCartPrimary = Color(0xFF2A2F3A);
const _wmCartPrimaryDark = Color(0xFF171A20);

const _wmCartSuccess = Color(0xFF15803D);
const _wmCartSuccessSoft = Color(0xFFECFDF5);

const _wmCartAmber = Color(0xFFF59E0B);
const _wmCartAmberSoft = Color(0xFFFFF7ED);

const _wmCartDanger = Color(0xFFDC2626);

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
      backgroundColor: _wmCartBg,
      body: SafeArea(
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
                              maxQty: p.maxCartQuantity,
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
          Container(
            decoration: BoxDecoration(
              color: _wmCartSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _wmCartBorder),
            ),
            child: IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _wmCartPrimary,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Your Cart',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: _wmCartTextStrong,
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
            color: _wmCartSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _wmCartBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C000000),
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
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  size: 34,
                  color: _wmCartPrimary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your cart is empty',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: _wmCartTextStrong,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add your favourite Kerala groceries, snacks, and essentials to get started.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _wmCartTextSoft,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const GlobalProductSearchScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _wmCartPrimary,
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

  String _displayMoney(int cents) => '£${(cents / 100).toStringAsFixed(2)}';
  String _money(int cents) => '£${(cents / 100).toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final bg = _unlocked ? _wmCartSuccessSoft : _wmCartAmberSoft;
    final border =
        _unlocked ? const Color(0xFFBBF7D0) : const Color(0xFFFED7AA);
    final accent = _unlocked ? _wmCartSuccess : _wmCartPrimary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
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
                      : 'Add ${_displayMoney(_remainingCents)} more for free delivery',
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
                    color: _wmCartTextSoft,
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
                      _displayMoney(cartTotalCents),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _wmCartTextStrong,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _displayMoney(freeDeliveryThresholdCents),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _wmCartTextSoft,
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
    required this.maxQty,
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
  final int? maxQty;
  final int unitCents;
  final int lineTotalCents;
  final VoidCallback onDec;
  final VoidCallback onInc;
  final VoidCallback onRemove;

  String _displayMoney(int cents) => '£${(cents / 100).toStringAsFixed(2)}';
  String _money(int cents) => '£${(cents / 100).toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final hasBrand = (brandName ?? '').trim().isNotEmpty;
    final hasValidPrice = unitCents > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _wmCartSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: _wmCartBorder,
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
                      color: _wmCartTextSoft,
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
                    color: _wmCartTextStrong,
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
                          ? '${_displayMoney(unitCents)} each'
                          : 'Price unavailable',
                      style: TextStyle(
                        color: hasValidPrice ? _wmCartTextSoft : _wmCartDanger,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Color(0xFFCBD5E1),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      hasValidPrice
                          ? _displayMoney(lineTotalCents)
                          : 'Unavailable',
                      style: TextStyle(
                        color: hasValidPrice ? _wmCartSuccess : _wmCartDanger,
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
                      maxQty: maxQty,
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
                        foregroundColor: _wmCartDanger,
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
    required this.maxQty,
    required this.onDec,
    required this.onInc,
  });

  final int qty;
  final int? maxQty;
  final VoidCallback onDec;
  final VoidCallback onInc;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _wmCartBorder,
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
                color: _wmCartTextStrong,
              ),
            ),
          ),
          _QtyIconButton(
            icon: Icons.add,
            onTap: onInc,
            disabled: maxQty != null && qty >= maxQty!,
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
    this.disabled = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            size: 18,
            color: disabled ? const Color(0xFF9CA3AF) : _wmCartPrimary,
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
  String _displayMoney(int cents) => '£${(cents / 100).toStringAsFixed(2)}';

  String _money(int cents) => '£${(cents / 100).toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final remainingForFreeDelivery =
        (freeDeliveryThresholdCents - subtotalCents).clamp(
      0,
      freeDeliveryThresholdCents,
    );
    final momentumLine = hasInvalidPricedItems
        ? 'Fix pricing issues before checkout.'
        : unlockedFreeDelivery
            ? 'Ready to place your order with free delivery.'
            : 'Add ${_displayMoney(remainingForFreeDelivery)} more for free delivery.';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _wmCartSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _wmCartBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color:
                  unlockedFreeDelivery ? _wmCartSuccessSoft : _wmCartAmberSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              unlockedFreeDelivery ? 'Ready to order' : 'Almost there',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                color: unlockedFreeDelivery ? _wmCartSuccess : _wmCartPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _displayMoney(subtotalCents),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: _wmCartTextStrong,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$totalItems item${totalItems == 1 ? '' : 's'} • $momentumLine',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _wmCartTextSoft,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          if (hasInvalidPricedItems) ...[
            const Text(
              'Some items need price correction before checkout.',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: _wmCartDanger,
              ),
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: hasInvalidPricedItems ? null : onCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: _wmCartPrimary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF9CA3AF),
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _wmCartBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryRow(
                    label: 'Items',
                    value: _displayMoney(subtotalCents),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryRow(
                    label: 'Delivery',
                    value: unlockedFreeDelivery
                        ? 'FREE'
                        : _displayMoney(deliveryFeeCents),
                    valueColor: unlockedFreeDelivery
                        ? _wmCartSuccess
                        : _wmCartTextStrong,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryRow(
                    label: 'Total',
                    value: _displayMoney(totalCents),
                    bold: true,
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
      fontSize: 12,
      fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
      color: bold ? _wmCartTextStrong : _wmCartTextSoft,
    );

    final valueStyle = TextStyle(
      fontSize: bold ? 17 : 13.5,
      fontWeight: bold ? FontWeight.w900 : FontWeight.w800,
      color: valueColor ?? (bold ? _wmCartPrimary : _wmCartTextStrong),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 6),
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
          color: _wmCartSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _wmCartBorder),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C000000),
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
                color: _wmCartTextStrong,
              ),
            ),
            SizedBox(height: 14),
            SizedBox(
              height: 230,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: _wmCartPrimary,
                ),
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
        color: _wmCartSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _wmCartBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
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
              color: _wmCartTextStrong,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Popular picks to complete your order',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: _wmCartTextSoft,
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
                    openProductDetail(
                      context,
                      productId: p.id,
                      initialProduct: p,
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
