// lib/screens/customer/search_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:western_malabar/features/search/providers/search_page_provider.dart';
import 'package:western_malabar/features/catalog/services/product_service.dart';
import 'package:western_malabar/shared/widgets/wm_product_image.dart';

const _wmSearchBg = Color(0xFFF6F7F8);
const _wmSearchSurface = Colors.white;
const _wmSearchSurfaceSoft = Color(0xFFF9FAFB);
const _wmSearchBorder = Color(0xFFE5E7EB);

const _wmSearchTextStrong = Color(0xFF111827);
const _wmSearchTextSoft = Color(0xFF6B7280);
const _wmSearchTextMuted = Color(0xFF9CA3AF);

const _wmSearchPrimary = Color(0xFF22252B);
const _wmSearchPrimarySoft = Color(0xFFF3F4F6);

/// ─────────────────────────────────────────────────────────────
/// Full-featured Search Screen with:
/// - Live suggestions dropdown
/// - Infinite scrolling
/// - Filter chips
/// - Loading skeletons
/// - Empty states
/// - Black / ash / white premium theme
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

    _f.addListener(() {
      if (mounted) setState(() {});
    });

    if ((widget.initialQuery ?? '').trim().isNotEmpty) {
      _c.text = widget.initialQuery!.trim();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(searchPageProvider.notifier).submit(_c.text);
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _f.requestFocus());
    }

    _scroll.addListener(() {
      if (!_scroll.hasClients) return;
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
      backgroundColor: _wmSearchBg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: _wmSearchBg,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: _SearchTopBar(
                controller: _c,
                focusNode: _f,
                onChanged: (q) =>
                    ref.read(searchPageProvider.notifier).onQueryChanged(q),
                onSubmitted: (q) =>
                    ref.read(searchPageProvider.notifier).submit(q),
                onClear: () {
                  _c.clear();
                  ref.read(searchPageProvider.notifier).onQueryChanged('');
                  _f.requestFocus();
                },
              ),
            ),
            const _FilterChipsRow(),
            Expanded(
              child: Stack(
                children: [
                  if (st.loading)
                    const _ResultsSkeleton()
                  else if (st.results.isEmpty && st.query.trim().isNotEmpty)
                    _EmptyState(
                      query: st.query,
                      error: st.error,
                      onRetry: () => ref
                          .read(searchPageProvider.notifier)
                          .submit(st.query),
                    )
                  else if (st.results.isEmpty)
                    const _InitialSearchState()
                  else
                    _ResultsGrid(
                      controller: _scroll,
                      items: st.results,
                      loadingMore: st.loadingMore,
                      error: st.error,
                    ),
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
                      },
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

/// Top search bar with back + input
class _SearchTopBar extends StatelessWidget {
  const _SearchTopBar({
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
    final isFocused = focusNode.hasFocus;

    return Row(
      children: [
        Material(
          color: _wmSearchSurface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => Navigator.maybePop(context),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _wmSearchSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _wmSearchBorder),
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
                color: _wmSearchPrimary,
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
              color: _wmSearchSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isFocused ? _wmSearchPrimary : _wmSearchBorder,
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
                  color: _wmSearchPrimary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      hintText: 'Search products…',
                      hintStyle: TextStyle(
                        color: _wmSearchTextMuted,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: const TextStyle(
                      color: _wmSearchTextStrong,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    onChanged: onChanged,
                    onSubmitted: onSubmitted,
                  ),
                ),
                if (controller.text.trim().isNotEmpty)
                  IconButton(
                    onPressed: onClear,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: _wmSearchTextSoft,
                    splashRadius: 18,
                  )
                else
                  const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ],
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
      top: 4,
      child: Material(
        color: _wmSearchSurface,
        elevation: 0,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: _wmSearchSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _wmSearchBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                color: _wmSearchBorder,
              ),
              itemBuilder: (_, i) {
                final p = suggestions[i];
                return ListTile(
                  dense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  leading: WmProductImage(
                    imageUrl: p.firstImageUrl,
                    width: 46,
                    height: 46,
                    borderRadius: 12,
                    placeholderIcon: Icons.search,
                  ),
                  title: Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: _wmSearchTextStrong,
                    ),
                  ),
                  subtitle: Text(
                    '£${(p.displayPriceCents / 100.0).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _wmSearchTextSoft,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.north_west_rounded,
                    size: 18,
                    color: _wmSearchTextMuted,
                  ),
                  onTap: () => onTap(p),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Filter chips row
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
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _wmSearchSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _wmSearchBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12.8,
              color: _wmSearchTextStrong,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.expand_more,
            size: 16,
            color: _wmSearchTextSoft,
          ),
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
              childAspectRatio: 0.62,
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
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _wmSearchPrimary,
                    ),
                  ),
                if (!loadingMore && error != null)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      error!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w700,
                      ),
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
    final brand = (p.brandName ?? '').trim();

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Open ${p.name}')));
      },
      child: Container(
        decoration: BoxDecoration(
          color: _wmSearchSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _wmSearchBorder),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            )
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
                  color: _wmSearchSurfaceSoft,
                  child: WmProductImage(
                    imageUrl: p.firstImageUrl,
                    width: double.infinity,
                    height: 180,
                    borderRadius: 0,
                    placeholderIcon: Icons.image_outlined,
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
                        color: _wmSearchTextSoft,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    p.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      height: 1.25,
                      color: _wmSearchTextStrong,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    price,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: _wmSearchPrimary,
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
        childAspectRatio: 0.62,
      ),
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: _wmSearchSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _wmSearchBorder),
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(999),
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
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _wmSearchSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _wmSearchBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.search_off_rounded,
                size: 56,
                color: _wmSearchTextMuted,
              ),
              const SizedBox(height: 12),
              Text(
                error ?? 'No results for "$query"',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: _wmSearchTextStrong,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Try a simpler keyword, product name, or brand.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _wmSearchTextSoft,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _wmSearchPrimary,
                  side: const BorderSide(color: _wmSearchBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _InitialSearchState extends StatelessWidget {
  const _InitialSearchState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_rounded,
              size: 52,
              color: _wmSearchTextMuted,
            ),
            SizedBox(height: 12),
            Text(
              'Search the store',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: _wmSearchTextStrong,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Find groceries, snacks, frozen foods, spices, and more.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _wmSearchTextSoft,
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
