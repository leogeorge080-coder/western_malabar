import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:western_malabar/features/cart/providers/cart_provider.dart';
import 'package:western_malabar/features/catalog/models/product_model.dart';
import 'package:western_malabar/shared/utils/haptic.dart';

class SearchAdvancedResultTile extends ConsumerStatefulWidget {
  const SearchAdvancedResultTile({
    super.key,
    required this.product,
    this.onTap,
    this.onAdded,
  });

  final ProductModel product;
  final VoidCallback? onTap;
  final void Function(String productName, GlobalKey imageKey)? onAdded;

  @override
  ConsumerState<SearchAdvancedResultTile> createState() =>
      _SearchAdvancedResultTileState();
}

class _SearchAdvancedResultTileState
    extends ConsumerState<SearchAdvancedResultTile> {
  final GlobalKey _imageKey = GlobalKey();

  bool get _hasDiscount {
    final base = widget.product.priceCents ?? 0;
    final sale = widget.product.salePriceCents;
    return sale != null && sale > 0 && base > 0 && sale < base;
  }

  int get _displayPriceCents =>
      widget.product.salePriceCents ?? widget.product.priceCents ?? 0;

  int get _basePriceCents => widget.product.priceCents ?? 0;

  int get _savingCents =>
      _hasDiscount ? (_basePriceCents - _displayPriceCents) : 0;

  String _money(int cents) => '\u00A3${(cents / 100).toStringAsFixed(2)}';

  String? get _categoryLabel {
    final value = (widget.product.categoryName ?? '').trim();
    return value.isEmpty ? null : value;
  }

  String? get _stockLabel => widget.product.stockStatusLabel;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final brand = (product.brandName ?? '').trim();
    final title = product.name.trim();
    final avgRating = product.avgRating ?? 0;
    final ratingCount = product.ratingCount ?? 0;
    final hasRating = ratingCount > 0 && avgRating > 0;
    final isDeal = product.isWeeklyDeal == true;
    final isFrozen = product.isFrozen == true;
    final stockLabel = _stockLabel;
    final categoryLabel = _categoryLabel;
    final discountPercent = product.discountPercent;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE6E7EB)),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 8,
                  offset: Offset(0, 3))
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AmazonTileImage(key: _imageKey, imageUrl: product.image),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (brand.isNotEmpty)
                          _AmazonMetaPill(
                            label: brand,
                            fg: const Color(0xFF475569),
                            bg: const Color(0xFFF8FAFC),
                          ),
                        if (categoryLabel != null)
                          _AmazonMetaPill(
                            label: categoryLabel,
                            fg: const Color(0xFF6B7280),
                            bg: const Color(0xFFF3F4F6),
                          ),
                      ],
                    ),
                    if (brand.isNotEmpty || categoryLabel != null)
                      const SizedBox(height: 6),
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
                    _AmazonSupportLine(
                      stockLabel: stockLabel,
                      hasRating: hasRating,
                      avgRating: avgRating,
                      ratingCount: ratingCount,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (isDeal)
                          _AmazonMetaPill(
                            label:
                                (product.dealBadgeText ?? '').trim().isNotEmpty
                                    ? product.dealBadgeText!.trim()
                                    : 'Weekly Deal',
                            fg: const Color(0xFF8A4B00),
                            bg: const Color(0xFFFFF1CC),
                          ),
                        if (discountPercent != null)
                          _AmazonMetaPill(
                            label: '$discountPercent% off',
                            fg: const Color(0xFF166534),
                            bg: const Color(0xFFDCFCE7),
                          ),
                        if (isFrozen)
                          const _AmazonMetaPill(
                            label: 'Frozen',
                            fg: Color(0xFF374151),
                            bg: Color(0xFFF3F4F6),
                          ),
                      ],
                    ),
                    if (isDeal || isFrozen || discountPercent != null)
                      const SizedBox(height: 8),
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
                            stockLabel: stockLabel,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _AmazonAddButton(
                          product: product,
                          onAdded: () =>
                              widget.onAdded?.call(product.name, _imageKey),
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
  const _AmazonTileImage({super.key, required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 92,
        height: 92,
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

class _AmazonSupportLine extends StatelessWidget {
  const _AmazonSupportLine({
    required this.stockLabel,
    required this.hasRating,
    required this.avgRating,
    required this.ratingCount,
  });

  final String? stockLabel;
  final bool hasRating;
  final double avgRating;
  final int ratingCount;

  @override
  Widget build(BuildContext context) {
    final stockColor = stockLabel == 'Out of stock'
        ? const Color(0xFFB91C1C)
        : (stockLabel?.startsWith('Only ') ?? false)
            ? const Color(0xFFB45309)
            : const Color(0xFF15803D);

    return Row(
      children: [
        if (stockLabel != null) ...[
          Icon(Icons.circle, size: 8, color: stockColor),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              stockLabel!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: stockColor,
                height: 1.0,
              ),
            ),
          ),
        ],
        if (stockLabel != null && hasRating) ...[
          const SizedBox(width: 8),
          const Text('|',
              style: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 12,
                  fontWeight: FontWeight.w900)),
          const SizedBox(width: 8),
        ],
        if (hasRating)
          Expanded(
            child: _AmazonRatingLine(
              avgRating: avgRating,
              ratingCount: ratingCount,
            ),
          ),
      ],
    );
  }
}

class _AmazonMetaPill extends StatelessWidget {
  const _AmazonMetaPill(
      {required this.label, required this.fg, required this.bg});

  final String label;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: fg,
          height: 1.0,
        ),
      ),
    );
  }
}

class _AmazonPriceBlock extends StatelessWidget {
  const _AmazonPriceBlock({
    required this.displayPrice,
    this.originalPrice,
    this.savingText,
    this.stockLabel,
  });

  final String displayPrice;
  final String? originalPrice;
  final String? savingText;
  final String? stockLabel;

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
        if (savingText == null && stockLabel == 'Out of stock') ...[
          const SizedBox(height: 3),
          const Text(
            'Check similar items',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280),
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
    final isAtStockLimit = !product.canAddToCartQuantity(qty);

    if (!product.inStock) {
      return SizedBox(
        height: 38,
        child: OutlinedButton(
          onPressed: null,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF9CA3AF),
            side: const BorderSide(color: Color(0xFFE5E7EB)),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            minimumSize: const Size(98, 38),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          child: const Text(
            'Sold out',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
        ),
      );
    }

    if (qty == 0) {
      return SizedBox(
        height: 38,
        child: ElevatedButton(
          onPressed: () {
            final added = ref.read(cartProvider.notifier).add(product);
            if (!added) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: Text(product.stockStatusLabel ?? 'No more stock available'),
                ),
              );
              return;
            }
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
            disabled: isAtStockLimit,
            onTap: () {
              final added = ref.read(cartProvider.notifier).inc(product);
              if (!added) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: Text(product.stockStatusLabel ?? 'No more stock available'),
                  ),
                );
                return;
              }
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
    this.disabled = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 38,
      child: IconButton(
        onPressed: disabled ? null : onTap,
        padding: EdgeInsets.zero,
        splashRadius: 18,
        icon: Icon(
          icon,
          size: 18,
          color: disabled ? const Color(0x66FFFFFF) : Colors.white,
        ),
      ),
    );
  }
}
