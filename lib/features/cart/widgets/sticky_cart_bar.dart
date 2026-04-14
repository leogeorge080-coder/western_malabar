import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:western_malabar/features/cart/providers/cart_provider.dart';
import 'package:western_malabar/features/cart/screens/cart_screen.dart';

const _wmStickyBg = Color(0xFF1F2329);
const _wmStickyBgSoft = Color(0xFF2A2F36);
const _wmStickySurface = Colors.white;
const _wmStickyTextStrong = Colors.white;
const _wmStickyTextSoft = Color(0xFFD5D9DF);

class StickyCartBar extends ConsumerWidget {
  const StickyCartBar({
    super.key,
    this.bottom = 16,
    this.left = 16,
    this.right = 16,
  });

  final double bottom;
  final double left;
  final double right;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final cartCount = cart.fold<int>(0, (sum, item) => sum + item.qty);

    if (cartCount == 0) {
      return const SizedBox.shrink();
    }

    int totalCents = 0;
    for (final e in cart) {
      final cents = e.product.salePriceCents ?? e.product.priceCents ?? 0;
      totalCents += cents * e.qty;
    }

    final totalText = '£${(totalCents / 100).toStringAsFixed(2)}';
    final itemText = cartCount == 1 ? '1 item' : '$cartCount items';

    return Positioned(
      left: left,
      right: right,
      bottom: bottom,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const CartScreen(),
              ),
            );
          },
          child: Ink(
            height: 62,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _wmStickyBg,
                  _wmStickyBgSoft,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$cartCount',
                    style: const TextStyle(
                      color: _wmStickyTextStrong,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$totalText • View basket',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _wmStickyTextStrong,
                          fontWeight: FontWeight.w800,
                          fontSize: 14.2,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        itemText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _wmStickyTextSoft,
                          fontWeight: FontWeight.w700,
                          fontSize: 11.8,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _wmStickySurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: _wmStickyBg,
                    size: 19,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
