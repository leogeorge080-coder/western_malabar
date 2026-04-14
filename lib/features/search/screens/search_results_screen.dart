// lib/screens/customer/search_results_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:western_malabar/features/catalog/services/product_service.dart';
import 'package:western_malabar/shared/utils/debounce.dart';
import 'package:western_malabar/shared/widgets/product_skeleton.dart';

const _wmBg = Color(0xFFF6F7F8);
const _wmSurface = Colors.white;
const _wmSurfaceSoft = Color(0xFFF9FAFB);
const _wmBorder = Color(0xFFE5E7EB);

const _wmTextStrong = Color(0xFF111827);
const _wmTextSoft = Color(0xFF6B7280);
const _wmTextMuted = Color(0xFF9CA3AF);

const _wmPrimary = Color(0xFF22252B);
const _wmSuccess = Color(0xFF1E8E3E);
const _wmDanger = Color(0xFFD93025);

/// ─────────────────────────────────────────────────────────────
/// Search Results Screen – Neutral black / ash / white version
///
/// Features:
/// ✅ Debounced search (300ms)
/// ✅ Skeleton loading
/// ✅ RPC-based search
/// ✅ Stable layout
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
  final FocusNode _focusNode = FocusNode();

  List<WmProductDto> _results = [];
  bool _isSearching = false;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _debouncer = SearchDebouncer(delay: const Duration(milliseconds: 300));
    _productService = ProductService();
    _searchController.text = widget.initialQuery;

    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });

    if (widget.initialQuery.isNotEmpty) {
      _lastQuery = widget.initialQuery;
      Future.microtask(() => _performSearch(widget.initialQuery));
    }
  }

  void _onSearchChanged(String query) {
    setState(() => _lastQuery = query);

    if (query.trim().length < 2) {
      setState(() {
        _results.clear();
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    _debouncer.run(() => _performSearch(query));
  }

  Future<void> _performSearch(String query) async {
    try {
      final results = await _productService.searchProductsRpc(query.trim());

      if (!mounted) return;

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
        SnackBar(
          content: Text('Search failed: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _debouncer.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = _focusNode.hasFocus;

    return Scaffold(
      backgroundColor: _wmBg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: _wmBg,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: Row(
                children: [
                  Material(
                    color: _wmSurface,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: _wmSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _wmBorder),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: _wmPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      height: 46,
                      decoration: BoxDecoration(
                        color: _wmSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isFocused ? _wmPrimary : _wmBorder,
                          width: isFocused ? 1.3 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isFocused
                                ? const Color(0x12000000)
                                : const Color(0x0A000000),
                            blurRadius: isFocused ? 14 : 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.search_rounded,
                            color: _wmPrimary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _focusNode,
                              onChanged: _onSearchChanged,
                              autofocus: true,
                              textInputAction: TextInputAction.search,
                              decoration: const InputDecoration(
                                hintText: 'Search products…',
                                isCollapsed: true,
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                                hintStyle: TextStyle(
                                  color: _wmTextMuted,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _wmTextStrong,
                              ),
                            ),
                          ),
                          if (_searchController.text.trim().isNotEmpty)
                            IconButton(
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                                _focusNode.requestFocus();
                              },
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 18,
                              ),
                              color: _wmTextSoft,
                              splashRadius: 18,
                            )
                          else
                            const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isSearching) {
      return _buildLoadingSkeleton();
    }

    if (_results.isEmpty && _lastQuery.trim().isNotEmpty) {
      return _buildEmptyState();
    }

    if (_results.isNotEmpty) {
      return _buildResults();
    }

    return _buildInitialState();
  }

  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: const [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Searching products…',
                style: TextStyle(
                  color: _wmTextSoft,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: ProductGridSkeleton(
              itemCount: 6,
              crossAxisCount: 2,
              childAspectRatio: 0.62,
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildResults() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.62,
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _wmSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _wmBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.search_off_rounded,
                size: 56,
                color: _wmTextMuted,
              ),
              const SizedBox(height: 14),
              const Text(
                'No products found',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: _wmTextStrong,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try searching for different keywords or a simpler product name.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: _wmTextSoft,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitialState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_rounded,
              size: 56,
              color: _wmTextMuted,
            ),
            SizedBox(height: 14),
            Text(
              'Start typing to search',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: _wmTextStrong,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Search by product name, brand, or grocery keyword.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: _wmTextSoft,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Result card
class _ProductResultCard extends StatelessWidget {
  final WmProductDto product;

  const _ProductResultCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final price = product.displayPriceCents / 100.0;
    final brand = (product.brandName ?? '').trim();
    final hasStock = product.variants.isNotEmpty;
    final stockQty = hasStock ? product.variants.first.stockQty : 0;

    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigate to: ${product.name}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: _wmSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _wmBorder),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: Container(
                  width: double.infinity,
                  color: _wmSurfaceSoft,
                  child: product.firstImageUrl != null
                      ? Image.network(
                          product.firstImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: _wmTextMuted,
                              size: 28,
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: _wmTextMuted,
                            size: 28,
                          ),
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (brand.isNotEmpty) ...[
                    Text(
                      brand,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.8,
                        fontWeight: FontWeight.w700,
                        color: _wmTextSoft,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                      color: _wmTextStrong,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '£${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: _wmPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (hasStock)
                    Text(
                      stockQty > 0 ? '$stockQty in stock' : 'Out of stock',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: stockQty > 0 ? _wmSuccess : _wmDanger,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
