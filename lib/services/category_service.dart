// lib/services/category_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:western_malabar/models/category_model.dart';

/// Category data access helpers.
/// - Defaults to active categories
/// - Sorted by sort_order then name
/// - Includes small in-memory cache for rotating search hints
class CategoryService {
  static SupabaseClient get _sb => Supabase.instance.client;

  /// Top categories for the quick horizontal strip on Home.
  static Future<List<CategoryModel>> fetchTop({int limit = 14}) async {
    final res = await _sb
        .from('categories')
        .select('id,name,slug,icon,sort_order,is_active')
        .eq('is_active', true)
        .order('sort_order', ascending: true, nullsFirst: false)
        .order('name', ascending: true)
        .limit(limit);

    final list = (res as List).cast<Map<String, dynamic>>();
    return list.map(CategoryModel.fromMap).toList();
  }

  /// Your original method, kept for compatibility.
  static Future<List<CategoryModel>> fetchActive({int limit = 50}) async {
    final res = await _sb
        .from('categories')
        .select('id,name,slug,icon,sort_order,is_active')
        .eq('is_active', true)
        .order('sort_order', ascending: true, nullsFirst: false)
        .order('name', ascending: true)
        .limit(limit);

    final list = (res as List).cast<Map<String, dynamic>>();
    return list.map(CategoryModel.fromMap).toList();
  }

  /// Case-insensitive name search.
  static Future<List<CategoryModel>> searchByName(
    String query, {
    int limit = 50,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return const <CategoryModel>[];

    final res = await _sb
        .from('categories')
        .select('id,name,slug,icon,sort_order,is_active')
        .eq('is_active', true)
        .ilike('name', '%$q%')
        .order('sort_order', ascending: true, nullsFirst: false)
        .order('name', ascending: true)
        .limit(limit);

    final list = (res as List).cast<Map<String, dynamic>>();
    return list.map(CategoryModel.fromMap).toList();
  }

  // ─────────────────────────────────────────────────────────
  // Rotating search hint phrases (for the Home search bar)
  // ─────────────────────────────────────────────────────────

  static List<String>? _hintCache;
  static DateTime? _hintCacheAt;
  static const _hintTtl = Duration(minutes: 1);

  /// Returns phrases like ["Search Rice…", "Search Frozen Vegetables…", ...]
  /// Call this once when the Home screen builds, then rotate locally via Timer.
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
        .order('sort_order', ascending: true, nullsFirst: false)
        .order('name', ascending: true)
        .limit(limit);

    final raw = (res as List)
        .cast<Map<String, dynamic>>()
        .map((e) => (e['name'] ?? '').toString().trim())
        .where((s) => s.isNotEmpty)
        .toList();

    // De-duplicate while preserving order
    final seen = <String>{};
    final unique = <String>[];
    for (final n in raw) {
      final k = n.toLowerCase();
      if (seen.add(k)) unique.add(n);
    }

    final phrases = unique.isEmpty
        ? <String>['Search products…']
        : unique.map((n) => 'Search $n…').toList();

    _hintCache = phrases;
    _hintCacheAt = now;
    return phrases;
  }

  /// Invalidate the hint cache (call after mutating categories).
  static void invalidateHintCache() {
    _hintCache = null;
    _hintCacheAt = null;
  }
}
