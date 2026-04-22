import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:western_malabar/features/admin/models/admin_product_edit_model.dart';

class AdminProductsService {
  final SupabaseClient supabase;

  AdminProductsService(this.supabase);

  Future<List<AdminProductEditModel>> fetchProducts() async {
    final rows = await supabase.from('products').select('''
          id,
          name,
          slug,
          brand_id,
          category_id,
          images,
          description,
          is_active,
          stock_qty,
          is_available,
          available_qty,
          is_frozen,
          barcode,
          seller_base_price_cents,
          is_weekly_deal,
          deal_price_cents,
          deal_starts_at,
          deal_ends_at,
          deal_badge_text,
          product_variants(id, price_cents, sale_price_cents, stock_qty)
        ''').order('name', ascending: true);

    return (rows as List)
        .map((e) => AdminProductEditModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<AdminProductEditModel> fetchProductById(String productId) async {
    final row = await supabase.from('products').select('''
          id,
          name,
          slug,
          brand_id,
          category_id,
          images,
          description,
          is_active,
          stock_qty,
          is_available,
          available_qty,
          is_frozen,
          barcode,
          seller_base_price_cents,
          is_weekly_deal,
          deal_price_cents,
          deal_starts_at,
          deal_ends_at,
          deal_badge_text,
          product_variants(id, price_cents, sale_price_cents, stock_qty)
        ''').eq('id', productId).single();

    return AdminProductEditModel.fromMap(row);
  }

  Future<void> setProductActiveStatus({
    required String productId,
    required bool isActive,
  }) async {
    await supabase
        .from('products')
        .update({'is_active': isActive}).eq('id', productId);
  }

  Future<List<AdminBrandOption>> fetchBrands() async {
    final rows = await supabase
        .from('brands')
        .select('id, name, slug')
        .eq('is_active', true)
        .order('name', ascending: true);

    return (rows as List)
        .map((e) => AdminBrandOption.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AdminCategoryOption>> fetchCategories() async {
    final rows = await supabase
        .from('categories')
        .select('id, name, slug, parent_id')
        .eq('is_active', true)
        .order('sort_order', ascending: true)
        .order('name', ascending: true);

    return (rows as List)
        .map((e) => AdminCategoryOption.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> uploadProductImage(File file) async {
    final compressedFile = await _compressProductImage(file);

    final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final storagePath = fileName;

    await supabase.storage.from('product-images').upload(
          storagePath,
          compressedFile,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: false,
          ),
        );

    return supabase.storage.from('product-images').getPublicUrl(storagePath);
  }

  Future<File> _compressProductImage(File file) async {
    final tempDir = await getTemporaryDirectory();
    final targetPath = p.join(
      tempDir.path,
      'wm_product_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 80,
      minWidth: 1400,
      minHeight: 1400,
      format: CompressFormat.jpeg,
    );

    if (result == null) {
      return file;
    }

    return File(result.path);
  }

  Future<void> updateProduct({
    required String productId,
    required String name,
    required String slug,
    String? brandId,
    String? categoryId,
    required List<String> images,
    String? description,
    required bool isActive,
    required int? stockQty,
    required bool isFrozen,
    String? barcode,
    required int? priceCents,
    required int? salePriceCents,
    required bool isWeeklyDeal,
    int? dealPriceCents,
    DateTime? dealStartsAt,
    DateTime? dealEndsAt,
    String? dealBadgeText,
  }) async {
    final cleanedDescription =
        (description == null || description.trim().isEmpty)
            ? null
            : description.trim();
    final cleanedBarcode =
        (barcode == null || barcode.trim().isEmpty) ? null : barcode.trim();
    final cleanedDealBadgeText = !isWeeklyDeal
        ? null
        : (dealBadgeText == null || dealBadgeText.trim().isEmpty)
            ? 'Weekly Deal'
            : dealBadgeText.trim();

    await supabase.from('products').update({
      'name': name,
      'slug': slug,
      'brand_id': (brandId == null || brandId.isEmpty) ? null : brandId,
      'category_id':
          (categoryId == null || categoryId.isEmpty) ? null : categoryId,
      'images': images,
      'description': cleanedDescription,
      'is_active': isActive,
      'stock_qty': stockQty,
      'is_frozen': isFrozen,
      'barcode': cleanedBarcode,
      'seller_base_price_cents': priceCents,
      'is_weekly_deal': isWeeklyDeal,
      'deal_price_cents': isWeeklyDeal ? dealPriceCents : null,
      'deal_starts_at': isWeeklyDeal ? dealStartsAt?.toIso8601String() : null,
      'deal_ends_at': isWeeklyDeal ? dealEndsAt?.toIso8601String() : null,
      'deal_badge_text': cleanedDealBadgeText,
    }).eq('id', productId);

    await supabase.from('product_variants').update({
      'price_cents': priceCents,
      'sale_price_cents': salePriceCents,
    }).eq('product_id', productId);
  }

  String buildSlugFromName(String name) {
    return name
        .trim()
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-');
  }
}
