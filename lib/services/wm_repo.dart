// lib/services/wm_repo.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductLite {
  final String id;
  final String name;
  final String? thumbUrl;
  final int priceCents; // store prices as cents
  final String? currency;

  const ProductLite({
    required this.id,
    required this.name,
    this.thumbUrl,
    required this.priceCents,
    this.currency,
  });
}

class WMRepo {
  SupabaseClient get _sb => Supabase.instance.client;

  Future<List<ProductLite>> fetchFeaturedProducts({int limit = 8}) async {
    // Example query; adjust selected columns to match your schema.
    // Expecting: products (id, name, images jsonb) + product_variants (price_cents, currency)
    final rows = await _sb
        .from('products')
        .select('id,name,images,product_variants(price_cents,currency)')
        .limit(limit);

    final List<ProductLite> out = [];
    if (rows is! List) return out;

    for (final row in rows) {
      if (row is! Map<String, dynamic>) continue;

      final id = _asString(row['id']) ?? '';
      final name = _asString(row['name']) ?? '';

      // images: jsonb array of urls
      String? thumb;
      final imgs = row['images'];
      if (imgs is List && imgs.isNotEmpty) {
        final first = imgs.first;
        if (first is String) thumb = first;
        // if objects, map and pick 'url' etc.
      }

      // variants: pick first
      int price = 0;
      String? curr;
      final v = row['product_variants'];
      if (v is List && v.isNotEmpty) {
        final first = v.first;
        if (first is Map<String, dynamic>) {
          price = _asInt(first['price_cents']) ?? 0;
          curr = _asString(first['currency']);
        }
      }

      out.add(ProductLite(
        id: id,
        name: name,
        thumbUrl: thumb,
        priceCents: price,
        currency: curr,
      ));
    }
    return out;
  }
}

// ---------- small parse helpers ----------
String? _asString(dynamic v) {
  if (v == null) return null;
  if (v is String) return v;
  return v.toString();
}

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.round();
  if (v is String) {
    final s = v.trim();
    final n = int.tryParse(s) ?? double.tryParse(s)?.round();
    return n;
  }
  return null;
}
