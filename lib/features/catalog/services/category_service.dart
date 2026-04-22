// lib/features/catalog/services/category_service.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:western_malabar/features/catalog/models/category_model.dart';

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

  /// Home categories derived from the live unified catalog view.
  /// Only includes categories that currently have sellable items.
  static Future<List<CategoryModel>> fetchHomeCategories(
      {int limit = 14}) async {
    try {
      final res = await _sb
          .from('v_products_unified')
          .select('category_name, category_slug, price_cents, stock_qty')
          .order('category_name', ascending: true)
          .timeout(const Duration(seconds: 10));

      final rows = (res as List).cast<Map<String, dynamic>>();

      final seen = <String>{};
      final out = <CategoryModel>[];

      for (final r in rows) {
        final slug = (r['category_slug'] ?? '').toString().trim();
        final name = (r['category_name'] ?? '').toString().trim();
        final price = (r['price_cents'] as num?)?.toInt() ?? 0;
        final stock = (r['stock_qty'] as num?)?.toInt() ?? 0;

        if (slug.isEmpty || name.isEmpty) continue;
        if (price <= 0) continue;
        if (stock <= 0) continue;
        if (!seen.add(slug)) continue;

        out.add(
          CategoryModel(
            id: slug, // UI-safe synthetic id
            name: name,
            slug: slug,
            icon: null,
            sortOrder: out.length,
            isActive: true,
          ),
        );

        if (out.length >= limit) break;
      }

      return out;
    } catch (e) {
      debugPrint('❌ Error fetching home categories: $e');
      return []; // Return empty list instead of hanging
    }
  }

  /// All categories that exist in the unified catalog view.
  /// Unlike fetchHomeCategories(), this does not require positive price/stock.
  static Future<List<CategoryModel>> fetchCatalogCategories(
      {int limit = 200}) async {
    final res = await _sb
        .from('v_products_unified')
        .select('category_name, category_slug')
        .order('category_name', ascending: true);

    final rows = (res as List).cast<Map<String, dynamic>>();

    final seen = <String>{};
    final out = <CategoryModel>[];

    for (final r in rows) {
      final slug = (r['category_slug'] ?? '').toString().trim();
      final name = (r['category_name'] ?? '').toString().trim();

      if (slug.isEmpty || name.isEmpty) continue;
      if (!seen.add(slug)) continue;

      out.add(
        CategoryModel(
          id: slug,
          name: name,
          slug: slug,
          icon: null,
          sortOrder: out.length,
          isActive: true,
        ),
      );

      if (out.length >= limit) break;
    }

    return out;
  }

  /// Fetch subcategories (children) by parent slug.
  static Future<List<CategoryModel>> fetchChildrenByParentSlug(
    String parentSlug, {
    int limit = 100,
  }) async {
    final parentRes = await _sb
        .from('categories')
        .select('id')
        .eq('slug', parentSlug)
        .eq('is_active', true)
        .maybeSingle();

    if (parentRes == null) return const <CategoryModel>[];

    final parentId = (parentRes['id'] ?? '').toString();
    if (parentId.isEmpty) return const <CategoryModel>[];

    final res = await _sb
        .from('categories')
        .select('id,name,slug,icon,sort_order,is_active')
        .eq('is_active', true)
        .eq('parent_id', parentId)
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

  /// Returns phrases derived from the live catalog-backed categories.
  static Future<List<String>> fetchHintPhrases({int limit = 100}) async {
    final now = DateTime.now();
    if (_hintCache != null &&
        _hintCacheAt != null &&
        now.difference(_hintCacheAt!) < _hintTtl) {
      return _hintCache!;
    }

    final rows = await fetchCatalogCategories(limit: limit);

    final raw =
        rows.map((e) => e.name.trim()).where((s) => s.isNotEmpty).toList();

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
