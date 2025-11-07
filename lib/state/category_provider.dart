// lib/state/category_provider.dart
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CategoryModel {
  final String id;
  final String name;
  final String slug;
  final String? icon;
  final int sortOrder;
  final bool isActive;

  CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
    required this.sortOrder,
    required this.isActive,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> m) => CategoryModel(
        id: m['id'] as String,
        name: m['name'] as String,
        slug: m['slug'] as String,
        icon: m['icon'] as String?,
        sortOrder: (m['sort_order'] as int?) ?? 0,
        isActive: (m['is_active'] as bool?) ?? true,
      );
}

final categoriesProvider = FutureProvider.autoDispose<List<CategoryModel>>(
  (ref) async {
    final sb = Supabase.instance.client;
    final res = await sb
        .from('categories')
        .select('id,name,slug,icon,sort_order,is_active')
        .eq('is_active', true)
        .order('sort_order');
    return (res as List)
        .map((e) => CategoryModel.fromMap(e as Map<String, dynamic>))
        .toList();
  },
);
