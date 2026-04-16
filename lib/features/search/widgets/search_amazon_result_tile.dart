import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:western_malabar/features/cart/providers/cart_provider.dart';
import 'package:western_malabar/features/catalog/models/product_model.dart';
import 'package:western_malabar/shared/utils/haptic.dart';

class SearchAmazonResultTile extends ConsumerWidget {
  const SearchAmazonResultTile({
    super.key,
    required this.product,
    this.onTap,
    this.onAdded,
  });

  final ProductModel product;
  final VoidCallback? onTap;
  final VoidCallback? onAdded;

  bool get _hasDiscount {
    final base = product.priceCents ?? 0;
    final sale = product.salePriceCents;
    return sale != null && sale > 0 && base > 0 && sale < base;
  }

  int get _displayPriceCents =>
      product.salePriceCents ?? product.priceCents ?? 0;

  int get _basePriceCents => product.priceCents ?? 0;

  int get _savingCents => _hasDiscount ? (_basePriceCents - _displayPriceCents) : 0;

  String _money(int cents) => '£${(cents / 100).toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = (product.brandName ?? '').trim();
    final title = product.name.trim();
    final avgRating = product.avgRating ?? 0;
    final ratingCount = product.ratingCount ?? 0;
    final hasRating = ratingCount > 0 && avgRating > 0;
    final isDeal = product.isWeeklyDeal == true;
    final isFrozen = product.isFrozen == true;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFE6E7EB),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AmazonTileImage(imageUrl: product.image),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (brand.isNotEmpty)
                      Text(
                        brand,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                          height: 1.15,
                        ),
                      ),
                    if (brand.isNotEmpty) const SizedBox(height: 3),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                        height: 1.22,
                        letterSpacing: -0.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (hasRating)
                      _AmazonRatingLine(
                        avgRating: avgRating,
                        ratingCount: ratingCount,
                      ),
                    if (hasRating) const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (isDeal)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1CC),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              (product.dealBadgeText ?? '').trim().isNotEmpty
                                  ? product.dealBadgeText!.trim()
                                  : 'Weekly Deal',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF8A4B00),
                                height: 1.0,
                              ),
                            ),
                          ),
                        if (isFrozen)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Frozen',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF374151),
                                height: 1.0,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (isDeal || isFrozen) const SizedBox(height: 7),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: _AmazonPriceBlock(
                            displayPrice: _money(_displayPriceCents),
                            originalPrice:
                                _hasDiscount ? _money(_basePriceCents) : null,
                            savingText: _hasDiscount
                                ? 'Save ${_money(_savingCents)}'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _AmazonAddButton(
                          product: product,
                          onAdded: onAdded,
                        ),
                      ],
                    ),
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

class _AmazonTileImage extends StatelessWidget {
  const _AmazonTileImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 104,
        height: 104,
        color: const Color(0xFFF7F7F8),
        child: hasImage
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                memCacheWidth: 300,
                fadeInDuration: const Duration(milliseconds: 90),
                placeholder: (_, __) => const Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 1.8),
                  ),
                ),
                errorWidget: (_, __, ___) => const _AmazonImageFallback(),
              )
            : const _AmazonImageFallback(),
      ),
    );
  }
}

class _AmazonImageFallback extends StatelessWidget {
  const _AmazonImageFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.shopping_bag_outlined,
        color: Color(0xFFA3A3A3),
        size: 28,
      ),
    );
  }
}

class _AmazonRatingLine extends StatelessWidget {
  const _AmazonRatingLine({
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
            (index) => Icon(
              index < fullStars
                  ? Icons.star_rounded
                  : Icons.star_border_rounded,
              size: 13,
              color: const Color(0xFFF59E0B),
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
                color: Color(0xFF6B7280),
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmazonPriceBlock extends StatelessWidget {
  const _AmazonPriceBlock({
    required this.displayPrice,
    this.originalPrice,
    this.savingText,
  });

  final String displayPrice;
  final String? originalPrice;
  final String? savingText;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          displayPrice,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w900,
            color: Color(0xFF111827),
            height: 1.0,
          ),
        ),
        if (originalPrice != null) ...[
          const SizedBox(height: 3),
          Text(
            originalPrice!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8B8B8B),
              decoration: TextDecoration.lineThrough,
              height: 1.0,
            ),
          ),
        ],
        if (savingText != null) ...[
          const SizedBox(height: 3),
          Text(
            savingText!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFFB45309),
              height: 1.0,
            ),
          ),
        ],
      ],
    );
  }
}

class _AmazonAddButton extends ConsumerWidget {
  const _AmazonAddButton({
    required this.product,
    this.onAdded,
  });

  final ProductModel product;
  final VoidCallback? onAdded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final item = cart.where((e) => e.product.id == product.id).firstOrNull;
    final qty = item?.qty ?? 0;

    if (qty == 0) {
      return SizedBox(
        height: 38,
        child: ElevatedButton(
          onPressed: () {
            ref.read(cartProvider.notifier).add(product);
            Haptic.heavy(context);
            onAdded?.call();
          },
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: const Color(0xFFFFD814),
            foregroundColor: const Color(0xFF111827),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            minimumSize: const Size(88, 38),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            side: const BorderSide(
              color: Color(0xFFF5C400),
            ),
          ),
          child: const Text(
            'Add',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
        ),
      );
    }

    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AmazonStepperBtn(
            icon: Icons.remove_rounded,
            onTap: () {
              ref.read(cartProvider.notifier).dec(product);
              Haptic.light(context);
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '$qty',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
            ),
          ),
          _AmazonStepperBtn(
            icon: Icons.add_rounded,
            onTap: () {
              ref.read(cartProvider.notifier).inc(product);
              Haptic.heavy(context);
              onAdded?.call();
            },
          ),
        ],
      ),
    );
  }
}

class _AmazonStepperBtn extends StatelessWidget {
  const _AmazonStepperBtn({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 38,
      child: IconButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        splashRadius: 18,
        icon: Icon(
          icon,
          size: 18,
          color: Colors.white,
        ),
      ),
    );
  }
}
