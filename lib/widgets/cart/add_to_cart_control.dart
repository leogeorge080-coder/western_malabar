import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:western_malabar/models/product_model.dart';
import 'package:western_malabar/state/cart_provider.dart';

class AddToCartControl extends ConsumerWidget {
  const AddToCartControl({
    super.key,
    required this.product,
    this.onAdded,
    this.compact = false,
  });

  final ProductModel product;
  final VoidCallback? onAdded;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const purple = Color(0xFF5A2D82);

    final cart = ref.watch(cartProvider);
    final item = cart.where((e) => e.product.id == product.id).firstOrNull;
    final qty = item?.qty ?? 0;

    if (qty == 0) {
      return SizedBox(
        height: compact ? 42 : 34,
        width: compact ? 42 : null,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: purple,
            foregroundColor: Colors.white,
            padding: compact
                ? EdgeInsets.zero
                : const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            ref.read(cartProvider.notifier).add(product);
            onAdded?.call();
          },
          child: compact
              ? const Icon(Icons.add_shopping_cart_outlined, size: 18)
              : const Text(
                  'Add',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
        ),
      );
    }

    return Container(
      height: compact ? 42 : 34,
      decoration: BoxDecoration(
        color: purple,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: const Icon(Icons.remove, size: 18, color: Colors.white),
            onPressed: () {
              ref.read(cartProvider.notifier).dec(product);
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '$qty',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: const Icon(Icons.add, size: 18, color: Colors.white),
            onPressed: () {
              ref.read(cartProvider.notifier).inc(product);
              onAdded?.call();
            },
          ),
        ],
      ),
    );
  }
}
