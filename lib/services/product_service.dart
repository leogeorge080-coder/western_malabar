import 'package:supabase_flutter/supabase_flutter.dart';

/// ─────────────────────────────────────────────────────────────────
/// Data Transfer Objects (DTOs)
/// These mirror your Supabase schema minimally and are UI-friendly.
/// ─────────────────────────────────────────────────────────────────

class WmVariantDto {
  final String sku;
  final int priceCents;
  final int? salePriceCents;
  final int stockQty;

  const WmVariantDto({
    required this.sku,
    required this.priceCents,
    required this.stockQty,
    this.salePriceCents,
  });
}

class WmProductDto {
  final String id; // uuid in DB → map to String here
  final String name;
  final String slug;
  final String? description;
  final String categoryId; // uuid
  final String brandId; // uuid
  final List<dynamic> images; // jsonb array of text urls in your schema
  final bool isActive;
  final List<WmVariantDto> variants;

  const WmProductDto({
    required this.id,
    required this.name,
    required this.slug,
    required this.categoryId,
    required this.brandId,
    required this.images,
    required this.isActive,
    required this.variants,
    this.description,
  });

  /// First image url or null
  String? get firstImageUrl {
    if (images.isEmpty) return null;
    final v = images.first;
    if (v is String && v.trim().isNotEmpty) return v;
    return null;
  }

  /// Price from first variant (fallback 0)
  int get priceCents {
    if (variants.isEmpty) return 0;
    return variants.first.priceCents;
  }

  /// Best available price (sale if present)
  int get displayPriceCents {
    if (variants.isEmpty) return 0;
    final v = variants.first;
    return (v.salePriceCents != null && v.salePriceCents! > 0)
        ? v.salePriceCents!
        : v.priceCents;
  }
}

class CategoryLite {
  final String id;
  final String name;
  final String slug;
  final int sortOrder;

  const CategoryLite({
    required this.id,
    required this.name,
    required this.slug,
    required this.sortOrder,
  });
}

class BrandLite {
  final String id;
  final String name;
  final String slug;

  const BrandLite({
    required this.id,
    required this.name,
    required this.slug,
  });
}

/// ─────────────────────────────────────────────────────────────────
/// ProductService
/// ─────────────────────────────────────────────────────────────────
class ProductService {
  final SupabaseClient _sb = Supabase.instance.client;

  /// Common select for products with nested variants.
  /// NOTE: Only columns that exist in your SQL are selected
  /// (no `currency` column).
  static const _productSelect =
      'id,name,slug,description,category_id,brand_id,images,is_active,'
      'product_variants(sku,price_cents,sale_price_cents,stock_qty)';

  /// Home: a small curated list. You can later add a boolean flag
  /// column like `is_featured` and filter on that.
  Future<List<WmProductDto>> fetchTodaysPicks({
    int limit = 8,
    int offset = 0,
  }) async {
    final data = await _sb
        .from('products')
        .select(_productSelect)
        .eq('is_active', true)
        .order('created_at', ascending: false) // if you have this column
        .range(offset, offset + limit - 1);

    return _mapProductsList(data);
  }

  /// Products by category slug (e.g. 'masalas-spices')
  Future<List<WmProductDto>> fetchByCategorySlug(
    String categorySlug, {
    int limit = 24,
    int offset = 0,
    bool onlyInStock = false,
  }) async {
    // Join via related table filter syntax
    // category:categories!inner(slug) exposes joined column for filter
    final data = await _sb
        .from('products')
        .select(
          '$_productSelect, categories!inner(slug)',
        )
        .eq('categories.slug', categorySlug)
        .eq('is_active', true)
        .range(offset, offset + limit - 1);

    final list = _mapProductsList(data);
    if (!onlyInStock) return list;

    return list.where((p) {
      if (p.variants.isEmpty) return false;
      return p.variants.any((v) => v.stockQty > 0);
    }).toList();
  }

  /// Simple name/sku search across active products.
  Future<List<WmProductDto>> searchProducts(
    String query, {
    int limit = 20,
    int offset = 0,
  }) async {
    if (query.trim().isEmpty) return const <WmProductDto>[];
    final q = query.trim();

    final data = await _sb
        .from('products')
        .select(_productSelect)
        .eq('is_active', true)
        .ilike('name', '%$q%')
        .range(offset, offset + limit - 1);

    // If you want to also search SKU within variants, do a second pass:
    // (client-side filter after fetching a page)
    final mapped = _mapProductsList(data);
    final qLower = q.toLowerCase();
    return mapped.where((p) {
      final inName = p.name.toLowerCase().contains(qLower);
      final inSku = p.variants.any((v) => v.sku.toLowerCase().contains(qLower));
      return inName || inSku;
    }).toList();
  }

  /// Lightweight category list for UI menus
  Future<List<CategoryLite>> fetchCategories() async {
    final data = await _sb
        .from('categories')
        .select('id,name,slug,sort_order')
        .order('sort_order', ascending: true)
        .order('name', ascending: true);

    return (data as List<dynamic>).map((row) {
      return CategoryLite(
        id: (row['id'] ?? '').toString(),
        name: (row['name'] ?? '') as String,
        slug: (row['slug'] ?? '') as String,
        sortOrder: (row['sort_order'] as int?) ?? 0,
      );
    }).toList();
  }

  /// Lightweight brand list for filters, banners, etc.
  Future<List<BrandLite>> fetchBrands() async {
    final data = await _sb
        .from('brands')
        .select('id,name,slug')
        .order('name', ascending: true);

    return (data as List<dynamic>).map((row) {
      return BrandLite(
        id: (row['id'] ?? '').toString(),
        name: (row['name'] ?? '') as String,
        slug: (row['slug'] ?? '') as String,
      );
    }).toList();
  }

  /// Optional: load a single product by slug (for PDP)
  Future<WmProductDto?> fetchProductBySlug(String slug) async {
    final data = await _sb
        .from('products')
        .select(_productSelect)
        .eq('slug', slug)
        .limit(1);

    if (data is List && data.isNotEmpty) {
      return _mapProductRow(data.first as Map<String, dynamic>);
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────────
  // Mappers
  // ─────────────────────────────────────────────────────────────

  List<WmProductDto> _mapProductsList(dynamic data) {
    if (data == null) return const <WmProductDto>[];
    final list = (data as List<dynamic>);
    return list
        .map((row) => _mapProductRow(row as Map<String, dynamic>))
        .where((p) => p != null)
        .cast<WmProductDto>()
        .toList();
  }

  WmProductDto? _mapProductRow(Map<String, dynamic> row) {
    try {
      final variantsRaw =
          (row['product_variants'] as List<dynamic>? ?? const []);
      final variants = variantsRaw.map((v) {
        final m = v as Map<String, dynamic>;
        return WmVariantDto(
          sku: (m['sku'] ?? '') as String,
          priceCents: (m['price_cents'] as int?) ?? 0,
          salePriceCents: m['sale_price_cents'] as int?,
          stockQty: (m['stock_qty'] as int?) ?? 0,
        );
      }).toList();

      return WmProductDto(
        id: (row['id'] ?? '').toString(),
        name: (row['name'] ?? '') as String,
        slug: (row['slug'] ?? '') as String,
        description: row['description'] as String?,
        categoryId: (row['category_id'] ?? '').toString(),
        brandId: (row['brand_id'] ?? '').toString(),
        images: (row['images'] as List<dynamic>? ?? const []),
        isActive: (row['is_active'] as bool?) ?? true,
        variants: variants,
      );
    } catch (e) {
      // If a row is malformed, skip it instead of crashing the UI.
      // You can log to analytics here if you want.
      return null;
    }
  }
}
