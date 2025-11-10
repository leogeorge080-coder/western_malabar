import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:western_malabar/features/virtual_store/domain/vs_product.dart';

class VirtualStoreRepository {
  final _sb = Supabase.instance.client;
  Future<List<VsProduct>> fetchShelf(String shelfSlug) async {
    // TODO: change to your view/table
    final rows = await _sb
        .from('products')
        .select('id,name,images,product_variants(price_cents)')
        .limit(20);
    return (rows as List).map((r) {
      final imgs = (r['images'] as List?) ?? const [];
      final cents =
          ((r['product_variants'] as List?)?.first?['price_cents'] as int?) ??
              0;
      return VsProduct(
        id: "${r["id"]}",
        name: "${r["name"]}",
        imageUrl: imgs.isNotEmpty ? '${imgs.first}' : '',
        price: cents / 100.0,
      );
    }).toList();
  }
}
