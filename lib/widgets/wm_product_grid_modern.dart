import 'package:flutter/material.dart';
import 'package:western_malabar/models/product_model.dart';
import 'package:western_malabar/widgets/cart/add_to_cart_control.dart';

/// Minimal product type for this grid.
/// If you already have a model, just map to these fields when you pass [products].
class WmProduct {
  final String id;
  final String name;
  final int priceCents; // e.g. 1299 for £12.99
  final String? imageUrl; // can be null -> shows placeholder

  const WmProduct({
    required this.id,
    required this.name,
    required this.priceCents,
    this.imageUrl,
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
      image: p.imageUrl,
      priceCents: p.priceCents,
      salePriceCents: null,
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
                      child: p.imageUrl == null || p.imageUrl!.isEmpty
                          ? Container(
                              color: const Color(0xFFF1F1F4),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.image,
                                size: 48,
                                color: Colors.black26,
                              ),
                            )
                          : Image.network(
                              p.imageUrl!,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                );
                              },
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFFF1F1F4),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.broken_image_outlined,
                                  size: 44,
                                  color: Colors.black26,
                                ),
                              ),
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
