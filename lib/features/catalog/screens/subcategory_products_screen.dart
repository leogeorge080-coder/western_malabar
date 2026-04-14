import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:western_malabar/features/catalog/models/product_model.dart';
import 'package:western_malabar/features/catalog/screens/shared_product_listing_screen.dart';
import 'package:western_malabar/features/catalog/services/product_service.dart';

class SubcategoryProductsScreen extends ConsumerStatefulWidget {
  const SubcategoryProductsScreen({
    super.key,
    required this.title,
    required this.subcategorySlug,
  });

  final String title;
  final String subcategorySlug;

  @override
  ConsumerState<SubcategoryProductsScreen> createState() =>
      _SubcategoryProductsScreenState();
}

class _SubcategoryProductsScreenState
    extends ConsumerState<SubcategoryProductsScreen> {
  final _svc = ProductService();

  bool _loading = true;
  List<ProductModel> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() => _loading = true);
    }

    try {
      final data = await _svc.fetchProductModelsBySubcategorySlug(
        widget.subcategorySlug,
      );

      if (!mounted) return;

      setState(() {
        _items = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load products: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SharedProductListingScreen(
      title: widget.title,
      items: _items,
      isLoading: _loading,
      onRefresh: _load,
      emptyTitle: 'No products found',
      emptySubtitle: 'This subcategory does not have visible products yet.',
    );
  }
}
