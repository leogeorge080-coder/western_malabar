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

const _wmCardPrimary = Color(0xFF2A2F3A);
const _wmCardSuccess = Color(0xFF15803D);
const _wmCardDeal = Color(0xFFF59E0B);
const _wmCardDanger = Color(0xFFDC2626);
const _wmCardGold = Color(0xFFD97706);

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

  int get _savingCents {
    if (!_hasDiscount) return 0;
    return _basePriceCents - _displayPriceCents;
  }

  String _money(int cents) => '£${(cents / 100).toStringAsFixed(2)}';

  bool get _showMetaPills => p.isWeeklyDeal == true || p.isFrozen == true;

  String? get _trustLabel {
    final avg = p.avgRating ?? 0;
    final count = p.ratingCount ?? 0;

    if (p.isWeeklyDeal == true) return 'Worth adding this week';
    if (avg >= 4.6 && count >= 8) return 'Customers love this';
    if (count >= 12) return 'Popular in baskets';
    if (count > 0) return 'Getting noticed';
    return null;
  }

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
      borderRadius: BorderRadius.circular(20),
      elevation: parent.showShadow ? 0.5 : 0,
      shadowColor: const Color(0x0A000000),
      child: InkWell(
        onTap: parent.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _wmCardBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  _ProductImage(
                    imageUrl: p.image,
                    size: 92,
                    borderRadius: 16,
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
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 100,
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
                          fontSize: 14.4,
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
                      if (parent._trustLabel != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          parent._trustLabel!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _wmCardMutedText,
                            height: 1.05,
                          ),
                        ),
                      ],
                      const Spacer(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: _PriceBlock(
                              displayPrice:
                                  parent._money(parent._displayPriceCents),
                              originalPrice: parent._hasDiscount
                                  ? parent._money(parent._basePriceCents)
                                  : null,
                              savingText: parent._hasDiscount
                                  ? 'Save ${parent._money(parent._savingCents)}'
                                  : null,
                              dense: true,
                            ),
                          ),
                          if (parent.showAddButton) ...[
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 34,
                              child: AddToCartControl(
                                product: p,
                                compact: true,
                                onAdded: () {
                                  Haptic.heavy(context);
                                  parent.onAdd();
                                },
                              ),
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

  static const double _imageHeight = 108;
  static const double _metaRowHeight = 22;
  static const double _ratingRowHeight = 16;
  static const double _trustRowHeight = 14;
  static const double _priceAreaMinHeight = 54;
  static const double _addButtonHeight = 36;

  @override
  Widget build(BuildContext context) {
    final p = parent.p;
    final brand = (p.brandName ?? '').trim();
    final hasRating = parent.showRating && (p.ratingCount ?? 0) > 0;

    return RepaintBoundary(
      child: Material(
        color: _wmCardBg,
        borderRadius: BorderRadius.circular(20),
        elevation: parent.showShadow ? 0.35 : 0,
        shadowColor: const Color(0x08000000),
        child: InkWell(
          onTap: parent.onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: parent.width ?? 182,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _wmCardBorder),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      SizedBox(
                        height: _imageHeight,
                        width: double.infinity,
                        child: const _ImageSurface(),
                      ),
                      _ProductImage(
                        imageUrl: p.image,
                        width: double.infinity,
                        height: _imageHeight,
                        borderRadius: 16,
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
                        if (parent.showBrand && brand.isNotEmpty)
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
                          )
                        else
                          const SizedBox(height: 12),
                        const SizedBox(height: 4),
                        Text(
                          p.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14.2,
                            height: 1.16,
                            color: _wmCardText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: _metaRowHeight,
                          child: parent._showMetaPills
                              ? Align(
                                  alignment: Alignment.centerLeft,
                                  child: _MetaPillRow(product: p),
                                )
                              : const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: _ratingRowHeight,
                          child: hasRating
                              ? StarRatingBadge(
                                  avgRating: p.avgRating,
                                  ratingCount: p.ratingCount,
                                  size: 11.2,
                                )
                              : const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: _trustRowHeight,
                          child: parent._trustLabel != null
                              ? Text(
                                  parent._trustLabel!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10.8,
                                    fontWeight: FontWeight.w700,
                                    color: _wmCardMutedText,
                                    height: 1.0,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        const Spacer(),
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                              minHeight: _priceAreaMinHeight),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: _PriceBlock(
                                  displayPrice:
                                      parent._money(parent._displayPriceCents),
                                  originalPrice: parent._hasDiscount
                                      ? parent._money(parent._basePriceCents)
                                      : null,
                                  savingText: parent._hasDiscount
                                      ? 'Save ${parent._money(parent._savingCents)}'
                                      : null,
                                  dense: false,
                                ),
                              ),
                              if (parent.showAddButton) ...[
                                const SizedBox(width: 8),
                                SizedBox(
                                  height: _addButtonHeight,
                                  child: AddToCartControl(
                                    product: p,
                                    compact: false,
                                    onAdded: () {
                                      Haptic.heavy(context);
                                      parent.onAdd();
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
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

class _ImageSurface extends StatelessWidget {
  const _ImageSurface();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _wmCardSurface,
        borderRadius: BorderRadius.circular(16),
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
          Flexible(child: pills[i]),
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
  final String? savingText;
  final bool dense;

  const _PriceBlock({
    required this.displayPrice,
    this.originalPrice,
    this.savingText,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final priceStyle = TextStyle(
      fontWeight: FontWeight.w900,
      fontSize: dense ? 15.4 : 16.0,
      color: _wmCardSuccess,
      letterSpacing: -0.22,
      height: 1.0,
    );

    final oldPriceStyle = TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: dense ? 11.2 : 11.6,
      color: const Color(0xFF7E7E7E),
      decoration: TextDecoration.lineThrough,
      height: 1.0,
    );

    final savingStyle = TextStyle(
      fontWeight: FontWeight.w800,
      fontSize: dense ? 10.8 : 11.2,
      color: _wmCardGold,
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
        if (savingText != null) ...[
          const SizedBox(height: 3),
          Text(
            savingText!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: savingStyle,
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
