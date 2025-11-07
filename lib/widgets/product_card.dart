// lib/widgets/product_card.dart   ← make sure the file name is product_card.dart

import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/product_model.dart';
import '../utils/haptic.dart';

class ProductCard extends StatelessWidget {
  final ProductModel p;
  final VoidCallback onAdd;

  const ProductCard({
    super.key,
    required this.p,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 176,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area (placeholder for now)
            Container(
              height: 78,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F3F3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(child: Icon(Icons.image_outlined)),
            ),
            const SizedBox(height: 8),

            // Name
            Text(
              p.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 6),

            // Price
            Text(
              _price(p),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),

            const Spacer(),

            // Add button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Haptic.heavy(context); // ✅ pass context for reliable haptics
                  onAdd(); // your existing add-to-cart logic
                },
                icon: const Icon(Icons.add_shopping_cart_outlined, size: 16),
                label: const Text('Add', style: TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(32),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: WMTheme.royalPurple,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _price(ProductModel p) {
    final cents = p.salePriceCents ?? p.priceCents ?? 0;
    return '£${(cents / 100).toStringAsFixed(2)}';
  }
}
