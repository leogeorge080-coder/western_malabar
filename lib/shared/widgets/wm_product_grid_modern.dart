import 'package:flutter/material.dart';
import 'package:western_malabar/features/catalog/models/product_model.dart';
import 'package:western_malabar/features/cart/widgets/add_to_cart_control.dart';
import 'package:western_malabar/shared/widgets/wm_product_image.dart';

/// Minimal product type for this grid.
/// If you already have a model, just map to these fields when you pass [products].
class WmProduct {
  final String id;
  final String name;
  final String? brandName;
  final int priceCents; // e.g. 1299 for £12.99
  final int? salePriceCents;
  final String? imageUrl; // can be null -> shows placeholder
  final double? avgRating;
  final int? ratingCount;
  final String? categoryName;
  final String? categorySlug;
  final bool isFrozen;
  final String? barcode;
  final String? sellerId;
  final int? sellerBasePriceCents;

  const WmProduct({
    required this.id,
    required this.name,
    required this.priceCents,
    this.brandName,
    this.salePriceCents,
    this.imageUrl,
    this.avgRating,
    this.ratingCount,
    this.categoryName,
    this.categorySlug,
    this.isFrozen = false,
    this.barcode,
    this.sellerId,
    this.sellerBasePriceCents,
  });
}

/// Modern, bold 2-column grid.
/// Uses shared AddToCartControl so cart behavior stays identical all over the app.
class WMTodaysPicksGrid extends StatelessWidget {
  const WMTodaysPicksGrid({
    super.key,
    required this.products,
    this.title = "Today's Picks",
    this.onTap,
    this.crossAxisCount = 2,
  });

  final List<WmProduct> products;
  final String title;
  final void Function(WmProduct product)? onTap;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF5A2D82);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: purple,
          ),
        ),
        const SizedBox(height: 10),
        if (products.isEmpty)
          const Center(
            child: Text('No products available'),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            primary: false,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: .78,
            ),
            itemCount: products.length,
            itemBuilder: (context, i) => _ProductTile(
              product: products[i],
              onTap: onTap,
            ),
          ),
      ],
    );
  }
}

class _ProductTile extends StatefulWidget {
  const _ProductTile({
    required this.product,
    this.onTap,
  });

  final WmProduct product;
  final void Function(WmProduct product)? onTap;

  @override
  State<_ProductTile> createState() => _ProductTileState();
}

class _ProductTileState extends State<_ProductTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF5A2D82);
    final p = widget.product;

    final productModel = ProductModel(
      id: p.id,
      name: p.name,
      brandName: p.brandName,
      image: p.imageUrl,
      priceCents: p.priceCents,
      salePriceCents: p.salePriceCents,
      avgRating: p.avgRating,
      ratingCount: p.ratingCount,
      categoryName: p.categoryName,
      categorySlug: p.categorySlug,
      isFrozen: p.isFrozen,
      barcode: p.barcode,
      sellerId: p.sellerId,
      sellerBasePriceCents: p.sellerBasePriceCents,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => widget.onTap?.call(p),
        onHighlightChanged: (v) => setState(() => _pressed = v),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 140),
          scale: _pressed ? 0.98 : 1.0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _pressed
                    ? purple.withValues(alpha: 0.18)
                    : Colors.black.withValues(alpha: 0.05),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x15000000),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(18)),
                    child: SizedBox(
                      width: double.infinity,
                      child: WmProductImage(
                        imageUrl: p.imageUrl,
                        width: double.infinity,
                        height: 108,
                        borderRadius: 0,
                        placeholderIcon: Icons.image,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _gbp(p.priceCents),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: purple,
                              ),
                            ),
                          ),
                          AddToCartControl(product: productModel),
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
    );
  }
}

String _gbp(int cents) {
  final pounds = cents / 100.0;
  return '£${pounds.toStringAsFixed(2)}';
}
