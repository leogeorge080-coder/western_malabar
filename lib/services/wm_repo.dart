// lib/services/wm_repo.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class CategoryLite {
  final String id;
  final String name;
  final int? sortOrder;
  const CategoryLite({required this.id, required this.name, this.sortOrder});
}

class ProductLite {
  final String id;
  final String name;
  final String? thumbUrl; // first image from products.images[]
  final int priceCents; // from first product_variants row
  final String currency; // defaults to GBP
  const ProductLite({
    required this.id,
    required this.name,
    this.thumbUrl,
    required this.priceCents,
    required this.currency,
  });

  String get priceLabel => '£${(priceCents / 100).toStringAsFixed(2)}';
}

class WMRepo {
  final SupabaseClient _db = Supabase.instance.client;

  Future<List<CategoryLite>> fetchCategories() async {
    final res = await _db
        .from('categories')
        .select('id,name,sort_order,is_active')
        .eq('is_active', true)
        .order('sort_order', ascending: true);

    return (res as List)
        .map((j) => CategoryLite(
              id: j['id'].toString(),
              name: j['name'] as String,
              sortOrder: j['sort_order'] as int?,
            ))
        .toList();
  }

  Future<List<ProductLite>> fetchFeaturedProducts({int limit = 8}) async {
    final res = await _db
        .from('products')
        .select('id,name,images,is_active')
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .limit(limit);

    final out = <ProductLite>[];
    for (final p in (res as List)) {
      final variants = await _db
          .from('product_variants')
          .select('price_cents,currency')
          .eq('product_id', p['id'])
          .limit(1);

      final vList = variants as List;
      final price = vList.isNotEmpty ? (vList.first['price_cents'] as int) : 0;
      final curr = vList.isNotEmpty
          ? (vList.first['currency'] as String? ?? 'GBP')
          : 'GBP';

      final imgs = (p['images'] as List<dynamic>?) ?? const [];
      final thumb = imgs.isNotEmpty ? imgs.first as String : null;

      out.add(ProductLite(
        id: p['id'].toString(),
        name: p['name'] as String,
        thumbUrl: thumb,
        priceCents: price,
        currency: curr,
      ));
    }
    return out;
  }
}
