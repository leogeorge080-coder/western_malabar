// lib/screens/customer/search_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:western_malabar/features/search/providers/search_page_provider.dart';
import 'package:western_malabar/features/catalog/services/product_service.dart';
import 'package:western_malabar/shared/widgets/wm_product_image.dart';

/// ─────────────────────────────────────────────────────────────
/// Full-featured Search Screen with:
/// - Live suggestions dropdown
/// - Infinite scrolling
/// - Filter chips (placeholder)
/// - Loading skeletons
/// - Empty states
/// ─────────────────────────────────────────────────────────────

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialQuery});
  final String? initialQuery;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _c = TextEditingController();
  final FocusNode _f = FocusNode();
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();

    if ((widget.initialQuery ?? '').trim().isNotEmpty) {
      _c.text = widget.initialQuery!.trim();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(searchPageProvider.notifier).submit(_c.text);
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _f.requestFocus());
    }

    _scroll.addListener(() {
      final st = ref.read(searchPageProvider);
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 800) {
        ref.read(searchPageProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    _f.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(searchPageProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        surfaceTintColor: Colors.white,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _SearchBar(
            controller: _c,
            focusNode: _f,
            onChanged: (q) =>
                ref.read(searchPageProvider.notifier).onQueryChanged(q),
            onSubmitted: (q) => ref.read(searchPageProvider.notifier).submit(q),
            onClear: () {
              _c.clear();
              ref.read(searchPageProvider.notifier).onQueryChanged('');
              _f.requestFocus();
            },
          ),
        ),
      ),
      body: Stack(
        children: [
          // Results area
          Column(
            children: [
              // Filter row placeholder (Amazon-like chips)
              const _FilterChipsRow(),

              Expanded(
                child: st.loading
                    ? const _ResultsSkeleton()
                    : st.results.isEmpty && st.query.trim().isNotEmpty
                        ? _EmptyState(
                            query: st.query,
                            error: st.error,
                            onRetry: () => ref
                                .read(searchPageProvider.notifier)
                                .submit(st.query),
                          )
                        : _ResultsGrid(
                            controller: _scroll,
                            items: st.results,
                            loadingMore: st.loadingMore,
                            error: st.error,
                          ),
              ),
            ],
          ),

          // Suggestions dropdown (only when typing + focused + not loading results)
          if (_f.hasFocus &&
              st.query.trim().isNotEmpty &&
              !st.loading &&
              st.suggestions.isNotEmpty)
            _SuggestionsOverlay(
              suggestions: st.suggestions,
              onTap: (p) {
                _c.text = p.name;
                _f.unfocus();
                ref.read(searchPageProvider.notifier).submit(p.name);
                // OPTIONAL: navigate directly to product detail
                // Navigator.pushNamed(context, "/product/${p.slug}");
              },
            ),
        ],
      ),
    );
  }
}

/// Search input bar with close button
class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x11000000)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          const Icon(Icons.search, color: Color(0xFF5A2D82)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Search products…',
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: onChanged,
              onSubmitted: onSubmitted,
            ),
          ),
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.close, size: 18),
            color: Colors.black54,
            splashRadius: 18,
          ),
        ],
      ),
    );
  }
}

/// Suggestions dropdown overlay
class _SuggestionsOverlay extends StatelessWidget {
  const _SuggestionsOverlay({
    required this.suggestions,
    required this.onTap,
  });

  final List<WmProductDto> suggestions;
  final void Function(WmProductDto p) onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 12,
      right: 12,
      top: 6,
      child: Material(
        elevation: 10,
        borderRadius: BorderRadius.circular(14),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 320),
          child: ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: suggestions.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final p = suggestions[i];
              return ListTile(
                dense: true,
                leading: WmProductImage(
                  imageUrl: p.firstImageUrl,
                  width: 44,
                  height: 44,
                  borderRadius: 10,
                  placeholderIcon: Icons.search,
                ),
                title: Text(
                  p.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '£${(p.displayPriceCents / 100.0).toStringAsFixed(2)}',
                ),
                onTap: () => onTap(p),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Filter chips row (placeholder for future filtering)
class _FilterChipsRow extends StatelessWidget {
  const _FilterChipsRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        children: const [
          _Chip(label: 'Sort'),
          SizedBox(width: 8),
          _Chip(label: 'Price'),
          SizedBox(width: 8),
          _Chip(label: 'In stock'),
          SizedBox(width: 8),
          _Chip(label: 'Category'),
          SizedBox(width: 8),
          _Chip(label: 'Brand'),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x11000000)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          const Icon(Icons.expand_more, size: 16),
        ],
      ),
    );
  }
}

/// Results grid with infinite scroll
class _ResultsGrid extends StatelessWidget {
  const _ResultsGrid({
    required this.controller,
    required this.items,
    required this.loadingMore,
    required this.error,
  });

  final ScrollController controller;
  final List<WmProductDto> items;
  final bool loadingMore;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: controller,
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.60,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => _ResultTile(p: items[i]),
              childCount: items.length,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                if (loadingMore)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                if (!loadingMore && error != null)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      error!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Individual product tile in results
class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.p});
  final WmProductDto p;

  @override
  Widget build(BuildContext context) {
    final price = '£${(p.displayPriceCents / 100.0).toStringAsFixed(2)}';

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        // Replace with your actual product detail navigation
        // Navigator.pushNamed(context, "/product/${p.slug}");
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Open ${p.name}')));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x15000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            )
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
                child: WmProductImage(
                  imageUrl: p.firstImageUrl,
                  width: double.infinity,
                  height: 180,
                  borderRadius: 0,
                  placeholderIcon: Icons.image,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    price,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF5A2D82),
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

/// Loading skeleton
class _ResultsSkeleton extends StatelessWidget {
  const _ResultsSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      physics: const BouncingScrollPhysics(),
      itemCount: 10,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.60,
      ),
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F4),
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}

/// Empty results state
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.query,
    required this.error,
    required this.onRetry,
  });
  final String query;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 56, color: Colors.black38),
            const SizedBox(height: 10),
            Text(
              error ?? 'No results for "$query"',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            )
          ],
        ),
      ),
    );
  }
}
