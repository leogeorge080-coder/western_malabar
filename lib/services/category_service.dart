import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:western_malabar/models/category_model.dart';

class CategoryService {
  static SupabaseClient get _sb => Supabase.instance.client;

  static Future<List<CategoryModel>> fetchActive({int limit = 50}) async {
    final res = await _sb
        .from('categories')
        .select('id,name,slug,icon,sort_order,is_active')
        .eq('is_active', true)
        .order('sort_order')
        .limit(limit);
    return (res as List).map((e) => CategoryModel.fromMap(e)).toList();
  }
}
