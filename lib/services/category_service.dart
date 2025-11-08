import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:western_malabar/models/category_model.dart';

/// Category data access helpers.
/// Defaults to active categories and includes hint utilities.
class CategoryService {
  static SupabaseClient get _sb => Supabase.instance.client;

  /// Fetch top categories (for quick strip)
  static Future<List<CategoryModel>> fetchTop({int limit = 14}) async {
    final res = await _sb
        .from('categories')
        .select('id,name,slug,icon,sort_order,is_active')
        .eq('is_active', true)
        .order('sort_order', ascending: true)
        .order('name', ascending: true)
        .limit(limit);

    return (res as List)
        .map((e) => CategoryModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Existing compatible version
  static Future<List<CategoryModel>> fetchActive({int limit = 50}) async {
    final res = await _sb
        .from('categories')
        .select('id,name,slug,icon,sort_order,is_active')
        .eq('is_active', true)
        .order('sort_order', ascending: true)
        .order('name', ascending: true)
        .limit(limit);
    return (res as List)
        .map((e) => CategoryModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Case-insensitive search
  static Future<List<CategoryModel>> searchByName(
    String query, {
    int limit = 50,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final res = await _sb
        .from('categories')
        .select('id,name,slug,icon,sort_order,is_active')
        .eq('is_active', true)
        .ilike('name', '%$q%')
        .order('sort_order', ascending: true)
        .order('name', ascending: true)
        .limit(limit);
    return (res as List)
        .map((e) => CategoryModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  // ─────────────────────────────────────────────
  // Rotating search hint support
  // ─────────────────────────────────────────────

  static List<String>? _hintCache;
  static DateTime? _hintCacheAt;
  static const _hintTtl = Duration(minutes: 1);

  static Future<List<String>> fetchHintPhrases({int limit = 100}) async {
    final now = DateTime.now();
    if (_hintCache != null &&
        _hintCacheAt != null &&
        now.difference(_hintCacheAt!) < _hintTtl) {
      return _hintCache!;
    }

    final res = await _sb
        .from('categories')
        .select('name')
        .eq('is_active', true)
        .order('sort_order', ascending: true)
        .order('name', ascending: true)
        .limit(limit);

    final raw = (res as List)
        .map((e) => (e['name'] ?? '').toString().trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final seen = <String>{};
    final unique = <String>[];
    for (final n in raw) {
      final k = n.toLowerCase();
      if (seen.add(k)) unique.add(n);
    }

    final phrases = unique.isEmpty
        ? ['Search products…']
        : unique.map((n) => 'Search $n…').toList();

    _hintCache = phrases;
    _hintCacheAt = now;
    return phrases;
  }

  static void invalidateHintCache() {
    _hintCache = null;
    _hintCacheAt = null;
  }
}
