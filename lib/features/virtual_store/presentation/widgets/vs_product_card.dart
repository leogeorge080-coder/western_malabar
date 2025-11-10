// lib/features/virtual_store/presentation/widgets/vs_product_card.dart
import 'package:flutter/material.dart';

class VsProductCard extends StatelessWidget {
  const VsProductCard({
    super.key,
    required this.title,
    required this.price,
    this.imageUrl,
  });

  final String title;
  final String price;
  final String? imageUrl;

  /// Placeholder (so the screen builds before wiring data).
  factory VsProductCard.placeholder({required int index}) {
    final num amount = (index + 1) * 1.25;
    return VsProductCard(
      title: 'Aisle Item #$index',
      price: '£${amount.toStringAsFixed(2)}',
      imageUrl: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF5A2D82);

    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Open "$title"'))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 6)),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: imageUrl == null
                    ? const _ShimmerBox()
                    : Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const _ShimmerBox(),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(price,
                          style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Colors.black87)),
                      const Spacer(),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => ScaffoldMessenger.of(context)
                            .showSnackBar(
                                SnackBar(content: Text('Added "$title"'))),
                        child: const Icon(Icons.add_shopping_cart, size: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Very light shimmer without extra packages.
class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox();

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))
        ..repeat();
  late final Animation<double> _t =
      CurvedAnimation(parent: _ac, curve: Curves.linear);

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (_, __) {
        final stop = 0.3 + 0.4 * _t.value;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Color(0xFFF1E9FF),
                Color(0xFFE9DFFF),
                Color(0xFFF1E9FF)
              ],
              stops: [stop - 0.2, stop, stop + 0.2],
            ),
          ),
        );
      },
    );
  }
}
