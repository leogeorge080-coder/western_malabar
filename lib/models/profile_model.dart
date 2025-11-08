// lib/models/product_model.dart
import 'dart:convert';

class ProductLite {
  final String id;
  final String name;
  final String slug;

  final String? brandName;
  final String? categoryName;

  /// raw list from `images` jsonb (may be empty)
  final List<String> images;

  /// Base price from view
  final int? priceCents;

  /// If present in the view
  final int? salePriceCents;

  /// Preferred price to show
  final int? effectivePriceCents;

  final bool isActive;

  const ProductLite({
    required this.id,
    required this.name,
    required this.slug,
    required this.images,
    this.brandName,
    this.categoryName,
    this.priceCents,
    this.salePriceCents,
    this.effectivePriceCents,
    this.isActive = true,
  });

  String? get thumb => images.isNotEmpty ? images.first : null;

  /// `row` is a map from `v_products_flat`
  factory ProductLite.fromMap(Map<String, dynamic> row) {
    // images can be List<dynamic>, String(json), or null
    final raw = row['images'];
    List<String> imgs = const [];
    if (raw is List) {
      imgs = raw
          .map((e) => e?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    } else if (raw is String && raw.isNotEmpty) {
      try {
        final parsed = jsonDecode(raw);
        if (parsed is List) {
          imgs = parsed
              .map((e) => e?.toString() ?? '')
              .where((s) => s.isNotEmpty)
              .toList();
        }
      } catch (_) {}
    }

    return ProductLite(
      id: (row['id'] ?? '').toString(),
      name: (row['name'] ?? '').toString(),
      slug: (row['slug'] ?? '').toString(),
      brandName: row['brand_name']?.toString(),
      categoryName: row['category_name']?.toString(),
      images: imgs,
      priceCents: row['price_cents'] as int?,
      salePriceCents: row['sale_price_cents'] as int?,
      effectivePriceCents: row['effective_price_cents'] as int?,
      isActive: (row['is_active'] as bool?) ?? true,
    );
  }
}
