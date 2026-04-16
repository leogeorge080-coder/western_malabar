import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:western_malabar/features/cart/providers/cart_provider.dart';
import 'package:western_malabar/features/catalog/models/product_model.dart';
import 'package:western_malabar/shared/utils/haptic.dart';

const _sgCardBg = Colors.white;
const _sgCardBorder = Color(0xFFE5E7EB);
const _sgCardSurface = Color(0xFFF8FAFC);

const _sgTextStrong = Color(0xFF111827);
const _sgTextSoft = Color(0xFF6B7280);
const _sgTextMuted = Color(0xFF9CA3AF);

const _sgPrimary = Color(0xFF2A2F3A);
const _sgSuccess = Color(0xFF15803D);
const _sgDeal = Color(0xFFF59E0B);
const _sgDanger = Color(0xFFDC2626);
const _sgGold = Color(0xFFD97706);

class SearchGridProductCard extends ConsumerWidget {
  const SearchGridProductCard({
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

  int get _savingCents =>
      _hasDiscount ? (_basePriceCents - _displayPriceCents) : 0;

  String _money(int cents) => '£${(cents / 100).toStringAsFixed(2)}';

  String? get _trustLabel {
    final avg = product.avgRating ?? 0;
    final count = product.ratingCount ?? 0;

    if (product.isWeeklyDeal == true) return 'Worth adding this week';
    if (avg >= 4.6 && count >= 8) return 'Customers love this';
    if (count >= 12) return 'Popular in baskets';
    if (count > 0) return 'Getting noticed';
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = (product.brandName ?? '').trim();
    final ratingCount = product.ratingCount ?? 0;
    final avgRating = product.avgRating ?? 0;
    final hasWeeklyDeal = product.isWeeklyDeal == true;
    final isFrozen = product.isFrozen == true;

    return RepaintBoundary(
      child: Material(
        color: _sgCardBg,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: _sgCardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _sgCardBorder),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    const _GridImageSurface(),
                    _GridProductImage(imageUrl: product.image),
                    if (_hasDiscount)
                      Positioned(
                        left: 10,
                        top: 10,
                        child: _GridDiscountBadge(
                          percentage: (((_basePriceCents - _displayPriceCents) /
                                      _basePriceCents) *
                                  100)
                              .round(),
                        ),
                      ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 16,
                          child: brand.isNotEmpty
                              ? Text(
                                  brand,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: _sgTextSoft,
                                    height: 1.0,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14.6,
                              fontWeight: FontWeight.w800,
                              color: _sgTextStrong,
                              height: 1.18,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 22,
                          child: Row(
                            children: [
                              if (hasWeeklyDeal)
                                Flexible(
                                  child: _TinyMetaPill(
                                    label: (product.dealBadgeText ?? '')
                                            .trim()
                                            .isNotEmpty
                                        ? product.dealBadgeText!.trim()
                                        : 'Weekly Deal',
                                    backgroundColor: const Color(0xFFFFF7ED),
                                    textColor: _sgDeal,
                                  ),
                                ),
                              if (hasWeeklyDeal && isFrozen)
                                const SizedBox(width: 6),
                              if (isFrozen)
                                const Flexible(
                                  child: _TinyMetaPill(
                                    label: 'Frozen',
                                    backgroundColor: Color(0xFFF3F4F6),
                                    textColor: _sgPrimary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 16,
                          child: ratingCount > 0
                              ? _GridRatingLine(
                                  avgRating: avgRating,
                                  ratingCount: ratingCount,
                                )
                              : const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 14,
                          child: _trustLabel != null
                              ? Text(
                                  _trustLabel!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10.8,
                                    fontWeight: FontWeight.w700,
                                    color: _sgTextMuted,
                                    height: 1.0,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: _GridPriceBlock(
                                priceText: _money(_displayPriceCents),
                                originalPriceText: _hasDiscount
                                    ? _money(_basePriceCents)
                                    : null,
                                savingText: _hasDiscount
                                    ? 'Save ${_money(_savingCents)}'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _GridAddControl(
                              product: product,
                              onAdded: onAdded,
                            ),
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
      ),
    );
  }
}

class _GridImageSurface extends StatelessWidget {
  const _GridImageSurface();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 128,
      decoration: const BoxDecoration(
        color: _sgCardSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }
}

class _GridProductImage extends StatelessWidget {
  const _GridProductImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: SizedBox(
        height: 128,
        width: double.infinity,
        child: hasImage
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 100),
                placeholder: (_, __) => const _GridImagePlaceholder(),
                errorWidget: (_, __, ___) => const _GridImageFallback(),
              )
            : const _GridImageFallback(),
      ),
    );
  }
}

class _GridImagePlaceholder extends StatelessWidget {
  const _GridImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _sgCardSurface,
      alignment: Alignment.center,
      child: const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 1.8,
          color: _sgPrimary,
        ),
      ),
    );
  }
}

class _GridImageFallback extends StatelessWidget {
  const _GridImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _sgCardSurface,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        size: 30,
        color: _sgTextMuted,
      ),
    );
  }
}

class _GridDiscountBadge extends StatelessWidget {
  const _GridDiscountBadge({required this.percentage});

  final int percentage;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: _sgDanger,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '$percentage% OFF',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.2,
          fontWeight: FontWeight.w900,
          height: 1.0,
          letterSpacing: 0.15,
        ),
      ),
    );
  }
}

class _TinyMetaPill extends StatelessWidget {
  const _TinyMetaPill({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10.2,
          fontWeight: FontWeight.w800,
          color: textColor,
          height: 1.0,
        ),
      ),
    );
  }
}

class _GridRatingLine extends StatelessWidget {
  const _GridRatingLine({
    required this.avgRating,
    required this.ratingCount,
  });

  final double avgRating;
  final int ratingCount;

  @override
  Widget build(BuildContext context) {
    final fullStars = avgRating.floor().clamp(0, 5);

    return Row(
      children: [
        ...List.generate(
          5,
          (i) => Icon(
            i < fullStars ? Icons.star_rounded : Icons.star_border_rounded,
            size: 12.5,
            color: _sgGold,
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '${avgRating.toStringAsFixed(1)} ($ratingCount)',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.2,
              fontWeight: FontWeight.w600,
              color: _sgTextSoft,
              height: 1.0,
            ),
          ),
        ),
      ],
    );
  }
}

class _GridPriceBlock extends StatelessWidget {
  const _GridPriceBlock({
    required this.priceText,
    this.originalPriceText,
    this.savingText,
  });

  final String priceText;
  final String? originalPriceText;
  final String? savingText;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          priceText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w900,
            color: _sgSuccess,
            height: 1.0,
            letterSpacing: -0.2,
          ),
        ),
        if (originalPriceText != null) ...[
          const SizedBox(height: 3),
          Text(
            originalPriceText!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.2,
              fontWeight: FontWeight.w700,
              color: _sgTextMuted,
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
              fontSize: 11.1,
              fontWeight: FontWeight.w800,
              color: _sgDeal,
              height: 1.0,
            ),
          ),
        ],
      ],
    );
  }
}

class _GridAddControl extends ConsumerWidget {
  const _GridAddControl({
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
        width: 78,
        height: 38,
        child: ElevatedButton(
          onPressed: () {
            ref.read(cartProvider.notifier).add(product);
            Haptic.heavy(context);
            onAdded?.call();
          },
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: _sgPrimary,
            foregroundColor: Colors.white,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
          child: const Text(
            'Add',
            style: TextStyle(
              fontSize: 13.2,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
    }

    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: _sgPrimary,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyBtn(
            icon: Icons.remove_rounded,
            onTap: () {
              ref.read(cartProvider.notifier).dec(product);
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '$qty',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
          ),
          _QtyBtn(
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

class _QtyBtn extends StatelessWidget {
  const _QtyBtn({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
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
