// lib/services/category_service.dart
import 'package:flutter/foundation.dart'; // <-- for debugPrint
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:western_malabar/models/category_model.dart';

class CategoryService {
  static SupabaseClient get _sb => Supabase.instance.client;

  /// Active categories ordered by sort_order (safe + typed)
  static Future<List<CategoryModel>> fetchActive({int limit = 50}) async {
    try {
      final res = await _sb
          .from('categories')
          .select('id,name,slug,icon,sort_order,is_active')
          .eq('is_active', true)
          .order('sort_order', ascending: true)
          .limit(limit);

      final list = (res as List)
          .map((e) => CategoryModel.fromMap(e as Map<String, dynamic>))
          .toList(growable: false);

      return list;
    } catch (e, st) {
      debugPrint('❌ CategoryService.fetchActive error: $e\n$st');
      return const <CategoryModel>[];
    }
  }

  /// Shortcut: top N items for the quick-strip on Home.
  static Future<List<CategoryModel>> fetchTop({int limit = 12}) async {
    final all = await fetchActive(limit: limit);
    return all.take(limit).toList(growable: false);
  }
}
