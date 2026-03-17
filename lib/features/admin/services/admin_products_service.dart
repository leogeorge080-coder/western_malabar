import 'dart:io';

import 'package:image_picker/image_picker.dart';
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
          is_frozen,
          barcode
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
          is_frozen,
          barcode
        ''').eq('id', productId).single();

    return AdminProductEditModel.fromMap(row);
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
    final ext = file.path.split('.').last.toLowerCase();
    final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final path = 'product-images/$fileName';

    await supabase.storage.from('product-images').upload(path, file);

    return supabase.storage.from('product-images').getPublicUrl(path);
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
    required bool isFrozen,
    String? barcode,
  }) async {
    await supabase.from('products').update({
      'name': name,
      'slug': slug,
      'brand_id': (brandId == null || brandId.isEmpty) ? null : brandId,
      'category_id':
          (categoryId == null || categoryId.isEmpty) ? null : categoryId,
      'images': images,
      'description': (description ?? '').trim().isEmpty ? null : description,
      'is_active': isActive,
      'is_frozen': isFrozen,
      'barcode': (barcode ?? '').trim().isEmpty ? null : barcode!.trim(),
    }).eq('id', productId);
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




