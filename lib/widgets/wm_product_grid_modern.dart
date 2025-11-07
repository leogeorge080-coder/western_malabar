import 'package:flutter/material.dart';

/// Minimal product type for this grid. If you already have a model,
/// just map to these fields when you pass [products].
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

/// Modern, bold 2-column grid with floating price tags and reveal-on-tap
/// Add button. Great for a home feed section.
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
              childAspectRatio: .78, // tall, visual cards
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

class _ProductTileState extends State<_ProductTile>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _a = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 150));

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF5A2D82);
    final p = widget.product;

    return GestureDetector(
      onTapDown: (_) {
        _a.forward();
        setState(() => _pressed = true);
      },
      onTapCancel: () {
        _a.reverse();
        setState(() => _pressed = false);
      },
      onTapUp: (_) {
        _a.reverse();
        setState(() => _pressed = false);
      },
      onTap: () => widget.onTap?.call(p),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        scale: _pressed ? 0.98 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x15000000),
                  blurRadius: 12,
                  offset: Offset(0, 6)),
            ],
          ),
          child: Column(
            children: [
              // Image area
              Expanded(
                child: Stack(
                  children: [
                    // image / placeholder
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(18)),
                        child: p.imageUrl == null || p.imageUrl!.isEmpty
                            ? Container(
                                color: const Color(0xFFF1F1F4),
                                alignment: Alignment.center,
                                child: const Icon(Icons.image,
                                    size: 48, color: Colors.black26),
                              )
                            : Image.network(
                                p.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xFFF1F1F4),
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.broken_image_outlined,
                                      size: 44, color: Colors.black26),
                                ),
                              ),
                      ),
                    ),
                    // floating price tag
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: _PriceTag(text: _gbp(p.priceCents)),
                    ),
                    // add button overlay (appears when pressed)
                    Positioned(
                      left: 10,
                      bottom: 10,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 150),
                        opacity: _pressed ? 1 : 0,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => widget.onAdd?.call(p),
                          icon: const Icon(Icons.add_shopping_cart, size: 18),
                          label: const Text('Add'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Info
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _gbp(p.priceCents),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
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

class _PriceTag extends StatelessWidget {
  const _PriceTag({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 13,
        ),
      ),
    );
  }
}

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
      child: const Text('No picks yet — check back soon!',
          style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
    );
  }
}

// Helpers
String _gbp(int cents) {
  final pounds = cents / 100.0;
  return '£${pounds.toStringAsFixed(2)}';
}
