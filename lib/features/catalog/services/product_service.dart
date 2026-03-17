import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:western_malabar/features/catalog/models/product_model.dart';

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

class ProductCursor {
  final DateTime createdAt;
  final String id;
  const ProductCursor({required this.createdAt, required this.id});
}

class WmProductDto {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String categoryId;
  final String brandId;
  final String? brandName;
  final List<dynamic> images;
  final bool isActive;
  final List<WmVariantDto> variants;
  final DateTime? createdAt;
  final double? avgRating;
  final int? ratingCount;

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
    this.createdAt,
    this.brandName,
    this.avgRating,
    this.ratingCount,
  });

  ProductCursor? get cursor =>
      createdAt == null ? null : ProductCursor(createdAt: createdAt!, id: id);

  String? get firstImageUrl {
    if (images.isEmpty) return null;
    final v = images.first;
    return (v is String && v.trim().isNotEmpty) ? v : null;
  }

  int get priceCents => variants.isEmpty ? 0 : variants.first.priceCents;

  int get displayPriceCents {
    if (variants.isEmpty) return 0;
    final v = variants.first;
    return (v.salePriceCents != null && v.salePriceCents! > 0)
        ? v.salePriceCents!
        : v.priceCents;
  }

  bool get inStock => variants.any((v) => v.stockQty > 0);

  WmProductDto copyWith({
    String? brandName,
    double? avgRating,
    int? ratingCount,
  }) {
    return WmProductDto(
      id: id,
      name: name,
      slug: slug,
      description: description,
      categoryId: categoryId,
      brandId: brandId,
      brandName: brandName ?? this.brandName,
      images: images,
      isActive: isActive,
      variants: variants,
      createdAt: createdAt,
      avgRating: avgRating ?? this.avgRating,
      ratingCount: ratingCount ?? this.ratingCount,
    );
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

class _RatingStatLite {
  final double? avgRating;
  final int ratingCount;

  const _RatingStatLite({
    required this.avgRating,
    required this.ratingCount,
  });
}

class ProductService {
  final SupabaseClient _sb = Supabase.instance.client;

  static const String productSelect =
      'id,name,slug,description,category_id,brand_id,images,is_active,created_at,'
      'product_variants(sku,price_cents,sale_price_cents,stock_qty)';

  static const String productLiteSelect =
      'id,name,slug,category_id,brand_id,images,is_active,created_at,'
      'product_variants(sku,price_cents,sale_price_cents,stock_qty)';

  static const String _rpcSearchIds = 'search_products';

  Future<List<WmProductDto>> fetchTodaysPicks({
    int limit = 24,
    int offset = 0,
  }) async {
    final data = await _sb
        .from('products')
        .select(productLiteSelect)
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .range(offset, offset + limit - 1);

    final mapped = _mapProductsList(data).where((p) => p.inStock).toList();
    return _enrichProducts(mapped);
  }

  Future<List<WmProductDto>> fetchFeedCursor({
    int limit = 24,
    ProductCursor? after,
  }) async {
    final offset = after == null ? 0 : after.createdAt.millisecondsSinceEpoch;

    final data = await _sb
        .from('products')
        .select(productLiteSelect)
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .range(offset, offset + limit - 1);

    final mapped = _mapProductsList(data).where((p) => p.inStock).toList();
    return _enrichProducts(mapped);
  }

  Future<List<WmProductDto>> fetchByCategorySlug(
    String categorySlug, {
    int limit = 24,
    int offset = 0,
    bool onlyInStock = false,
  }) async {
    final data = await _sb
        .from('products')
        .select('$productLiteSelect,categories!inner(slug)')
        .eq('categories.slug', categorySlug)
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .range(offset, offset + limit - 1);

    var list = _mapProductsList(data);
    if (onlyInStock) {
      list = list.where((p) => p.inStock).toList();
    }
    return _enrichProducts(list);
  }

  Future<List<WmProductDto>> fetchCategoryCursor(
    String categorySlug, {
    int limit = 24,
    ProductCursor? after,
    bool onlyInStock = false,
  }) async {
    final data = await _sb
        .from('products')
        .select('$productLiteSelect,categories!inner(slug)')
        .eq('categories.slug', categorySlug)
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .limit(limit);

    var list = _mapProductsList(data);
    if (onlyInStock) {
      list = list.where((p) => p.inStock).toList();
    }
    return _enrichProducts(list);
  }

  Future<List<WmProductDto>> searchProductsRpc(
    String query, {
    int limit = 20,
    int offset = 0,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return const <WmProductDto>[];

    final raw = await _sb.rpc(_rpcSearchIds, params: {
      'q': q,
      'lim': limit,
      'off': offset,
    });

    final ids = (raw as List<dynamic>)
        .map((r) => (r as Map<String, dynamic>)['id'].toString())
        .where((s) => s.isNotEmpty)
        .toList();

    if (ids.isEmpty) return const <WmProductDto>[];

    final data = await _sb
        .from('products')
        .select(productLiteSelect)
        .inFilter('id', ids);

    final byId = <String, WmProductDto>{};
    final enriched = await _enrichProducts(
        _mapProductsList(data).where((p) => p.inStock).toList());
    for (final p in enriched) {
      byId[p.id] = p;
    }
    return ids.map((id) => byId[id]).whereType<WmProductDto>().toList();
  }

  Future<List<ProductModel>> fetchProductModelsByQuery(
    String query, {
    int limit = 30,
    int offset = 0,
  }) async {
    final results = await searchProductsRpc(
      query,
      limit: limit,
      offset: offset,
    );

    if (results.isEmpty) return const <ProductModel>[];

    final categoryIds = results
        .map((p) => p.categoryId)
        .where((e) => e.trim().isNotEmpty)
        .toSet()
        .toList();

    Map<String, Map<String, String>> categoryMap = {};

    if (categoryIds.isNotEmpty) {
      final res = await _sb
          .from('categories')
          .select('id,name,slug')
          .inFilter('id', categoryIds);

      for (final row in (res as List<dynamic>)) {
        final m = row as Map<String, dynamic>;
        final id = (m['id'] ?? '').toString();
        if (id.isEmpty) continue;

        categoryMap[id] = {
          'name': (m['name'] ?? '').toString(),
          'slug': (m['slug'] ?? '').toString(),
        };
      }
    }

    return results.map((p) {
      final category = categoryMap[p.categoryId];
      return ProductModel(
        id: p.id,
        name: p.name,
        brandName: p.brandName,
        image: p.firstImageUrl,
        priceCents: p.priceCents,
        salePriceCents:
            p.variants.isEmpty ? null : p.variants.first.salePriceCents,
        avgRating: p.avgRating,
        ratingCount: p.ratingCount,
        categoryName: category?['name'],
        categorySlug: category?['slug'],
      );
    }).toList();
  }

  @Deprecated('Use searchProductsRpc() with debounce instead')
  Future<List<WmProductDto>> searchProducts(
    String query, {
    int limit = 20,
    int offset = 0,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return const <WmProductDto>[];

    final data = await _sb
        .from('products')
        .select(productLiteSelect)
        .eq('is_active', true)
        .ilike('name', '%$q%')
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .range(offset, offset + limit - 1);

    final mapped = _mapProductsList(data).where((p) => p.inStock).toList();
    final qLower = q.toLowerCase();
    final filtered = mapped.where((p) {
      final inName = p.name.toLowerCase().contains(qLower);
      final inSku = p.variants.any((v) => v.sku.toLowerCase().contains(qLower));
      return inName || inSku;
    }).toList();

    return _enrichProducts(filtered);
  }

  Future<List<CategoryLite>> fetchCategories() async {
    final data = await _sb
        .from('categories')
        .select('id,name,slug,sort_order')
        .order('sort_order', ascending: true)
        .order('name', ascending: true);

    return (data as List<dynamic>).map((row) {
      final m = row as Map<String, dynamic>;
      return CategoryLite(
        id: (m['id'] ?? '').toString(),
        name: (m['name'] ?? '') as String,
        slug: (m['slug'] ?? '') as String,
        sortOrder: (m['sort_order'] as int?) ?? 0,
      );
    }).toList();
  }

  Future<List<BrandLite>> fetchBrands() async {
    final data = await _sb
        .from('brands')
        .select('id,name,slug')
        .order('name', ascending: true);

    return (data as List<dynamic>).map((row) {
      final m = row as Map<String, dynamic>;
      return BrandLite(
        id: (m['id'] ?? '').toString(),
        name: (m['name'] ?? '') as String,
        slug: (m['slug'] ?? '') as String,
      );
    }).toList();
  }

  Future<WmProductDto?> fetchProductBySlug(String slug) async {
    final data = await _sb
        .from('products')
        .select(productSelect)
        .eq('slug', slug)
        .limit(1);

    if (data.isNotEmpty) {
      final mapped = _mapProductRow(data.first as Map<String, dynamic>);
      if (mapped == null) return null;
      final enriched = await _enrichProducts([mapped]);
      return enriched.isEmpty ? null : enriched.first;
    }
    return null;
  }

  Future<ProductModel?> fetchProductModelById(String id) async {
    final data =
        await _sb.from('products').select(productSelect).eq('id', id).limit(1);

    if (data.isEmpty) return null;

    final row = data.first as Map<String, dynamic>;
    final productId = (row['id'] ?? '').toString();
    final brandId = (row['brand_id'] ?? '').toString();

    final images = row['images'] as List?;
    final imageUrl =
        (images != null && images.isNotEmpty) ? images.first as String? : null;

    String? brandName;
    if (brandId.isNotEmpty) {
      final brandMap = await _fetchBrandNamesByIds({brandId});
      brandName = brandMap[brandId];
    }

    double? avgRating;
    int? ratingCount;
    final ratingMap = await _fetchRatingStatsByProductIds({productId});
    final rating = ratingMap[productId];
    if (rating != null) {
      avgRating = rating.avgRating;
      ratingCount = rating.ratingCount;
    }

    return ProductModel(
      id: productId,
      name: (row['name'] ?? '') as String,
      brandName: brandName,
      image: imageUrl,
      priceCents: _extractFirstPrice(row, 'price_cents'),
      salePriceCents: _extractFirstPrice(row, 'sale_price_cents'),
      avgRating: avgRating,
      ratingCount: ratingCount,
    );
  }

  Future<List<ProductModel>> fetchProductModelsBySubcategorySlug(
    String subcategorySlug, {
    int limit = 100,
  }) async {
    final data = await _sb
        .from('v_products_unified')
        .select(
          'product_id,product_name,brand_name,price_cents,sale_price_cents,stock_qty',
        )
        .eq('subcategory_slug', subcategorySlug)
        .gt('price_cents', 0)
        .gt('stock_qty', 0)
        .order('product_name', ascending: true)
        .limit(limit);

    final rows = (data as List).cast<Map<String, dynamic>>();
    final productIds =
        rows.map((m) => (m['product_id'] ?? '').toString()).toSet();
    final ratingMap = await _fetchRatingStatsByProductIds(productIds);

    return rows.map((m) {
      final id = (m['product_id'] ?? '').toString();
      final rating = ratingMap[id];
      return ProductModel(
        id: id,
        name: (m['product_name'] ?? '').toString(),
        brandName: (m['brand_name'] ?? '').toString().trim().isEmpty
            ? null
            : (m['brand_name'] ?? '').toString(),
        image: null,
        priceCents: (m['price_cents'] as num?)?.toInt(),
        salePriceCents: (m['sale_price_cents'] as num?)?.toInt(),
        avgRating: rating?.avgRating,
        ratingCount: rating?.ratingCount,
      );
    }).toList();
  }

  int? _extractFirstPrice(Map<String, dynamic> row, String priceField) {
    try {
      final variants = row['product_variants'] as List?;
      if (variants == null || variants.isEmpty) return null;
      final first = variants.first as Map<String, dynamic>;
      return (first[priceField] as num?)?.toInt();
    } catch (_) {
      return null;
    }
  }

  Future<List<WmProductDto>> _enrichProducts(
      List<WmProductDto> products) async {
    if (products.isEmpty) return const <WmProductDto>[];

    final brandIds = products
        .map((p) => p.brandId)
        .where((id) => id.trim().isNotEmpty)
        .toSet();

    final productIds = products.map((p) => p.id).toSet();

    final brandMap = await _fetchBrandNamesByIds(brandIds);
    final ratingMap = await _fetchRatingStatsByProductIds(productIds);

    return products.map((p) {
      final rating = ratingMap[p.id];
      return p.copyWith(
        brandName: brandMap[p.brandId],
        avgRating: rating?.avgRating,
        ratingCount: rating?.ratingCount,
      );
    }).toList();
  }

  Future<Map<String, String>> _fetchBrandNamesByIds(
      Set<String> brandIds) async {
    if (brandIds.isEmpty) return const <String, String>{};

    final data = await _sb
        .from('brands')
        .select('id,name')
        .inFilter('id', brandIds.toList());

    final out = <String, String>{};
    for (final row in (data as List<dynamic>)) {
      final m = row as Map<String, dynamic>;
      final id = (m['id'] ?? '').toString();
      final name = (m['name'] ?? '').toString();
      if (id.isNotEmpty && name.isNotEmpty) {
        out[id] = name;
      }
    }
    return out;
  }

  Future<Map<String, _RatingStatLite>> _fetchRatingStatsByProductIds(
    Set<String> productIds,
  ) async {
    if (productIds.isEmpty) return const <String, _RatingStatLite>{};

    try {
      final data = await _sb
          .from('v_product_rating_stats')
          .select('product_id,avg_rating,rating_count')
          .inFilter('product_id', productIds.toList());

      final out = <String, _RatingStatLite>{};
      for (final row in (data as List<dynamic>)) {
        final m = row as Map<String, dynamic>;
        final id = (m['product_id'] ?? '').toString();
        if (id.isEmpty) continue;

        final avg = (m['avg_rating'] as num?)?.toDouble();
        final count = (m['rating_count'] as num?)?.toInt() ?? 0;

        out[id] = _RatingStatLite(
          avgRating: avg,
          ratingCount: count,
        );
      }
      return out;
    } catch (_) {
      return const <String, _RatingStatLite>{};
    }
  }

  List<WmProductDto> _mapProductsList(dynamic data) {
    if (data == null) return const <WmProductDto>[];
    final list = (data as List<dynamic>);
    return list
        .map((row) => _mapProductRow(row as Map<String, dynamic>))
        .whereType<WmProductDto>()
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
          priceCents: (m['price_cents'] as num?)?.toInt() ?? 0,
          salePriceCents: (m['sale_price_cents'] as num?)?.toInt(),
          stockQty: (m['stock_qty'] as num?)?.toInt() ?? 0,
        );
      }).toList();

      final createdAt = _parseDate(row['created_at']);

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
        createdAt: createdAt,
      );
    } catch (_) {
      return null;
    }
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) {
      try {
        return DateTime.parse(v);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}


