import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:western_malabar/features/cart/providers/cart_provider.dart';
import 'package:western_malabar/features/catalog/models/category_model.dart';
import 'package:western_malabar/features/catalog/models/product_model.dart';
import 'package:western_malabar/features/catalog/screens/subcategory_screen.dart';
import 'package:western_malabar/features/catalog/services/product_service.dart';
import 'package:western_malabar/features/search/providers/search_controller.dart';
import 'package:western_malabar/shared/widgets/product_card.dart';
import 'package:western_malabar/shared/widgets/wm_product_image.dart';

const _wmSearchBg = Color(0xFFF7F7F7);
const _wmSearchSurface = Colors.white;
const _wmSearchBorder = Color(0xFFE5E7EB);

const _wmSearchTextStrong = Color(0xFF111827);
const _wmSearchTextSoft = Color(0xFF6B7280);
const _wmSearchTextMuted = Color(0xFF9CA3AF);

const _wmSearchPrimary = Color(0xFF2A2F3A);
const _wmSearchPrimaryDark = Color(0xFF171A20);

const _wmSearchSuccess = Color(0xFF15803D);
const _wmSearchSuccessSoft = Color(0xFFECFDF5);

const _wmSearchDanger = Color(0xFFDC2626);
const _wmSearchAmberSoft = Color(0xFFFFF7ED);

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
  static const List<({String label, String value})> _sortItems = [
    (label: 'Relevance', value: 'relevance'),
    (label: 'Low to high', value: 'price_low'),
    (label: 'High to low', value: 'price_high'),
    (label: 'Name', value: 'name'),
  ];

  late final TextEditingController _searchController;
  late final ProviderSubscription<SearchSessionState> _searchSub;

  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  int _cartPulseTick = 0;
  _StringToastData? _addedToast;

  bool get _keyboardVisible => MediaQuery.of(context).viewInsets.bottom > 0;

  @override
  void initState() {
    super.initState();

    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });

    final searchState = ref.read(searchProvider);
    final initialText =
        searchState.query.isNotEmpty ? searchState.query : widget.initialQuery;

    _searchController = TextEditingController(text: initialText);

    _searchSub = ref.listenManual<SearchSessionState>(
      searchProvider,
      (previous, next) {
        final nextText = next.query;
        if (_searchController.text != nextText) {
          _searchController.value = TextEditingValue(
            text: nextText,
            selection: TextSelection.collapsed(offset: nextText.length),
          );
        }
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final notifier = ref.read(searchProvider.notifier);

      await notifier.hydrate();
      notifier.enterSearchScreen(
        initialQuery: widget.initialQuery,
      );

      if (!mounted) return;

      final state = ref.read(searchProvider);

      if (state.shouldRequestFocus) {
        _focusNode.requestFocus();
      }

      if (state.resultScrollOffset > 0 && _scrollController.hasClients) {
        await Future<void>.delayed(const Duration(milliseconds: 80));
        if (!mounted || !_scrollController.hasClients) return;

        final max = _scrollController.position.maxScrollExtent;
        final target = state.resultScrollOffset.clamp(0.0, max);
        _scrollController.jumpTo(target);
      }
    });

    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        ref
            .read(searchProvider.notifier)
            .setResultScrollOffset(_scrollController.offset);
      }
    });
  }

  @override
  void dispose() {
    _searchSub.close();
    _searchController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _closeSearch() {
    ref.read(searchProvider.notifier).collapseForHome();
    Navigator.pop(context);
  }

  void _showAddedToBasketToast(String productName) {
    final shortName = productName.trim().isEmpty ? 'Item' : productName.trim();
    final toastKey = UniqueKey();

    setState(() {
      _cartPulseTick++;
      _addedToast = _StringToastData(
        message: '$shortName added to basket',
        key: toastKey,
      );
    });

    Future<void>.delayed(const Duration(milliseconds: 1150), () {
      if (!mounted) return;
      if (_addedToast?.key == toastKey) {
        setState(() {
          _addedToast = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProvider);
    final controller = ref.read(searchProvider.notifier);
    final visibleItems = state.visibleResults;

    final cartSummary = ref.watch(
      cartProvider.select(
        (cart) {
          final qty = cart.fold<int>(0, (sum, e) => sum + e.qty);
          final totalCents = cart.fold<int>(
            0,
            (sum, e) =>
                sum +
                ((e.product.salePriceCents ?? e.product.priceCents ?? 0) *
                    e.qty),
          );
          return (qty: qty, totalCents: totalCents);
        },
      ),
    );

    final cartQty = cartSummary.qty;
    final cartTotalCents = cartSummary.totalCents;

    final showCartBar = cartQty > 0 && !_keyboardVisible;
    final showCommittedHeader = state.committedQuery.isNotEmpty &&
        !state.isSearchingResults &&
        state.committedQuery.trim() == state.query.trim() &&
        visibleItems.isNotEmpty;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _closeSearch();
      },
      child: Scaffold(
        backgroundColor: _wmSearchBg,
        body: SafeArea(
          child: Stack(
            children: [
              Container(
                color: _wmSearchBg,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        curve: Curves.easeOutCubic,
                        height: 58,
                        decoration: BoxDecoration(
                          color: _wmSearchSurface,
                          borderRadius: BorderRadius.circular(29),
                          border: Border.all(
                            color: _focusNode.hasFocus
                                ? _wmSearchPrimary
                                : _wmSearchBorder,
                            width: _focusNode.hasFocus ? 1.35 : 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _focusNode.hasFocus
                                  ? const Color(0x14000000)
                                  : const Color(0x0A000000),
                              blurRadius: _focusNode.hasFocus ? 14 : 8,
                              offset: Offset(0, _focusNode.hasFocus ? 5 : 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: _closeSearch,
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                color: _wmSearchTextStrong,
                                size: 25,
                              ),
                            ),
                            Icon(
                              Icons.search_rounded,
                              color: _focusNode.hasFocus
                                  ? _wmSearchPrimary
                                  : _wmSearchTextStrong,
                              size: 23,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                focusNode: _focusNode,
                                autofocus: true,
                                textInputAction: TextInputAction.search,
                                cursorColor: _wmSearchPrimary,
                                decoration: InputDecoration(
                                  hintText: widget.hintText,
                                  hintStyle: const TextStyle(
                                    color: _wmSearchTextSoft,
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                style: const TextStyle(
                                  color: _wmSearchTextStrong,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.1,
                                ),
                                onChanged: (value) {
                                  ref.read(searchProvider.notifier).updateQuery(
                                        value,
                                        fetchResultsToo: false,
                                        showOverlay: false,
                                      );
                                },
                                onSubmitted: (value) async {
                                  _focusNode.unfocus();
                                  await ref
                                      .read(searchProvider.notifier)
                                      .commitQuery(value);
                                },
                              ),
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 140),
                              switchInCurve: Curves.easeOut,
                              switchOutCurve: Curves.easeIn,
                              child: state.query.trim().isEmpty
                                  ? Row(
                                      key: const ValueKey('idle_actions'),
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          onPressed: () {},
                                          icon: const Icon(
                                            Icons.camera_alt_outlined,
                                            color: _wmSearchTextStrong,
                                            size: 21,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () {},
                                          icon: const Icon(
                                            Icons.mic_none_rounded,
                                            color: _wmSearchTextStrong,
                                            size: 21,
                                          ),
                                        ),
                                      ],
                                    )
                                  : IconButton(
                                      key: const ValueKey('clear_action'),
                                      onPressed: () {
                                        ref
                                            .read(searchProvider.notifier)
                                            .clearQuery(
                                              keepOverlay: false,
                                              clearResults: true,
                                            );
                                        _searchController.clear();
                                        _focusNode.requestFocus();
                                      },
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        color: _wmSearchTextSoft,
                                        size: 23,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (showCommittedHeader)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
                        child: Row(
                          children: [
                            Text(
                              '${visibleItems.length} result${visibleItems.length == 1 ? '' : 's'}',
                              style: const TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w900,
                                color: _wmSearchTextStrong,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                state.committedQuery,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13.2,
                                  fontWeight: FontWeight.w600,
                                  color: _wmSearchTextSoft,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (showCommittedHeader)
                      SizedBox(
                        height: 38,
                        child: ListView.separated(
                          key: const PageStorageKey('search_sort_chip_row'),
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                          itemCount: _sortItems.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final item = _sortItems[index];
                            return _FilterChip(
                              label: item.label,
                              selected: state.sort == item.value,
                              onTap: () => controller.setSort(item.value),
                            );
                          },
                        ),
                      ),
                    Expanded(
                      child: _buildBody(
                        context: context,
                        state: state,
                        visibleItems: visibleItems,
                        bottomInset: showCartBar ? 140 : 94,
                      ),
                    ),
                  ],
                ),
              ),
              if (_addedToast != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: showCartBar ? 92 : 20,
                  child: IgnorePointer(
                    child: _AddedToBasketToast(
                      key: _addedToast!.key,
                      message: _addedToast!.message,
                    ),
                  ),
                ),
              if (showCartBar)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: _SearchCartBar(
                    pulseTick: _cartPulseTick,
                    itemCount: cartQty,
                    totalCents: cartTotalCents,
                    onTap: _closeSearch,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required SearchSessionState state,
    required List<ProductModel> visibleItems,
    required double bottomInset,
  }) {
    final query = state.query.trim();
    final committed = state.committedQuery.trim();

    if (query.isEmpty && committed.isEmpty && state.recentQueries.isEmpty) {
      return const _SearchEmptyState();
    }

    final isTypingMode =
        query.isNotEmpty && (state.isSuggesting || committed != query);

    if (isTypingMode) {
      return _SearchTypingBody(state: state);
    }

    if (state.isSearchingResults && state.resultItems.isEmpty) {
      return GridView.builder(
        key: const PageStorageKey('search_loading_grid'),
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        cacheExtent: 900,
        padding: EdgeInsets.fromLTRB(12, 4, 12, bottomInset),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.66,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => const RepaintBoundary(
          child: _SearchGridSkeleton(),
        ),
      );
    }

    if (committed.isNotEmpty && visibleItems.isEmpty) {
      return _NoResults(query: committed);
    }

    return Stack(
      children: [
        GridView.builder(
          key: const PageStorageKey('search_results_grid'),
          controller: _scrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          cacheExtent: 900,
          padding: EdgeInsets.fromLTRB(12, 4, 12, bottomInset),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.66,
          ),
          itemCount: visibleItems.length,
          itemBuilder: (context, i) {
            final p = visibleItems[i];

            return RepaintBoundary(
              child: ProductCard(
                key: ValueKey(p.id),
                p: p,
                compact: false,
                showShadow: true,
                onTap: () {
                  // TODO: Navigate to product detail screen.
                },
                onAdd: () {
                  _showAddedToBasketToast(p.name);
                },
              ),
            );
          },
        ),
        if (state.isSearchingResults && state.resultItems.isNotEmpty)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              minHeight: 2,
              color: _wmSearchPrimary,
              backgroundColor: Color(0xFFE5E7EB),
            ),
          ),
      ],
    );
  }
}

class _SearchTypingBody extends ConsumerWidget {
  const _SearchTypingBody({required this.state});

  final SearchSessionState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = state.suggestionProducts.take(6).toList();
    final categories = state.suggestionCategories.take(3).toList();

    return ListView(
      key: const PageStorageKey('search_typing_body'),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        if (products.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 8, 4, 10),
            child: Text(
              'Top results',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: _wmSearchTextSoft,
              ),
            ),
          ),
          SizedBox(
            height: 176,
            child: ListView.separated(
              key: const PageStorageKey('top_results_row'),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _ProductCardMini(
                product: products[i],
                isTopMatch: i == 0,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (state.isSuggesting && products.isEmpty)
          const _SuggestionSkeletonList(),
        if (categories.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 8, 4, 8),
            child: Text(
              'Categories',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: _wmSearchTextSoft,
              ),
            ),
          ),
          ...categories.map((c) => _CategorySuggestionTile(category: c)),
          const SizedBox(height: 8),
        ],
        if (state.query.trim().isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: _wmSearchSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _wmSearchBorder),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 2,
              ),
              leading: const Icon(
                Icons.search_rounded,
                color: _wmSearchPrimary,
              ),
              title: Text(
                'Search all products for "${state.query.trim()}"',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: _wmSearchTextStrong,
                ),
              ),
              onTap: () async {
                FocusScope.of(context).unfocus();
                await ref
                    .read(searchProvider.notifier)
                    .commitQuery(state.query);
              },
            ),
          ),
      ],
    );
  }
}

class _SearchCartBar extends StatefulWidget {
  const _SearchCartBar({
    required this.pulseTick,
    required this.itemCount,
    required this.totalCents,
    required this.onTap,
  });

  final int pulseTick;
  final int itemCount;
  final int totalCents;
  final VoidCallback onTap;

  @override
  State<_SearchCartBar> createState() => _SearchCartBarState();
}

class _SearchCartBarState extends State<_SearchCartBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scale;
  late final Animation<double> _glow;

  String _money(int cents) => '£${(cents / 100).toStringAsFixed(2)}';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.035)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.035, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 45,
      ),
    ]).animate(_pulseController);

    _glow = Tween<double>(begin: 18, end: 24).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant _SearchCartBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulseTick != oldWidget.pulseTick) {
      _pulseController
        ..stop()
        ..forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        return Transform.scale(
          scale: _scale.value,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(22),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      _wmSearchPrimaryDark,
                      _wmSearchPrimary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x22000000),
                      blurRadius: _glow.value,
                      offset: const Offset(0, 9),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0x22FFFFFF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.shopping_bag_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.itemCount} item${widget.itemCount == 1 ? '' : 's'} in basket',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _money(widget.totalCents),
                              style: const TextStyle(
                                color: Color(0xFFE5E7EB),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'View basket',
                          style: TextStyle(
                            color: _wmSearchPrimary,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SuggestionSkeletonList extends StatelessWidget {
  const _SuggestionSkeletonList();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _SearchResultSkeleton(),
        SizedBox(height: 12),
        _SearchResultSkeleton(),
      ],
    );
  }
}

class _CategorySuggestionTile extends ConsumerWidget {
  const _CategorySuggestionTile({required this.category});

  final CategoryModel category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          FocusScope.of(context).unfocus();
          ref.read(searchProvider.notifier).collapseForHome();

          await Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => SubcategoryScreen(
                parentName: category.name,
                parentSlug: category.slug,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _wmSearchSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _wmSearchBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.grid_view_rounded,
                  color: _wmSearchPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _wmSearchTextStrong,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: _wmSearchTextMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductCardMini extends ConsumerWidget {
  const _ProductCardMini({
    required this.product,
    this.isTopMatch = false,
  });

  final WmProductDto product;
  final bool isTopMatch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final price = product.displayPriceCents / 100.0;
    final image =
        product.images.isNotEmpty ? product.images.first.toString() : null;
    final brand = (product.brandName ?? '').trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          FocusScope.of(context).unfocus();
          await ref
              .read(searchProvider.notifier)
              .selectSuggestionProduct(product);
        },
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: 150,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _wmSearchSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _wmSearchBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x07000000),
                blurRadius: 7,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: ColoredBox(
                    color: const Color(0xFFF3F4F6),
                    child: WmProductImage(
                      imageUrl: image,
                      width: double.infinity,
                      height: double.infinity,
                      borderRadius: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (isTopMatch) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _wmSearchAmberSoft,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: const Text(
                    'Top match',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: _wmSearchPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],
              if (brand.isNotEmpty) ...[
                Text(
                  brand,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: _wmSearchTextSoft,
                  ),
                ),
                const SizedBox(height: 3),
              ],
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.3,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  color: _wmSearchTextStrong,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '£${price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: _wmSearchPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchResultSkeleton extends StatefulWidget {
  const _SearchResultSkeleton();

  @override
  State<_SearchResultSkeleton> createState() => _SearchResultSkeletonState();
}

class _SearchResultSkeletonState extends State<_SearchResultSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
      lowerBound: 0.72,
      upperBound: 1.0,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _bar(double width, double height) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 116,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _wmSearchSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _wmSearchBorder),
      ),
      child: Row(
        children: [
          FadeTransition(
            opacity: _controller,
            child: Container(
              width: 90,
              height: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(70, 10),
                const SizedBox(height: 10),
                _bar(double.infinity, 14),
                const SizedBox(height: 8),
                _bar(120, 12),
                const Spacer(),
                _bar(92, 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchGridSkeleton extends StatefulWidget {
  const _SearchGridSkeleton();

  @override
  State<_SearchGridSkeleton> createState() => _SearchGridSkeletonState();
}

class _SearchGridSkeletonState extends State<_SearchGridSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
      lowerBound: 0.72,
      upperBound: 1.0,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _bar(double height, {double? width}) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _wmSearchSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _wmSearchBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeTransition(
            opacity: _controller,
            child: Container(
              height: 118,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _bar(11, width: 86),
          const SizedBox(height: 8),
          _bar(15),
          const SizedBox(height: 6),
          _bar(15, width: 118),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _bar(18, width: 76),
              const Spacer(),
              _bar(34, width: 72),
            ],
          ),
        ],
      ),
    );
  }
}

class _StringToastData {
  final String message;
  final Key key;

  const _StringToastData({
    required this.message,
    required this.key,
  });
}

class _AddedToBasketToast extends StatefulWidget {
  const _AddedToBasketToast({
    super.key,
    required this.message,
  });

  final String message;

  @override
  State<_AddedToBasketToast> createState() => _AddedToBasketToastState();
}

class _AddedToBasketToastState extends State<_AddedToBasketToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..forward();

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _scale = Tween<double>(
      begin: 0.985,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(
          scale: _scale,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0x2215803D),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Color(0xFF86EFAC),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.message,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
    return Material(
      color: selected ? const Color(0xFFF3F4F6) : _wmSearchSurface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? _wmSearchPrimary : _wmSearchBorder,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: TextStyle(
              fontSize: 12.4,
              fontWeight: FontWeight.w800,
              color: selected ? _wmSearchPrimary : _wmSearchTextStrong,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchEmptyState extends ConsumerWidget {
  const _SearchEmptyState();

  static const List<String> _quickPickLabels = [
    'Rice',
    'Frozen',
    'Masala',
    'Tea',
    'Snacks',
    'Oil',
  ];

  static const List<String> _popularLabels = [
    'Chicken',
    'Vegetables',
    'Ready meals',
    'Biscuits',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchProvider);

    return ListView(
      key: const PageStorageKey('search_empty_state'),
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        if (state.recentQueries.isNotEmpty) ...[
          const _SearchSectionLabel('Recent searches'),
          const SizedBox(height: 8),
          ...state.recentQueries.map((q) => _RecentSearchRow(query: q)),
          const SizedBox(height: 16),
        ],
        const _SearchSectionLabel('Quick picks'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quickPickLabels
              .map((label) => _QuickPill(label: label))
              .toList(),
        ),
        const SizedBox(height: 18),
        const _SearchSectionLabel('Popular this week'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              _popularLabels.map((label) => _QuickPill(label: label)).toList(),
        ),
      ],
    );
  }
}

class _SearchSectionLabel extends StatelessWidget {
  const _SearchSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: _wmSearchTextSoft,
        ),
      ),
    );
  }
}

class _RecentSearchRow extends ConsumerWidget {
  const _RecentSearchRow({required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _wmSearchSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _wmSearchBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        leading: const Icon(Icons.history_rounded, color: _wmSearchTextSoft),
        title: Text(
          query,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: _wmSearchTextStrong,
          ),
        ),
        trailing: IconButton(
          onPressed: () {
            ref.read(searchProvider.notifier).removeRecentQuery(query);
          },
          icon: const Icon(Icons.close_rounded),
        ),
        onTap: () async {
          await ref.read(searchProvider.notifier).rerunRecent(query);
          FocusScope.of(context).unfocus();
        },
      ),
    );
  }
}

class _QuickPill extends ConsumerWidget {
  const _QuickPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: _wmSearchSurface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: () async {
          final notifier = ref.read(searchProvider.notifier);
          await notifier.commitQuery(label);
          FocusScope.of(context).unfocus();
        },
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _wmSearchBorder),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _wmSearchTextStrong,
              height: 1.0,
            ),
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
            color: _wmSearchSurface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _wmSearchBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0E000000),
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
                color: _wmSearchPrimary,
              ),
              const SizedBox(height: 12),
              Text(
                'We couldn’t find a close match for "$query"',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: _wmSearchTextStrong,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Try another name, brand, or a simpler keyword.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _wmSearchTextSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
