import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:western_malabar/features/admin/models/admin_product_edit_model.dart';
import 'package:western_malabar/features/admin/services/admin_products_service.dart';

final adminProductsServiceProvider = Provider<AdminProductsService>((ref) {
  return AdminProductsService(Supabase.instance.client);
});

final adminProductsProvider =
    FutureProvider<List<AdminProductEditModel>>((ref) async {
  return ref.read(adminProductsServiceProvider).fetchProducts();
});

final adminProductByIdProvider =
    FutureProvider.family<AdminProductEditModel, String>(
        (ref, productId) async {
  return ref.read(adminProductsServiceProvider).fetchProductById(productId);
});

final adminBrandsProvider = FutureProvider<List<AdminBrandOption>>((ref) async {
  return ref.read(adminProductsServiceProvider).fetchBrands();
});

final adminCategoriesProvider =
    FutureProvider<List<AdminCategoryOption>>((ref) async {
  return ref.read(adminProductsServiceProvider).fetchCategories();
});




