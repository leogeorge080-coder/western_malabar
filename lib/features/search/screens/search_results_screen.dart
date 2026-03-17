// lib/screens/customer/search_results_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:western_malabar/features/catalog/services/product_service.dart';
import 'package:western_malabar/shared/utils/debounce.dart';
import 'package:western_malabar/shared/widgets/product_skeleton.dart';

/// ─────────────────────────────────────────────────────────────
/// Search Results Screen – Complete Reference Implementation
///
/// Features:
/// ✅ Debounced search (300ms delay)
/// ✅ Skeleton loading (not spinner)
/// ✅ RPC-based search (indexed, fast)
/// ✅ Stable layout (no collapse during load)
/// ✅ Empty state handling
/// ─────────────────────────────────────────────────────────────

class SearchResultsScreen extends StatefulWidget {
  final String initialQuery;

  const SearchResultsScreen({
    super.key,
    this.initialQuery = '',
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late final SearchDebouncer _debouncer;
  late final ProductService _productService;
  final TextEditingController _searchController = TextEditingController();

  List<WmProductDto> _results = [];
  bool _isSearching = false;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _debouncer = SearchDebouncer(delay: const Duration(milliseconds: 300));
    _productService = ProductService();
    _searchController.text = widget.initialQuery;

    if (widget.initialQuery.isNotEmpty) {
      _lastQuery = widget.initialQuery;
      Future.microtask(() => _performSearch(widget.initialQuery));
    }
  }

  void _onSearchChanged(String query) {
    setState(() => _lastQuery = query);

    // Don't search for < 2 chars
    if (query.trim().length < 2) {
      setState(() {
        _results.clear();
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    // Debounce the search (fires 300ms after user stops typing)
    _debouncer.run(() => _performSearch(query));
  }

  Future<void> _performSearch(String query) async {
    try {
      final results = await _productService.searchProductsRpc(query.trim());

      if (!mounted) return;

      // Only update if this is still the latest query
      if (query.trim() == _lastQuery.trim()) {
        setState(() {
          _results = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSearching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search failed: $e')),
      );
    }
  }

  @override
  void dispose() {
    _debouncer.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search products…',
            isCollapsed: true,
            contentPadding: EdgeInsets.zero,
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey.shade400),
          ),
          style: const TextStyle(fontSize: 16),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Show skeleton while loading
    if (_isSearching) {
      return _buildLoadingSkeleton();
    }

    // Show empty state
    if (_results.isEmpty && _lastQuery.trim().isNotEmpty) {
      return _buildEmptyState();
    }

    // Show results
    if (_results.isNotEmpty) {
      return _buildResults();
    }

    // Show initial state (no query yet)
    return _buildInitialState();
  }

  /// Skeleton loader – stable layout, no collapse
  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Searching…',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          ProductGridSkeleton(
            itemCount: 6,
            crossAxisCount: 2,
            childAspectRatio: 0.65,
          ),
        ],
      ),
    );
  }

  /// Results grid
  Widget _buildResults() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final product = _results[index];
        return _ProductResultCard(product: product);
      },
    );
  }

  /// Empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No products found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching for different keywords',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  /// Initial state (no query typed yet)
  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Start typing to search',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Result card for search results
class _ProductResultCard extends StatelessWidget {
  final WmProductDto product;

  const _ProductResultCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final price = product.displayPriceCents / 100.0;
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to product detail
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Navigate to: ${product.name}')),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              image: product.firstImageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(product.firstImageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: product.firstImageUrl == null
                ? Icon(
                    Icons.image_not_supported,
                    color: Colors.grey.shade400,
                  )
                : null,
          ),
          const SizedBox(height: 12),

          // Name (truncated, max 2 lines)
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),

          // Price
          Text(
            '£${price.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5A2D82),
            ),
          ),

          // Stock indicator
          const SizedBox(height: 4),
          if (product.variants.isNotEmpty)
            Text(
              '${product.variants.first.stockQty} in stock',
              style: TextStyle(
                fontSize: 12,
                color: product.variants.first.stockQty > 0
                    ? Colors.green.shade600
                    : Colors.red.shade600,
              ),
            ),
        ],
      ),
    );
  }
}




