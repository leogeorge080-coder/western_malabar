import 'dart:math' as math;

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

  const ProductCursor({
    required this.createdAt,
    required this.id,
  });
}

class WmProductDto {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String categoryId;
  final String brandId;
  final String? brandName;
  final String? barcode;
  final bool isFrozen;
  final List<dynamic> images;
  final bool isActive;
  final List<WmVariantDto> variants;
  final DateTime? createdAt;
  final double? avgRating;
  final int? ratingCount;
  final String? sellerId;
  final int? sellerBasePriceCents;
  final int? rememberedQty;
  final bool isWeeklyDeal;
  final int? dealPriceCents;
  final DateTime? dealStartsAt;
  final DateTime? dealEndsAt;
  final String? dealBadgeText;

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
    this.barcode,
    this.isFrozen = false,
    this.sellerId,
    this.sellerBasePriceCents,
    this.rememberedQty,
    this.isWeeklyDeal = false,
    this.dealPriceCents,
    this.dealStartsAt,
    this.dealEndsAt,
    this.dealBadgeText,
  });

  ProductCursor? get cursor =>
      createdAt == null ? null : ProductCursor(createdAt: createdAt!, id: id);

  String? get firstImageUrl {
    if (images.isEmpty) return null;
    final v = images.first;
    return (v is String && v.trim().isNotEmpty) ? v : null;
  }

  bool get _dealIsActive {
    final now = DateTime.now();
    final startsOk = dealStartsAt == null || !now.isBefore(dealStartsAt!);
    final endsOk = dealEndsAt == null || !now.isAfter(dealEndsAt!);
    return startsOk && endsOk;
  }

  int get priceCents {
    if (variants.isNotEmpty && variants.first.priceCents > 0) {
      return variants.first.priceCents;
    }
    if ((sellerBasePriceCents ?? 0) > 0) {
      return sellerBasePriceCents!;
    }
    return 0;
  }

  int get originalPriceCents => priceCents;

  int get displayPriceCents {
    if (isWeeklyDeal &&
        dealPriceCents != null &&
        dealPriceCents! > 0 &&
        _dealIsActive) {
      return dealPriceCents!;
    }

    if (variants.isNotEmpty) {
      final v = variants.first;
      if (v.salePriceCents != null &&
          v.salePriceCents! > 0 &&
          v.salePriceCents! < v.priceCents) {
        return v.salePriceCents!;
      }
      if (v.priceCents > 0) {
        return v.priceCents;
      }
    }

    if ((sellerBasePriceCents ?? 0) > 0) {
      return sellerBasePriceCents!;
    }

    return 0;
  }

  bool get inStock {
    if (variants.isNotEmpty) {
      return variants.any((v) => v.stockQty > 0);
    }
    return (sellerBasePriceCents ?? 0) > 0;
  }

  WmProductDto copyWith({
    String? brandName,
    double? avgRating,
    int? ratingCount,
    String? barcode,
    bool? isFrozen,
    String? sellerId,
    int? sellerBasePriceCents,
    int? rememberedQty,
    bool? isWeeklyDeal,
    int? dealPriceCents,
    DateTime? dealStartsAt,
    DateTime? dealEndsAt,
    String? dealBadgeText,
  }) {
    return WmProductDto(
      id: id,
      name: name,
      slug: slug,
      description: description,
      categoryId: categoryId,
      brandId: brandId,
      brandName: brandName ?? this.brandName,
      barcode: barcode ?? this.barcode,
      isFrozen: isFrozen ?? this.isFrozen,
      images: images,
      isActive: isActive,
      variants: variants,
      createdAt: createdAt,
      avgRating: avgRating ?? this.avgRating,
      ratingCount: ratingCount ?? this.ratingCount,
      sellerId: sellerId ?? this.sellerId,
      sellerBasePriceCents: sellerBasePriceCents ?? this.sellerBasePriceCents,
      rememberedQty: rememberedQty ?? this.rememberedQty,
      isWeeklyDeal: isWeeklyDeal ?? this.isWeeklyDeal,
      dealPriceCents: dealPriceCents ?? this.dealPriceCents,
      dealStartsAt: dealStartsAt ?? this.dealStartsAt,
      dealEndsAt: dealEndsAt ?? this.dealEndsAt,
      dealBadgeText: dealBadgeText ?? this.dealBadgeText,
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
  ProductService({SupabaseClient? supabase})
      : _sb = supabase ?? Supabase.instance.client;

  final SupabaseClient _sb;

  static const String productSelect =
      'id,name,slug,description,category_id,brand_id,barcode,is_frozen,images,is_active,created_at,'
      'seller_id,seller_base_price_cents,'
      'is_weekly_deal,deal_price_cents,deal_starts_at,deal_ends_at,deal_badge_text,'
      'product_variants(sku,price_cents,sale_price_cents,stock_qty)';

  static const String productLiteSelect =
      'id,name,slug,category_id,brand_id,barcode,is_frozen,images,is_active,created_at,'
      'seller_id,seller_base_price_cents,'
      'is_weekly_deal,deal_price_cents,deal_starts_at,deal_ends_at,deal_badge_text,'
      'product_variants(sku,price_cents,sale_price_cents,stock_qty)';

  static const String _rpcSearchIds = 'search_products';

  Future<List<WmProductDto>> fetchTodaysPicks({
    int limit = 24,
    int offset = 0,
  }) async {
    final fetchCount = math.max(limit * 4, 72);

    final data = await _sb
        .from('products')
        .select(productLiteSelect)
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .range(0, fetchCount - 1);

    final mapped = _mapProductsList(data).where((p) => p.inStock).toList();
    final enriched = await _enrichProducts(mapped);

    final ranked = [...enriched]..sort(_compareHomeFeedProducts);

    final start = offset.clamp(0, ranked.length);
    final end = (start + limit).clamp(0, ranked.length);

    if (start >= end) return const <WmProductDto>[];
    return ranked.sublist(start, end);
  }

  int _compareHomeFeedProducts(WmProductDto a, WmProductDto b) {
    final as = _homeFeedScore(a);
    final bs = _homeFeedScore(b);

    final scoreCompare = bs.compareTo(as);
    if (scoreCompare != 0) return scoreCompare;

    final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final dateCompare = bDate.compareTo(aDate);
    if (dateCompare != 0) return dateCompare;

    return b.id.compareTo(a.id);
  }

  double _homeFeedScore(WmProductDto p) {
    double score = 0;

    final avg = p.avgRating ?? 0;
    final count = p.ratingCount ?? 0;
    final now = DateTime.now();
    final createdAt = p.createdAt;

    if (avg > 0) {
      score += avg * 18.0;
    }

    score += math.min(count.toDouble(), 30) * 2.2;

    if (createdAt != null) {
      final ageDays = now.difference(createdAt).inDays;
      if (ageDays <= 3) {
        score += 20;
      } else if (ageDays <= 7) {
        score += 14;
      } else if (ageDays <= 14) {
        score += 8;
      } else if (ageDays <= 30) {
        score += 4;
      }
    }

    if (_hasMeaningfulDiscount(p)) {
      score += 16;
    }

    final totalStock = p.variants.fold<int>(0, (sum, v) => sum + v.stockQty);
    if (totalStock >= 20) {
      score += 8;
    } else if (totalStock >= 8) {
      score += 5;
    } else if (totalStock >= 3) {
      score += 2;
    }

    if ((p.sellerId ?? '').trim().isNotEmpty) {
      score += 3;
    }

    if (p.isFrozen) {
      score += 2;
    }

    score += _stableJitter(p.id);

    return score;
  }

  bool _hasMeaningfulDiscount(WmProductDto p) {
    if (p.variants.isEmpty) return false;
    final v = p.variants.first;
    final sale = v.salePriceCents;
    final base = v.priceCents;

    if (sale == null || sale <= 0 || base <= 0) return false;
    if (sale >= base) return false;

    final diffPct = ((base - sale) / base) * 100;
    return diffPct >= 5;
  }

  double _stableJitter(String id) {
    if (id.isEmpty) return 0;
    final hash = id.codeUnits.fold<int>(0, (a, b) => a + b);
    return (hash % 17) / 10.0;
  }

  Future<List<WmProductDto>> _fetchHomeCandidates({
    int limit = 120,
  }) async {
    final data = await _sb
        .from('products')
        .select(productLiteSelect)
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .range(0, limit - 1);

    final mapped = _mapProductsList(data).where((p) => p.inStock).toList();
    return _enrichProducts(mapped);
  }

  Future<List<WmProductDto>> fetchTrendingNow({
    int limit = 12,
  }) async {
    final items = await _fetchHomeCandidates();

    final ranked = [...items]..sort((a, b) {
        final aScore = ((a.avgRating ?? 0) * 20) +
            math.min((a.ratingCount ?? 0).toDouble(), 50) * 2.8;
        final bScore = ((b.avgRating ?? 0) * 20) +
            math.min((b.ratingCount ?? 0).toDouble(), 50) * 2.8;
        return bScore.compareTo(aScore);
      });

    return ranked.take(limit).toList();
  }

  Future<List<WmProductDto>> fetchFreshFinds({
    int limit = 12,
  }) async {
    final items = await _fetchHomeCandidates();
    final now = DateTime.now();

    final ranked = [...items]..sort((a, b) {
        double score(WmProductDto p) {
          double s = 0;
          final createdAt = p.createdAt;
          if (createdAt != null) {
            final ageDays = now.difference(createdAt).inDays;
            if (ageDays <= 3) {
              s += 24;
            } else if (ageDays <= 7) {
              s += 16;
            } else if (ageDays <= 14) {
              s += 8;
            }
          }
          s += (p.avgRating ?? 0) * 8;
          s += math.min((p.ratingCount ?? 0).toDouble(), 10) * 1.4;
          if (_hasMeaningfulDiscount(p)) s += 8;
          return s;
        }

        return score(b).compareTo(score(a));
      });

    return ranked.take(limit).toList();
  }

  Future<List<WmProductDto>> fetchGreatValuePicks({
    int limit = 12,
  }) async {
    final items = await _fetchHomeCandidates();

    final discounted = items.where(_hasMeaningfulDiscount).toList();

    final ranked = [...discounted]..sort((a, b) {
        double score(WmProductDto p) {
          if (p.variants.isEmpty) return 0;
          final v = p.variants.first;
          final base = v.priceCents;
          final sale = v.salePriceCents ?? base;
          if (base <= 0 || sale >= base) return 0;

          final discountPct = ((base - sale) / base) * 100;
          return discountPct +
              ((p.avgRating ?? 0) * 4) +
              math.min((p.ratingCount ?? 0).toDouble(), 20);
        }

        return score(b).compareTo(score(a));
      });

    return ranked.take(limit).toList();
  }

  Future<List<WmProductDto>> fetchWeeklyDeals({
    int limit = 12,
  }) async {
    final data = await _sb
        .from('products')
        .select(productLiteSelect)
        .eq('is_active', true)
        .eq('is_weekly_deal', true)
        .order('created_at', ascending: false)
        .limit(limit * 3);

    final mapped = _mapProductsList(data).where((p) => p.inStock).toList();
    final enriched = await _enrichProducts(mapped);

    final activeDeals = enriched.where((p) {
      if (!p.isWeeklyDeal) return false;
      if (p.dealPriceCents == null || p.dealPriceCents! <= 0) return false;

      final now = DateTime.now();
      final startsOk = p.dealStartsAt == null || !now.isBefore(p.dealStartsAt!);
      final endsOk = p.dealEndsAt == null || !now.isAfter(p.dealEndsAt!);
      return startsOk && endsOk;
    }).toList();

    activeDeals.sort((a, b) {
      double score(WmProductDto p) {
        double s = 0;

        if (p.originalPriceCents > 0 &&
            p.displayPriceCents < p.originalPriceCents) {
          final discountPct = ((p.originalPriceCents - p.displayPriceCents) /
                  p.originalPriceCents) *
              100;
          s += discountPct;
        }

        s += (p.avgRating ?? 0) * 4;
        s += ((p.ratingCount ?? 0).clamp(0, 20)) * 1.0;
        return s;
      }

      return score(b).compareTo(score(a));
    });

    return activeDeals.take(limit).toList();
  }

  Future<List<WmProductDto>> fetchWeeklyEssentials({
    int limit = 12,
  }) async {
    final items = await _fetchHomeCandidates();

    final ranked = [...items]..sort((a, b) {
        double score(WmProductDto p) {
          double s = 0;

          final avg = p.avgRating ?? 0;
          final count = p.ratingCount ?? 0;
          final totalStock =
              p.variants.fold<int>(0, (sum, v) => sum + v.stockQty);

          s += avg * 12;
          s += math.min(count.toDouble(), 25) * 2.2;

          if (!_hasMeaningfulDiscount(p)) {
            s += 4;
          }

          if (!p.isFrozen) {
            s += 3;
          }

          if (totalStock >= 20) {
            s += 10;
          } else if (totalStock >= 10) {
            s += 6;
          } else if (totalStock >= 5) {
            s += 2;
          }

          final price = p.displayPriceCents;
          if (price > 0 && price <= 499) {
            s += 5;
          } else if (price <= 899) {
            s += 3;
          }

          s += _stableJitter(p.id);
          return s;
        }

        return score(b).compareTo(score(a));
      });

    return ranked.take(limit).toList();
  }

  Future<List<WmProductDto>> fetchFrozenFavourites({
    int limit = 12,
  }) async {
    final items = await _fetchHomeCandidates();

    final frozen = items.where((p) => p.isFrozen).toList();

    final ranked = [...frozen]..sort((a, b) {
        double score(WmProductDto p) {
          double s = 0;

          final avg = p.avgRating ?? 0;
          final count = p.ratingCount ?? 0;
          final totalStock =
              p.variants.fold<int>(0, (sum, v) => sum + v.stockQty);

          s += avg * 14;
          s += math.min(count.toDouble(), 30) * 2.0;

          if (_hasMeaningfulDiscount(p)) {
            s += 10;
          }

          if (totalStock >= 12) {
            s += 6;
          } else if (totalStock >= 5) {
            s += 3;
          }

          s += _stableJitter(p.id);
          return s;
        }

        return score(b).compareTo(score(a));
      });

    return ranked.take(limit).toList();
  }

  Future<List<WmProductDto>> fetchNewInStore({
    int limit = 12,
  }) async {
    final items = await _fetchHomeCandidates();
    final now = DateTime.now();

    final ranked = [...items]..sort((a, b) {
        double score(WmProductDto p) {
          double s = 0;
          final createdAt = p.createdAt;
          final avg = p.avgRating ?? 0;
          final count = p.ratingCount ?? 0;

          if (createdAt != null) {
            final ageDays = now.difference(createdAt).inDays;
            if (ageDays <= 3) {
              s += 28;
            } else if (ageDays <= 7) {
              s += 20;
            } else if (ageDays <= 14) {
              s += 10;
            } else if (ageDays <= 30) {
              s += 4;
            }
          }

          s += avg * 6;
          s += math.min(count.toDouble(), 8) * 1.2;

          if (_hasMeaningfulDiscount(p)) {
            s += 6;
          }

          s += _stableJitter(p.id);
          return s;
        }

        return score(b).compareTo(score(a));
      });

    return ranked.take(limit).toList();
  }

  Future<List<WmProductDto>> fetchPopularThisWeek({
    int limit = 12,
  }) async {
    final items = await _fetchHomeCandidates();

    final ranked = [...items]..sort((a, b) {
        double score(WmProductDto p) {
          double s = 0;

          final avg = p.avgRating ?? 0;
          final count = p.ratingCount ?? 0;
          final totalStock =
              p.variants.fold<int>(0, (sum, v) => sum + v.stockQty);

          s += avg * 16;
          s += math.min(count.toDouble(), 40) * 2.4;

          if (_hasMeaningfulDiscount(p)) {
            s += 6;
          }

          if (totalStock >= 15) {
            s += 5;
          } else if (totalStock >= 8) {
            s += 3;
          }

          final price = p.displayPriceCents;
          if (price > 0 && price <= 699) {
            s += 3;
          }

          s += _stableJitter(p.id);
          return s;
        }

        return score(b).compareTo(score(a));
      });

    return ranked.take(limit).toList();
  }

  Future<List<WmProductDto>> fetchBasketCompletionSuggestions({
    required List<String> basketProductIds,
    int limit = 6,
  }) async {
    final seedIds =
        basketProductIds.where((e) => e.trim().isNotEmpty).toSet().toList();

    if (seedIds.isEmpty) {
      final essentials = await fetchWeeklyEssentials(limit: limit);
      return essentials.take(limit).toList();
    }

    try {
      const eligibleOrderStatuses = <String>[
        'packed',
        'out_for_delivery',
        'delivered',
        'completed',
      ];

      final seedOrderItemsRaw = await _sb
          .from('order_items')
          .select('order_id, product_id')
          .inFilter('product_id', seedIds);

      final seedOrderItems =
          List<Map<String, dynamic>>.from(seedOrderItemsRaw as List);
      if (seedOrderItems.isEmpty) {
        return _fallbackBasketSuggestions(
          basketProductIds: seedIds,
          limit: limit,
        );
      }

      final seedOrderIds = seedOrderItems
          .map((e) => e['order_id']?.toString())
          .whereType<String>()
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();

      if (seedOrderIds.isEmpty) {
        return _fallbackBasketSuggestions(
          basketProductIds: seedIds,
          limit: limit,
        );
      }

      final ordersRaw = await _sb
          .from('orders')
          .select('id, created_at, status')
          .inFilter('id', seedOrderIds)
          .inFilter('status', eligibleOrderStatuses)
          .order('created_at', ascending: false)
          .limit(120);

      final orders = List<Map<String, dynamic>>.from(ordersRaw as List);
      if (orders.isEmpty) {
        return _fallbackBasketSuggestions(
          basketProductIds: seedIds,
          limit: limit,
        );
      }

      final validOrderIds = orders
          .map((e) => e['id']?.toString())
          .whereType<String>()
          .where((e) => e.isNotEmpty)
          .toList();

      if (validOrderIds.isEmpty) {
        return _fallbackBasketSuggestions(
          basketProductIds: seedIds,
          limit: limit,
        );
      }

      final createdAtByOrderId = <String, DateTime>{};
      for (final order in orders) {
        final id = order['id']?.toString();
        final createdAt = order['created_at']?.toString();
        if (id != null && createdAt != null) {
          final parsed = DateTime.tryParse(createdAt);
          if (parsed != null) {
            createdAtByOrderId[id] = parsed;
          }
        }
      }

      final relatedItemsRaw = await _sb
          .from('order_items')
          .select('order_id, product_id, qty')
          .inFilter('order_id', validOrderIds);

      final relatedItems = List<Map<String, dynamic>>.from(
        relatedItemsRaw as List,
      );
      if (relatedItems.isEmpty) {
        return _fallbackBasketSuggestions(
          basketProductIds: seedIds,
          limit: limit,
        );
      }

      final now = DateTime.now();
      final candidateScores = <String, double>{};
      final candidateOrderHits = <String, int>{};
      final candidateQty = <String, int>{};
      final seenOrderProductPairs = <String>{};

      for (final row in relatedItems) {
        final productId = row['product_id']?.toString();
        final orderId = row['order_id']?.toString();
        if (productId == null || productId.isEmpty || orderId == null) {
          continue;
        }

        if (seedIds.contains(productId)) continue;

        final qtyRaw = row['qty'];
        final qty = switch (qtyRaw) {
          int v => v,
          double v => v.round(),
          String v => int.tryParse(v) ?? 1,
          _ => 1,
        };

        final orderedAt = createdAtByOrderId[orderId];
        final daysAgo =
            orderedAt == null ? 999 : now.difference(orderedAt).inDays;

        final recencyBoost = daysAgo <= 14
            ? 2.4
            : daysAgo <= 30
                ? 1.8
                : daysAgo <= 60
                    ? 1.0
                    : 0.4;

        candidateScores[productId] = (candidateScores[productId] ?? 0) +
            1.8 +
            (qty * 0.18) +
            recencyBoost;

        final pairKey = '$orderId::$productId';
        if (seenOrderProductPairs.add(pairKey)) {
          candidateOrderHits[productId] =
              (candidateOrderHits[productId] ?? 0) + 1;
        }

        candidateQty[productId] = (candidateQty[productId] ?? 0) + qty;
      }

      if (candidateScores.isEmpty) {
        return _fallbackBasketSuggestions(
          basketProductIds: seedIds,
          limit: limit,
        );
      }

      final rankedIds = candidateScores.keys.toList()
        ..sort((a, b) {
          final scoreCmp =
              (candidateScores[b] ?? 0).compareTo(candidateScores[a] ?? 0);
          if (scoreCmp != 0) return scoreCmp;

          final hitCmp = (candidateOrderHits[b] ?? 0)
              .compareTo(candidateOrderHits[a] ?? 0);
          if (hitCmp != 0) return hitCmp;

          return (candidateQty[b] ?? 0).compareTo(candidateQty[a] ?? 0);
        });

      final candidateIds = rankedIds.take(limit * 3).toList();
      if (candidateIds.isEmpty) {
        return _fallbackBasketSuggestions(
          basketProductIds: seedIds,
          limit: limit,
        );
      }

      final data = await _sb
          .from('products')
          .select(productLiteSelect)
          .eq('is_active', true)
          .inFilter('id', candidateIds);

      final mapped =
          _mapProductsList(data).where((p) => p.isActive && p.inStock).toList();
      final enriched = await _enrichProducts(mapped);

      final byId = <String, WmProductDto>{
        for (final p in enriched) p.id: p,
      };

      final result = <WmProductDto>[];
      for (final id in candidateIds) {
        final p = byId[id];
        if (p == null) continue;
        result.add(p);
        if (result.length >= limit) break;
      }

      if (result.length >= 3) {
        return result;
      }

      final fallback = await _fallbackBasketSuggestions(
        basketProductIds: seedIds,
        limit: limit,
      );

      final merged = <WmProductDto>[
        ...result,
        ...fallback.where((f) => result.every((r) => r.id != f.id)),
      ];

      return merged.take(limit).toList();
    } catch (_) {
      return _fallbackBasketSuggestions(
        basketProductIds: seedIds,
        limit: limit,
      );
    }
  }

  Future<List<WmProductDto>> _fallbackBasketSuggestions({
    required List<String> basketProductIds,
    required int limit,
  }) async {
    final excluded = basketProductIds.toSet();

    final essentials = await fetchWeeklyEssentials(limit: limit * 2);
    final popular = await fetchPopularThisWeek(limit: limit * 2);
    final frozen = await fetchFrozenFavourites(limit: limit * 2);

    final merged = <WmProductDto>[
      ...essentials,
      ...popular.where((p) => essentials.every((e) => e.id != p.id)),
      ...frozen.where(
        (p) =>
            essentials.every((e) => e.id != p.id) &&
            popular.every((e) => e.id != p.id),
      ),
    ];

    return merged.where((p) => !excluded.contains(p.id)).take(limit).toList();
  }

  Future<List<WmProductDto>> fetchBuyItAgain({
    int limit = 12,
  }) async {
    try {
      final productStats = await _fetchRepeatStatsForCurrentUser();
      if (productStats.isEmpty) {
        return const <WmProductDto>[];
      }

      final rankedIds = productStats.entries.toList()
        ..sort((a, b) {
          final scoreCmp = b.value.score.compareTo(a.value.score);
          if (scoreCmp != 0) return scoreCmp;

          final countCmp = b.value.orderCount.compareTo(a.value.orderCount);
          if (countCmp != 0) return countCmp;

          final aTime = a.value.lastOrderedAt ?? DateTime(2000);
          final bTime = b.value.lastOrderedAt ?? DateTime(2000);
          return bTime.compareTo(aTime);
        });

      final candidateIds = rankedIds.map((e) => e.key).take(limit * 3).toList();
      if (candidateIds.isEmpty) {
        return const <WmProductDto>[];
      }

      final result = await _fetchRankedRepeatProducts(
        candidateIds,
        productStats: productStats,
        limit: limit,
      );

      return result.length >= 3 ? result : const <WmProductDto>[];
    } catch (_) {
      return const <WmProductDto>[];
    }
  }

  Future<List<WmProductDto>> fetchRunningLow({
    int limit = 10,
  }) async {
    try {
      final productStats = await _fetchRepeatStatsForCurrentUser();
      if (productStats.length < 4) {
        return const <WmProductDto>[];
      }

      final now = DateTime.now();
      final rankedIds = productStats.entries.where((entry) {
        final stat = entry.value;
        if (stat.orderCount < 2 && stat.totalQty < 3) return false;

        final lastOrderedAt = stat.lastOrderedAt;
        final firstOrderedAt = stat.firstOrderedAt ?? lastOrderedAt;
        if (lastOrderedAt == null || firstOrderedAt == null) return false;

        final daysSinceLast = math.max(0, now.difference(lastOrderedAt).inDays);
        if (daysSinceLast < 5) return false;

        final spanDays =
            math.max(1, lastOrderedAt.difference(firstOrderedAt).inDays);
        final cadenceDays = stat.orderCount > 1
            ? math.max(7, (spanDays / (stat.orderCount - 1)).round())
            : 14;
        final refillPressure = daysSinceLast / cadenceDays;

        return refillPressure >= 0.65;
      }).toList()
        ..sort((a, b) {
          double score(_RepeatStats stat) {
            final lastOrderedAt = stat.lastOrderedAt ?? DateTime(2000);
            final firstOrderedAt = stat.firstOrderedAt ?? lastOrderedAt;
            final daysSinceLast =
                math.max(0, now.difference(lastOrderedAt).inDays);
            final spanDays =
                math.max(1, lastOrderedAt.difference(firstOrderedAt).inDays);
            final cadenceDays = stat.orderCount > 1
                ? math.max(7, (spanDays / (stat.orderCount - 1)).round())
                : 14;
            final refillPressure = daysSinceLast / cadenceDays;

            return (refillPressure * 8.0) +
                (stat.orderCount * 1.8) +
                (stat.totalQty * 0.35) +
                _recencyScore(daysSinceLast);
          }

          return score(b.value).compareTo(score(a.value));
        });

      final candidateIds = rankedIds.map((e) => e.key).take(limit * 3).toList();
      if (candidateIds.isEmpty) {
        return const <WmProductDto>[];
      }

      final result = await _fetchRankedRepeatProducts(
        candidateIds,
        productStats: productStats,
        limit: limit,
      );

      return result.length >= 4 ? result : const <WmProductDto>[];
    } catch (_) {
      return const <WmProductDto>[];
    }
  }

  Future<Map<String, _RepeatStats>> _fetchRepeatStatsForCurrentUser() async {
    final user = _sb.auth.currentUser;
    if (user == null) return const <String, _RepeatStats>{};

    const ordersUserColumn = 'user_id';
    const eligibleOrderStatuses = <String>[
      'packed',
      'out_for_delivery',
      'delivered',
      'completed',
    ];

    final ordersRaw = await _sb
        .from('orders')
        .select('id, created_at')
        .eq(ordersUserColumn, user.id)
        .inFilter('status', eligibleOrderStatuses)
        .order('created_at', ascending: false)
        .limit(40);

    final orders = List<Map<String, dynamic>>.from(ordersRaw as List);
    if (orders.isEmpty) return const <String, _RepeatStats>{};

    final orderIds = orders
        .map((o) => o['id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList();
    if (orderIds.isEmpty) return const <String, _RepeatStats>{};

    final createdAtByOrderId = <String, DateTime>{};
    for (final order in orders) {
      final id = order['id']?.toString();
      final createdAt = order['created_at']?.toString();
      if (id != null && createdAt != null) {
        createdAtByOrderId[id] = DateTime.tryParse(createdAt) ?? DateTime(2000);
      }
    }

    final itemsRaw = await _sb
        .from('order_items')
        .select('order_id, product_id, qty')
        .inFilter('order_id', orderIds);

    final items = List<Map<String, dynamic>>.from(itemsRaw as List);
    if (items.isEmpty) return const <String, _RepeatStats>{};

    final now = DateTime.now();
    final productStats = <String, _RepeatStats>{};

    for (final row in items) {
      final productId = row['product_id']?.toString();
      final orderId = row['order_id']?.toString();
      if (productId == null || productId.isEmpty || orderId == null) continue;

      final qtyRaw = row['qty'];
      final qty = switch (qtyRaw) {
        int v => v,
        double v => v.round(),
        String v => int.tryParse(v) ?? 1,
        _ => 1,
      };

      final orderedAt = createdAtByOrderId[orderId] ?? DateTime(2000);
      final daysAgo = math.max(0, now.difference(orderedAt).inDays);

      final stat = productStats.putIfAbsent(productId, _RepeatStats.new);
      stat.orderCount += 1;
      stat.totalQty += qty;

      if (stat.firstOrderedAt == null ||
          orderedAt.isBefore(stat.firstOrderedAt!)) {
        stat.firstOrderedAt = orderedAt;
      }

      if (stat.lastOrderedAt == null ||
          orderedAt.isAfter(stat.lastOrderedAt!)) {
        stat.lastOrderedAt = orderedAt;
        stat.lastQty = qty;
      }

      final recencyBoost = _recencyScore(daysAgo);
      stat.score += 2.4 + (qty * 0.45) + recencyBoost;
    }

    return productStats;
  }

  Future<List<WmProductDto>> _fetchRankedRepeatProducts(
    List<String> candidateIds, {
    required Map<String, _RepeatStats> productStats,
    required int limit,
  }) async {
    if (candidateIds.isEmpty) return const <WmProductDto>[];

    final data = await _sb
        .from('products')
        .select(productLiteSelect)
        .eq('is_active', true)
        .inFilter('id', candidateIds);

    final mapped =
        _mapProductsList(data).where((p) => p.isActive && p.inStock).toList();
    final enriched = await _enrichProducts(mapped);

    final byId = <String, WmProductDto>{
      for (final product in enriched) product.id: product,
    };

    final result = <WmProductDto>[];
    for (final id in candidateIds) {
      final product = byId[id];
      if (product == null) continue;

      result.add(
        product.copyWith(
          rememberedQty: productStats[id]?.lastQty,
        ),
      );
      if (result.length >= limit) break;
    }

    return result;
  }

  Future<List<WmProductDto>> _buildColdStartBasket({
    required int limit,
  }) async {
    final results = await Future.wait<List<WmProductDto>>([
      fetchWeeklyEssentials(limit: limit),
      fetchPopularThisWeek(limit: limit),
    ]);

    final essentials = results[0];
    final popular = results[1];

    final merged = <WmProductDto>[
      ...essentials,
      ...popular.where((p) => essentials.every((e) => e.id != p.id)),
    ];

    return merged.take(limit).toList();
  }

  static double _recencyScore(int daysAgo) {
    if (daysAgo <= 7) return 3.2;
    if (daysAgo <= 14) return 2.4;
    if (daysAgo <= 30) return 1.6;
    if (daysAgo <= 60) return 0.9;
    if (daysAgo <= 90) return 0.45;
    return 0.1;
  }

  Future<List<WmProductDto>> fetchFeedCursor({
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
        .eq('is_active', true)
        .inFilter('id', ids);

    final byId = <String, WmProductDto>{};
    final enriched = await _enrichProducts(_mapProductsList(data).toList());
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
        priceCents: p.originalPriceCents,
        salePriceCents: p.displayPriceCents < p.originalPriceCents
            ? p.displayPriceCents
            : null,
        avgRating: p.avgRating,
        ratingCount: p.ratingCount,
        categoryName: category?['name'],
        categorySlug: category?['slug'],
        isFrozen: p.isFrozen,
        barcode: p.barcode,
        sellerId: p.sellerId,
        sellerBasePriceCents: p.sellerBasePriceCents,
        isWeeklyDeal: p.isWeeklyDeal,
        dealBadgeText: p.dealBadgeText,
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
        .eq('is_active', true)
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
    final data = await _sb
        .from('products')
        .select(productSelect)
        .eq('id', id)
        .eq('is_active', true)
        .limit(1);

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

    final basePrice = _extractFirstPrice(row, 'price_cents');
    final variantSalePrice = _extractFirstPrice(row, 'sale_price_cents');

    final isWeeklyDeal = (row['is_weekly_deal'] as bool?) ?? false;
    final dealPriceCents = (row['deal_price_cents'] as num?)?.toInt();
    final dealStartsAt = _parseDate(row['deal_starts_at']);
    final dealEndsAt = _parseDate(row['deal_ends_at']);

    final now = DateTime.now();
    final dealActive = isWeeklyDeal &&
        dealPriceCents != null &&
        dealPriceCents > 0 &&
        (dealStartsAt == null || !now.isBefore(dealStartsAt)) &&
        (dealEndsAt == null || !now.isAfter(dealEndsAt));

    final effectiveSalePrice = dealActive ? dealPriceCents : variantSalePrice;

    return ProductModel(
      id: productId,
      name: (row['name'] ?? '') as String,
      brandName: brandName,
      image: imageUrl,
      priceCents: basePrice,
      salePriceCents: effectiveSalePrice,
      avgRating: avgRating,
      ratingCount: ratingCount,
      isFrozen: (row['is_frozen'] as bool?) ?? false,
      barcode: row['barcode']?.toString(),
      sellerId: row['seller_id']?.toString(),
      sellerBasePriceCents: (row['seller_base_price_cents'] as num?)?.toInt(),
      isWeeklyDeal: isWeeklyDeal,
      dealBadgeText: row['deal_badge_text']?.toString(),
    );
  }

  Future<List<ProductModel>> fetchProductModelsBySubcategorySlug(
    String subcategorySlug, {
    int limit = 100,
  }) async {
    final data = await _sb
        .from('v_products_unified')
        .select(
          'product_id,product_name,brand_name,price_cents,sale_price_cents,stock_qty,seller_id,seller_base_price_cents',
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
        sellerId: m['seller_id']?.toString(),
        sellerBasePriceCents: (m['seller_base_price_cents'] as num?)?.toInt(),
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
    List<WmProductDto> products,
  ) async {
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
    Set<String> brandIds,
  ) async {
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
        barcode: row['barcode']?.toString(),
        isFrozen: (row['is_frozen'] as bool?) ?? false,
        images: ((row['images'] as List<dynamic>?) ?? const [])
            .map((e) => e?.toString() ?? '')
            .where((e) => e.isNotEmpty)
            .toList(),
        isActive: (row['is_active'] as bool?) ?? true,
        variants: variants,
        createdAt: createdAt,
        sellerId: row['seller_id']?.toString(),
        sellerBasePriceCents: (row['seller_base_price_cents'] as num?)?.toInt(),
        isWeeklyDeal: (row['is_weekly_deal'] as bool?) ?? false,
        dealPriceCents: (row['deal_price_cents'] as num?)?.toInt(),
        dealStartsAt: _parseDate(row['deal_starts_at']),
        dealEndsAt: _parseDate(row['deal_ends_at']),
        dealBadgeText: row['deal_badge_text']?.toString(),
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

  /// 🔥 RELATED PRODUCTS - Category based fetching
  Future<List<ProductModel>> fetchProductsByCategory(
    String? categorySlug, {
    int limit = 12,
  }) async {
    if (categorySlug == null || categorySlug.trim().isEmpty) {
      return const <ProductModel>[];
    }

    try {
      final data = await _sb
          .from('products')
          .select('$productLiteSelect,categories!inner(id,name,slug)')
          .eq('categories.slug', categorySlug)
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .order('id', ascending: false)
          .limit(limit);

      final list = _mapProductsList(data);
      if (list.isEmpty) return const <ProductModel>[];

      final enriched = await _enrichProducts(list);

      final categoryIds = enriched
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

      return enriched.map((p) {
        final category = categoryMap[p.categoryId];
        return ProductModel(
          id: p.id,
          name: p.name,
          brandName: p.brandName,
          image: p.firstImageUrl,
          priceCents: p.originalPriceCents,
          salePriceCents: p.displayPriceCents < p.originalPriceCents
              ? p.displayPriceCents
              : null,
          avgRating: p.avgRating,
          ratingCount: p.ratingCount,
          categoryName: category?['name'],
          categorySlug: category?['slug'],
          isFrozen: p.isFrozen,
          barcode: p.barcode,
          sellerId: p.sellerId,
          sellerBasePriceCents: p.sellerBasePriceCents,
          isWeeklyDeal: p.isWeeklyDeal,
          dealBadgeText: p.dealBadgeText,
        );
      }).toList();
    } catch (_) {
      return const <ProductModel>[];
    }
  }

  /// 🔥 COMBO ENGINE - Rule-Based Product Suggestions
  Future<List<ProductModel>> fetchComboProducts(ProductModel product) async {
    final name = product.name.toLowerCase();

    /// Rule-based combo suggestions
    if (name.contains('rice')) {
      return fetchByKeywords(['masala', 'pickle', 'dal']);
    }

    if (name.contains('tea')) {
      return fetchByKeywords(['snacks', 'biscuits']);
    }

    if (name.contains('frozen')) {
      return fetchByKeywords(['sauce', 'ready']);
    }

    if (name.contains('masala')) {
      return fetchByKeywords(['rice', 'oil']);
    }

    return const <ProductModel>[];
  }

  /// Helper: Fetch products by multiple keywords
  Future<List<ProductModel>> fetchByKeywords(List<String> keywords) async {
    final results = <ProductModel>[];
    final seen = <String>{};

    for (final keyword in keywords) {
      try {
        final items = await fetchProductModelsByQuery(keyword, limit: 4);
        for (final item in items) {
          if (!seen.contains(item.id)) {
            results.add(item);
            seen.add(item.id);
          }
        }
      } catch (_) {
        // Skip on error
      }
    }

    return results;
  }
}

class _RepeatStats {
  int orderCount = 0;
  int totalQty = 0;
  int lastQty = 1;
  double score = 0;
  DateTime? firstOrderedAt;
  DateTime? lastOrderedAt;
}
