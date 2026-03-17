import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:western_malabar/models/product_model.dart';
import 'package:western_malabar/services/product_service.dart';
import 'package:western_malabar/theme/wm_gradients.dart';
import 'package:western_malabar/widgets/product_card.dart';
import 'package:western_malabar/widgets/cart/sticky_cart_bar.dart';

class GlobalProductSearchScreen extends ConsumerStatefulWidget {
  const GlobalProductSearchScreen({
    super.key,
    this.initialQuery = '',
    this.hintText = 'Search all products…',
  });

  final String initialQuery;
  final String hintText;

  @override
  ConsumerState<GlobalProductSearchScreen> createState() =>
      _GlobalProductSearchScreenState();
}

class _GlobalProductSearchScreenState
    extends ConsumerState<GlobalProductSearchScreen> {
  final _svc = ProductService();
  late final TextEditingController _searchController;
  final FocusNode _focusNode = FocusNode();

  Timer? _debounce;
  bool _loading = false;
  String _query = '';
  String _sort = 'relevance';
  String _selectedCategorySlug = '';

  List<ProductModel> _allItems = [];
  List<ProductModel> _visibleItems = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _query = widget.initialQuery.trim();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
      if (_query.isNotEmpty) {
        _runSearch(_query);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final q = value.trim();
    setState(() {
      _query = q;
      _selectedCategorySlug = '';
    });

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _runSearch(q);
    });
  }

  Future<void> _runSearch(String q) async {
    if (q.isEmpty) {
      setState(() {
        _loading = false;
        _allItems = [];
        _visibleItems = [];
        _selectedCategorySlug = '';
      });
      return;
    }

    setState(() => _loading = true);

    try {
      final results = await _svc.fetchProductModelsByQuery(q);

      if (!mounted) return;

      setState(() {
        _allItems = results;
        _selectedCategorySlug = '';
        _visibleItems = _applySort(results, _sort);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search failed: $e')),
      );
    }
  }

  List<ProductModel> _applySort(List<ProductModel> input, String sort) {
    final list = [...input];

    switch (sort) {
      case 'price_low':
        list.sort((a, b) => (a.salePriceCents ?? a.priceCents ?? 0)
            .compareTo(b.salePriceCents ?? b.priceCents ?? 0));
        return list;
      case 'price_high':
        list.sort((a, b) => (b.salePriceCents ?? b.priceCents ?? 0)
            .compareTo(a.salePriceCents ?? a.priceCents ?? 0));
        return list;
      case 'name':
        list.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        return list;
      case 'relevance':
      default:
        return list;
    }
  }

  List<ProductModel> _applyCategoryFilter(List<ProductModel> input) {
    if (_selectedCategorySlug.isEmpty) return input;
    return input
        .where((p) => (p.categorySlug ?? '') == _selectedCategorySlug)
        .toList();
  }

  void _rebuildVisibleItems() {
    final filtered = _applyCategoryFilter(_allItems);
    _visibleItems = _applySort(filtered, _sort);
  }

  void _changeSort(String value) {
    setState(() {
      _sort = value;
      _rebuildVisibleItems();
    });
  }

  void _changeCategory(String slug) {
    setState(() {
      _selectedCategorySlug = slug;
      _rebuildVisibleItems();
    });
  }

  List<_CategoryChipData> get _categoryChips {
    final seen = <String>{};
    final out = <_CategoryChipData>[];

    for (final p in _allItems) {
      final slug = (p.categorySlug ?? '').trim();
      final name = (p.categoryName ?? '').trim();
      if (slug.isEmpty || name.isEmpty) continue;
      if (!seen.add(slug)) continue;
      out.add(_CategoryChipData(slug: slug, name: name));
    }

    out.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return out;
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF5A2D82);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: WMGradients.pageBackground,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.maybePop(context),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: purple,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Expanded(
                          child: Text(
                            'Search Products',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: purple,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _focusNode,
                        onChanged: _onChanged,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: widget.hintText,
                          prefixIcon: const Icon(Icons.search, color: purple),
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    _onChanged('');
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_query.isNotEmpty && !_loading)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${_visibleItems.length} result${_visibleItems.length == 1 ? '' : 's'} for "$_query"',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_query.isNotEmpty)
                    SizedBox(
                      height: 46,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        children: [
                          _FilterChip(
                            label: 'Relevance',
                            selected: _sort == 'relevance',
                            onTap: () => _changeSort('relevance'),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Price Low',
                            selected: _sort == 'price_low',
                            onTap: () => _changeSort('price_low'),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Price High',
                            selected: _sort == 'price_high',
                            onTap: () => _changeSort('price_high'),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Name',
                            selected: _sort == 'name',
                            onTap: () => _changeSort('name'),
                          ),
                        ],
                      ),
                    ),
                  if (_query.isNotEmpty && _categoryChips.isNotEmpty)
                    SizedBox(
                      height: 42,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        children: [
                          _CategoryChip(
                            label: 'All',
                            selected: _selectedCategorySlug.isEmpty,
                            onTap: () => _changeCategory(''),
                          ),
                          const SizedBox(width: 8),
                          ..._categoryChips.map(
                            (c) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _CategoryChip(
                                label: c.name,
                                selected: _selectedCategorySlug == c.slug,
                                onTap: () => _changeCategory(c.slug),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: _query.isEmpty
                        ? const _SearchEmptyState()
                        : _loading
                            ? const Center(child: CircularProgressIndicator())
                            : _visibleItems.isEmpty
                                ? _NoResults(query: _query)
                                : ListView.separated(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 4, 16, 96),
                                    itemCount: _visibleItems.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 12),
                                    itemBuilder: (context, i) {
                                      final p = _visibleItems[i];
                                      return ProductCard(
                                        p: p,
                                        compact: true,
                                        onTap: () {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text('Open "${p.name}"'),
                                            ),
                                          );
                                        },
                                        onAdd: () {},
                                      );
                                    },
                                  ),
                  ),
                ],
              ),
            ),
          ),
          const StickyCartBar(bottom: 16),
        ],
      ),
    );
  }
}

class _CategoryChipData {
  final String slug;
  final String name;

  const _CategoryChipData({
    required this.slug,
    required this.name,
  });
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF5A2D82);

    return Material(
      color: selected ? const Color(0xFFF3ECFB) : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? purple : const Color(0xFFE5DDED),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? purple : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF5A2D82);

    return Material(
      color: selected ? purple : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? purple : const Color(0xFFE5DDED),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState();

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF5A2D82);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_rounded, size: 42, color: purple),
              SizedBox(height: 12),
              Text(
                'Search all products',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: purple,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Try rice, masala, snacks, tea, frozen items, or your favourite brand.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.search_off_rounded,
                size: 42,
                color: Color(0xFF5A2D82),
              ),
              const SizedBox(height: 12),
              Text(
                'No products found for "$query"',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Try a different keyword, brand name, or product type.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
