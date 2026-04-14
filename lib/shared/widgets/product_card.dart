import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:western_malabar/features/cart/widgets/add_to_cart_control.dart';
import 'package:western_malabar/features/catalog/models/product_model.dart';
import 'package:western_malabar/shared/utils/haptic.dart';
import 'package:western_malabar/shared/widgets/star_rating_badge.dart';

const _wmCardBg = Colors.white;
const _wmCardBorder = Color(0xFFE5E7EB);
const _wmCardText = Color(0xFF111827);
const _wmCardSoftText = Color(0xFF6B7280);
const _wmCardMutedText = Color(0xFF9CA3AF);
const _wmCardSurface = Color(0xFFF8FAFC);
const _wmCardSurfaceAlt = Color(0xFFF3F4F6);

const _wmCardPrimary = Color(0xFF2A2F3A);
const _wmCardPrimaryDark = Color(0xFF171A20);
const _wmCardSuccess = Color(0xFF15803D);
const _wmCardDeal = Color(0xFFF59E0B);
const _wmCardDanger = Color(0xFFDC2626);

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

  int get _displayPriceCents {
    final sale = p.salePriceCents;
    if (sale != null && sale > 0) return sale;
    return p.priceCents ?? 0;
  }

  int get _basePriceCents => p.priceCents ?? 0;

  String _money(int cents) => '£${(cents / 100).toStringAsFixed(2)}';

  bool get _showMetaPills => p.isWeeklyDeal == true || p.isFrozen == true;

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
    final brand = (p.brandName ?? '').trim();
    final hasRating = parent.showRating && (p.ratingCount ?? 0) > 0;

    return Material(
      color: _wmCardBg,
      borderRadius: BorderRadius.circular(18),
      elevation: parent.showShadow ? 0.5 : 0,
      shadowColor: const Color(0x0A000000),
      child: InkWell(
        onTap: parent.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _wmCardBorder,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProductImage(
                imageUrl: p.image,
                size: 84,
                borderRadius: 14,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 98,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (parent.showBrand && brand.isNotEmpty) ...[
                        Text(
                          brand,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _wmCardSoftText,
                            height: 1.05,
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
                          color: _wmCardText,
                        ),
                      ),
                      if (parent._showMetaPills) ...[
                        const SizedBox(height: 6),
                        _MetaPillRow(product: p),
                      ],
                      if (hasRating) ...[
                        const SizedBox(height: 6),
                        StarRatingBadge(
                          avgRating: p.avgRating,
                          ratingCount: p.ratingCount,
                          size: 12,
                        ),
                      ],
                      const Spacer(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 36,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: _PriceBlock(
                                  displayPrice:
                                      parent._money(parent._displayPriceCents),
                                  originalPrice: parent._hasDiscount
                                      ? parent._money(parent._basePriceCents)
                                      : null,
                                  dense: true,
                                ),
                              ),
                            ),
                          ),
                          if (parent.showAddButton) ...[
                            const SizedBox(width: 8),
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

class _GridProductCard extends StatelessWidget {
  final ProductCard parent;

  const _GridProductCard({
    required this.parent,
  });

  @override
  Widget build(BuildContext context) {
    final p = parent.p;
    final brand = (p.brandName ?? '').trim();
    final hasRating = parent.showRating && (p.ratingCount ?? 0) > 0;

    return RepaintBoundary(
      child: Material(
        color: _wmCardBg,
        borderRadius: BorderRadius.circular(18),
        elevation: parent.showShadow ? 0.35 : 0,
        shadowColor: const Color(0x08000000),
        child: InkWell(
          onTap: parent.onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: parent.width ?? 182,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _wmCardBorder,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const _ImageSurface(),
                      _ProductImage(
                        imageUrl: p.image,
                        width: double.infinity,
                        height: 114,
                        borderRadius: 14,
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (parent.showBrand && brand.isNotEmpty) ...[
                          Text(
                            brand,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10.8,
                              fontWeight: FontWeight.w700,
                              color: _wmCardSoftText,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ] else ...[
                          const SizedBox(height: 2),
                        ],
                        Text(
                          p.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.7,
                            height: 1.18,
                            color: _wmCardText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: parent._showMetaPills ? 22 : 0,
                          child: parent._showMetaPills
                              ? Align(
                                  alignment: Alignment.centerLeft,
                                  child: _MetaPillRow(product: p),
                                )
                              : const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 17,
                          child: hasRating
                              ? StarRatingBadge(
                                  avgRating: p.avgRating,
                                  ratingCount: p.ratingCount,
                                  size: 11.3,
                                )
                              : const SizedBox.shrink(),
                        ),
                        const Spacer(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              fit: FlexFit.tight,
                              child: SizedBox(
                                height: 34,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: _PriceBlock(
                                    displayPrice: parent
                                        ._money(parent._displayPriceCents),
                                    originalPrice: parent._hasDiscount
                                        ? parent._money(parent._basePriceCents)
                                        : null,
                                    dense: false,
                                  ),
                                ),
                              ),
                            ),
                            if (parent.showAddButton) ...[
                              const SizedBox(width: 6),
                              _GridAddButton(
                                product: p,
                                onAdded: () {
                                  Haptic.heavy(context);
                                  parent.onAdd();
                                },
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GridAddButton extends StatelessWidget {
  const _GridAddButton({
    required this.product,
    required this.onAdded,
  });

  final ProductModel product;
  final VoidCallback onAdded;

  @override
  Widget build(BuildContext context) {
    return AddToCartControl(
      product: product,
      compact: false,
      onAdded: onAdded,
    );
  }
}

class _ImageSurface extends StatelessWidget {
  const _ImageSurface();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _wmCardSurface,
          borderRadius: BorderRadius.circular(14),
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
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: resolvedWidth,
        height: resolvedHeight,
        child: hasImage
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 100),
                fadeOutDuration: Duration.zero,
                memCacheWidth: resolvedWidth.isFinite
                    ? (resolvedWidth * 2.0).round()
                    : null,
                placeholder: (_, __) => const _ProductImagePlaceholder(),
                errorWidget: (_, __, ___) => const _ProductImageFallback(),
              )
            : const _ProductImageFallback(),
      ),
    );
  }
}

class _ProductImagePlaceholder extends StatelessWidget {
  const _ProductImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _wmCardSurface,
      alignment: Alignment.center,
      child: const SizedBox(
        width: 15,
        height: 15,
        child: CircularProgressIndicator(
          strokeWidth: 1.7,
          color: _wmCardPrimary,
        ),
      ),
    );
  }
}

class _ProductImageFallback extends StatelessWidget {
  const _ProductImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _wmCardSurface,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        color: _wmCardMutedText,
        size: 25,
      ),
    );
  }
}

class _MetaPillRow extends StatelessWidget {
  final ProductModel product;

  const _MetaPillRow({
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final pills = <Widget>[
      if (product.isWeeklyDeal == true)
        _MetaPill(
          label: product.dealBadgeText?.trim().isNotEmpty == true
              ? product.dealBadgeText!
              : 'Deal',
          backgroundColor: const Color(0xFFFFF7ED),
          textColor: _wmCardDeal,
        ),
      if (product.isFrozen == true)
        const _MetaPill(
          label: 'Frozen',
          backgroundColor: Color(0xFFF3F4F6),
          textColor: _wmCardPrimary,
        ),
    ];

    if (pills.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < pills.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          pills[i],
        ],
      ],
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.label,
    this.backgroundColor = const Color(0xFFF3F4F6),
    this.textColor = _wmCardPrimary,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 8),
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
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: textColor,
          height: 1.0,
        ),
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
      fontSize: dense ? 15 : 15.8,
      color: _wmCardSuccess,
      letterSpacing: -0.22,
      height: 1.0,
    );

    final oldPriceStyle = TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: dense ? 11.3 : 11.8,
      color: const Color(0xFF7E7E7E),
      decoration: TextDecoration.lineThrough,
      height: 1.0,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          displayPrice,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: priceStyle,
        ),
        if (originalPrice != null) ...[
          const SizedBox(height: 3),
          Text(
            originalPrice!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: oldPriceStyle,
          ),
        ],
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
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: _wmCardDanger,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '$pct% OFF',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.12,
          height: 1.0,
        ),
      ),
    );
  }
}
