import 'package:flutter/material.dart';

/// Minimal product type for this grid.
/// If you already have a model, just map to these fields.
class WmProduct {
  final String id;
  final String name;
  final int priceCents;
  final String? imageUrl;

  const WmProduct({
    required this.id,
    required this.name,
    required this.priceCents,
    this.imageUrl,
  });
}

/// Modern 2-column product grid
class WMTodaysPicksGrid extends StatelessWidget {
  const WMTodaysPicksGrid({
    super.key,
    required this.products,
    this.title = "Today's Picks",
    this.onAdd,
    this.onTap,
    this.crossAxisCount = 2,
  });

  final List<WmProduct> products;
  final String title;
  final void Function(WmProduct product)? onAdd;
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
          const _EmptyState()
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
              onAdd: onAdd,
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
    this.onAdd,
    this.onTap,
  });

  final WmProduct product;
  final void Function(WmProduct product)? onAdd;
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

    return AnimatedScale(
      duration: const Duration(milliseconds: 140),
      scale: _pressed ? 0.97 : 1.0,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onHighlightChanged: (v) => setState(() => _pressed = v),
          onTap: () => widget.onTap?.call(p),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _pressed
                    ? purple.withOpacity(0.18)
                    : Colors.black.withOpacity(0.05),
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
                /// IMAGE
                Expanded(
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(18)),
                    child: SizedBox(
                      width: double.infinity,
                      child: (p.imageUrl == null || p.imageUrl!.isEmpty)
                          ? Container(
                              color: const Color(0xFFF1F1F4),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.image,
                                size: 46,
                                color: Colors.black26,
                              ),
                            )
                          : Image.network(
                              p.imageUrl!,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;

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

                /// PRODUCT INFO
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// NAME
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

                      /// PRICE + ADD BUTTON
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
                          SizedBox(
                            height: 34,
                            width: 64,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: purple,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () => widget.onAdd?.call(p),
                              child: const Text(
                                'Add',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
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
      ),
    );
  }
}

/// Empty state
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        'No picks yet — check back soon!',
        style: TextStyle(
          color: Colors.black54,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// GBP formatter
String _gbp(int cents) {
  final pounds = cents / 100.0;
  return '£${pounds.toStringAsFixed(2)}';
}




