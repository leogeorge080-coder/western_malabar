import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:western_malabar/models/product_model.dart';
import 'package:western_malabar/theme.dart';
import 'package:western_malabar/utils/haptic.dart';
import 'package:western_malabar/widgets/cart/add_to_cart_control.dart';
import 'package:western_malabar/widgets/star_rating_badge.dart';

class ProductCard extends StatelessWidget {
  final ProductModel p;
  final VoidCallback onAdd;
  final VoidCallback? onTap;
  final bool compact;
  final double? width;
  final bool showShadow;
  final bool showBrand;
  final bool showRating;
  final bool showAddButton;

  const ProductCard({
    super.key,
    required this.p,
    required this.onAdd,
    this.onTap,
    this.compact = false,
    this.width,
    this.showShadow = true,
    this.showBrand = true,
    this.showRating = true,
    this.showAddButton = true,
  });

  bool get _hasDiscount {
    final price = p.priceCents ?? 0;
    final sale = p.salePriceCents;
    return sale != null && sale > 0 && sale < price;
  }

  int get _displayPriceCents => p.salePriceCents ?? p.priceCents ?? 0;

  int get _basePriceCents => p.priceCents ?? 0;

  String _money(int cents) => '£${(cents / 100).toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return compact
        ? _CompactProductCard(parent: this)
        : _GridProductCard(parent: this);
  }
}

class _CompactProductCard extends StatelessWidget {
  final ProductCard parent;

  const _CompactProductCard({
    required this.parent,
  });

  @override
  Widget build(BuildContext context) {
    final p = parent.p;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: parent.showShadow ? 1.5 : 0,
      shadowColor: const Color(0x22000000),
      child: InkWell(
        onTap: parent.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFEFE8F6),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProductImage(
                imageUrl: p.image,
                size: 74,
                borderRadius: 14,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (parent.showBrand &&
                        (p.brandName ?? '').trim().isNotEmpty) ...[
                      Text(
                        p.brandName!,
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
                      p.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        height: 1.2,
                        color: Colors.black87,
                      ),
                    ),
                    if (parent.showRating && (p.ratingCount ?? 0) > 0) ...[
                      const SizedBox(height: 6),
                      StarRatingBadge(
                        avgRating: p.avgRating,
                        ratingCount: p.ratingCount,
                        size: 12,
                      ),
                    ],
                    const SizedBox(height: 8),
                    _PriceBlock(
                      displayPrice: parent._money(parent._displayPriceCents),
                      originalPrice: parent._hasDiscount
                          ? parent._money(parent._basePriceCents)
                          : null,
                      dense: true,
                    ),
                  ],
                ),
              ),
              if (parent.showAddButton) ...[
                const SizedBox(width: 10),
                AddToCartControl(
                  product: p,
                  compact: true,
                  onAdded: () {
                    Haptic.heavy(context);
                    parent.onAdd();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GridProductCard extends StatelessWidget {
  final ProductCard parent;

  const _GridProductCard({
    required this.parent,
  });

  @override
  Widget build(BuildContext context) {
    final p = parent.p;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: parent.showShadow ? 2 : 0,
      shadowColor: const Color(0x22000000),
      child: InkWell(
        onTap: parent.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: parent.width ?? 182,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFEFE8F6),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    _ProductImage(
                      imageUrl: p.image,
                      size: null,
                      height: 108,
                      width: double.infinity,
                      borderRadius: 15,
                    ),
                    if (parent._hasDiscount)
                      Positioned(
                        left: 8,
                        top: 8,
                        child: _DiscountBadge(
                          originalPrice: parent._basePriceCents,
                          salePrice: parent._displayPriceCents,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                if (parent.showBrand && (p.brandName ?? '').trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      p.brandName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                Text(
                  p.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    height: 1.2,
                    color: Colors.black87,
                  ),
                ),
                if (parent.showRating && (p.ratingCount ?? 0) > 0) ...[
                  const SizedBox(height: 6),
                  StarRatingBadge(
                    avgRating: p.avgRating,
                    ratingCount: p.ratingCount,
                    size: 12,
                  ),
                ],
                const SizedBox(height: 8),
                _PriceBlock(
                  displayPrice: parent._money(parent._displayPriceCents),
                  originalPrice: parent._hasDiscount
                      ? parent._money(parent._basePriceCents)
                      : null,
                ),
                const Spacer(),
                if (parent.showAddButton)
                  Align(
                    alignment: Alignment.centerRight,
                    child: AddToCartControl(
                      product: p,
                      onAdded: () {
                        Haptic.heavy(context);
                        parent.onAdd();
                      },
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

class _ProductImage extends StatelessWidget {
  final String? imageUrl;
  final double? size;
  final double? width;
  final double? height;
  final double borderRadius;

  const _ProductImage({
    required this.imageUrl,
    required this.borderRadius,
    this.size,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedWidth = size ?? width ?? 80;
    final resolvedHeight = size ?? height ?? 80;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: resolvedWidth,
        height: resolvedHeight,
        color: const Color(0xFFF6F3FA),
        child: (imageUrl == null || imageUrl!.trim().isEmpty)
            ? const _ProductImageFallback()
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
                errorWidget: (_, __, ___) => const _ProductImageFallback(),
              ),
      ),
    );
  }
}

class _ProductImageFallback extends StatelessWidget {
  const _ProductImageFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.image_outlined,
        color: Colors.black26,
        size: 28,
      ),
    );
  }
}

class _PriceBlock extends StatelessWidget {
  final String displayPrice;
  final String? originalPrice;
  final bool dense;

  const _PriceBlock({
    required this.displayPrice,
    this.originalPrice,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final priceStyle = TextStyle(
      fontWeight: FontWeight.w900,
      fontSize: dense ? 15 : 16,
      color: WMTheme.royalPurple,
      letterSpacing: -0.1,
    );

    final oldPriceStyle = TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: dense ? 12 : 12.5,
      color: Colors.black45,
      decoration: TextDecoration.lineThrough,
    );

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 2,
      children: [
        Text(displayPrice, style: priceStyle),
        if (originalPrice != null) Text(originalPrice!, style: oldPriceStyle),
      ],
    );
  }
}

class _DiscountBadge extends StatelessWidget {
  final int originalPrice;
  final int salePrice;

  const _DiscountBadge({
    required this.originalPrice,
    required this.salePrice,
  });

  @override
  Widget build(BuildContext context) {
    if (originalPrice <= 0 || salePrice <= 0 || salePrice >= originalPrice) {
      return const SizedBox.shrink();
    }

    final pct = (((originalPrice - salePrice) / originalPrice) * 100).round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: WMTheme.royalPurple,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$pct% OFF',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
