import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:western_malabar/features/catalog/models/product_model.dart';
import 'package:western_malabar/features/catalog/services/product_service.dart';

final productServiceProvider = Provider<ProductService>((ref) {
  return ProductService();
});

final relatedProductsProvider =
    FutureProvider.family<List<ProductModel>, ProductModel>(
  (ref, product) async {
    final service = ref.read(productServiceProvider);

    /// 1. Same category products
    final categoryProducts =
        await service.fetchProductsByCategory(product.categorySlug);

    /// Remove current product
    final filtered =
        categoryProducts.where((ProductModel p) => p.id != product.id).toList();

    /// 2. Add combo products
    final combos = await service.fetchComboProducts(product);

    /// Merge + deduplicate
    final all = <ProductModel>[...filtered, ...combos];

    final unique = <String, ProductModel>{
      for (var p in all) p.id: p,
    }.values.toList();

    return unique.take(10).toList();
  },
);
