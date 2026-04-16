import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:western_malabar/features/cart/providers/cart_provider.dart';
import 'package:western_malabar/features/catalog/models/product_model.dart';
import 'package:western_malabar/shared/utils/haptic.dart';

class SearchResultProductCard extends ConsumerWidget {
  const SearchResultProductCard({
    super.key,
    required this.product,
    this.onTap,
  });

  final ProductModel product;
  final VoidCallback? onTap;

  bool get _hasDiscount {
    final base = product.priceCents ?? 0;
    final sale = product.salePriceCents;
    return sale != null && sale > 0 && base > 0 && sale < base;
  }

  int get _displayPriceCents =>
      product.salePriceCents ?? product.priceCents ?? 0;

  int get _basePriceCents => product.priceCents ?? 0;

  String _money(int cents) => '£${(cents / 100).toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = (product.brandName ?? '').trim();
    final ratingCount = product.ratingCount ?? 0;
    final avgRating = product.avgRating ?? 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 116,
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFEAEAEA),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SearchCardImage(imageUrl: product.image),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (brand.isNotEmpty) ...[
                        Text(
                          brand,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF7B7B7B),
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF222222),
                          height: 1.18,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (ratingCount > 0)
                        _RatingLine(
                          avgRating: avgRating,
                          ratingCount: ratingCount,
                        )
                      else
                        const SizedBox(height: 16),
                      const Spacer(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: _SearchCardPrice(
                              priceText: _money(_displayPriceCents),
                              originalPriceText:
                                  _hasDiscount ? _money(_basePriceCents) : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _SearchCardAddControl(product: product),
                        ],
                      ),
                    ],
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

class _SearchCardImage extends StatelessWidget {
  const _SearchCardImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 88,
        height: 88,
        color: const Color(0xFFF7F4FA),
        child: (imageUrl == null || imageUrl!.trim().isEmpty)
            ? const Center(
                child: Icon(
                  Icons.shopping_bag_outlined,
                  color: Color(0xFFA8A1B0),
                  size: 28,
                ),
              )
            : CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (_, __, ___) => const Center(
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    color: Color(0xFFA8A1B0),
                    size: 28,
                  ),
                ),
              ),
      ),
    );
  }
}

class _RatingLine extends StatelessWidget {
  const _RatingLine({
    required this.avgRating,
    required this.ratingCount,
  });

  final double avgRating;
  final int ratingCount;

  @override
  Widget build(BuildContext context) {
    final fullStars = avgRating.floor().clamp(0, 5);

    return SizedBox(
      height: 16,
      child: Row(
        children: [
          ...List.generate(
            5,
            (i) => Icon(
              i < fullStars ? Icons.star_rounded : Icons.star_border_rounded,
              size: 13,
              color: const Color(0xFFF0C53E),
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '${avgRating.toStringAsFixed(1)} ($ratingCount)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6F6F6F),
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchCardPrice extends StatelessWidget {
  const _SearchCardPrice({
    required this.priceText,
    this.originalPriceText,
  });

  final String priceText;
  final String? originalPriceText;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Text(
              priceText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF15803D),
                height: 1.0,
                letterSpacing: -0.2,
              ),
            ),
          ),
          if (originalPriceText != null) ...[
            const SizedBox(width: 6),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 1),
                child: Text(
                  originalPriceText!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8B8B8B),
                    decoration: TextDecoration.lineThrough,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchCardAddControl extends ConsumerWidget {
  const _SearchCardAddControl({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const buttonColor = Color(0xFF2A2F3A);

    final cart = ref.watch(cartProvider);
    final item = cart.where((e) => e.product.id == product.id).firstOrNull;
    final qty = item?.qty ?? 0;

    if (qty == 0) {
      return SizedBox(
        width: 44,
        height: 44,
        child: ElevatedButton(
          onPressed: () {
            ref.read(cartProvider.notifier).add(product);
            Haptic.heavy(context);
          },
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: EdgeInsets.zero,
            backgroundColor: buttonColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(44, 44),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Icon(
            Icons.add_rounded,
            size: 22,
          ),
        ),
      );
    }

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: buttonColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperBtn(
            icon: Icons.remove_rounded,
            onTap: () {
              ref.read(cartProvider.notifier).dec(product);
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '$qty',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
          _StepperBtn(
            icon: Icons.add_rounded,
            onTap: () {
              ref.read(cartProvider.notifier).inc(product);
              Haptic.heavy(context);
            },
          ),
        ],
      ),
    );
  }
}

class _StepperBtn extends StatelessWidget {
  const _StepperBtn({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 40,
      child: IconButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 30, height: 40),
        splashRadius: 18,
        icon: Icon(
          icon,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}
