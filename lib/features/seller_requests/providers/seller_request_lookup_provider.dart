import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/seller_brand_option_model.dart';
import '../models/seller_category_option_model.dart';
import '../services/seller_request_lookup_service.dart';

final sellerRequestLookupServiceProvider =
    Provider<SellerRequestLookupService>((ref) {
  return SellerRequestLookupService(Supabase.instance.client);
});

final sellerCategoriesProvider =
    FutureProvider<List<SellerCategoryOptionModel>>((ref) {
  return ref.read(sellerRequestLookupServiceProvider).fetchCategories();
});

final sellerBrandsProvider =
    FutureProvider<List<SellerBrandOptionModel>>((ref) {
  return ref.read(sellerRequestLookupServiceProvider).fetchBrands();
});
