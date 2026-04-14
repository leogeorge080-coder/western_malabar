import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/seller_brand_option_model.dart';
import '../models/seller_category_option_model.dart';

class SellerRequestLookupService {
  SellerRequestLookupService(this._supabase);

  final SupabaseClient _supabase;

  Future<List<SellerCategoryOptionModel>> fetchCategories() async {
    final rows = await _supabase
        .from('categories')
        .select('id, name, slug')
        .order('name');

    return (rows as List)
        .map((e) => SellerCategoryOptionModel.fromMap(
              Map<String, dynamic>.from(e as Map),
            ))
        .toList();
  }

  Future<List<SellerBrandOptionModel>> fetchBrands() async {
    final rows =
        await _supabase.from('brands').select('id, name, slug').order('name');

    return (rows as List)
        .map((e) => SellerBrandOptionModel.fromMap(
              Map<String, dynamic>.from(e as Map),
            ))
        .toList();
  }
}
