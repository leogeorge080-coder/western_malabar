import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:western_malabar/features/cart/providers/cart_provider.dart';
import 'package:western_malabar/features/cart/screens/cart_screen.dart';
import 'package:western_malabar/features/catalog/models/category_model.dart';
import 'package:western_malabar/features/catalog/models/product_model.dart';
import 'package:western_malabar/features/catalog/services/product_service.dart';
import 'package:western_malabar/shared/navigation/product_navigation.dart';
import 'package:western_malabar/features/catalog/screens/subcategory_screen.dart';
import 'package:western_malabar/features/search/providers/search_controller.dart';
import 'package:western_malabar/features/search/widgets/search_advanced_result_tile.dart';
import 'package:western_malabar/shared/utils/cart_fly_target.dart';
import 'package:western_malabar/shared/utils/fly_to_cart.dart';
import 'package:western_malabar/shared/utils/haptic.dart';
import 'package:western_malabar/shared/widgets/wm_product_image.dart';

const _wmSearchBg = Color(0xFFF7F7F7);
const _wmSearchSurface = Colors.white;
const _wmSearchBorder = Color(0xFFD5DAE1);

const _wmSearchTextStrong = Color(0xFF111827);
const _wmSearchTextSoft = Color(0xFF6B7280);
const _wmSearchTextMuted = Color(0xFF9CA3AF);

const _wmSearchPrimary = Color(0xFF202531);
const _wmSearchPrimaryDark = Color(0xFF121722);
const _wmSearchCta = Color(0xFFF4B400);
const _wmSearchCtaText = Color(0xFF111827);

class GlobalProductSearchScreen extends ConsumerStatefulWidget {
  const GlobalProductSearchScreen({
    super.key,
    this.initialQuery = '',
    this.hintText = 'Search all products',
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
      notifier.enterSearchScreen(initialQuery: widget.initialQuery);

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
        setState(() => _addedToast = null);
      }
    });
  }

  Future<void> _handleAddedToBasket(
      String productName, GlobalKey imageKey) async {
    Haptic.medium(context);
    _showAddedToBasketToast(productName);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    if (!mounted) return;
    await flyToCart(
      context: context,
      cartKey: wmBottomCartNavKey,
      imageKey: imageKey,
    );
  }

  Future<void> _openCart() async {
    FocusScope.of(context).unfocus();
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const CartScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProvider);
    final controller = ref.read(searchProvider.notifier);
    final visibleItems = state.visibleResults;

    final cartSummary = ref.watch(
      cartProvider.select((cart) {
        final qty = cart.fold<int>(0, (sum, e) => sum + e.qty);
        final totalCents = cart.fold<int>(
          0,
          (sum, e) =>
              sum +
              ((e.product.salePriceCents ?? e.product.priceCents ?? 0) * e.qty),
        );
        return (qty: qty, totalCents: totalCents);
      }),
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
      child: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: _wmSearchPrimary,
              ),
          textSelectionTheme: const TextSelectionThemeData(
            cursorColor: _wmSearchTextStrong,
            selectionColor: Color(0x14000000),
            selectionHandleColor: Color(0xFFBDBDBD),
          ),
        ),
        child: Scaffold(
          backgroundColor: _wmSearchBg,
          body: SafeArea(
            child: Stack(
              children: [
                ColoredBox(
                  color: _wmSearchBg,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                        child: _SearchHeaderBar(
                          controller: _searchController,
                          focusNode: _focusNode,
                          hintText: widget.hintText,
                          hasText: state.query.trim().isNotEmpty,
                          onBack: _closeSearch,
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
                          onClear: () {
                            ref.read(searchProvider.notifier).clearQuery(
                                  keepOverlay: false,
                                  clearResults: true,
                                );
                            _searchController.clear();
                            _focusNode.requestFocus();
                          },
                        ),
                      ),
                      if (showCommittedHeader)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
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
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
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
                      onTap: _openCart,
                    ),
                  ),
              ],
            ),
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

    if (query.isEmpty) {
      return const _SearchEmptyState();
    }

    final isTypingMode = query.isNotEmpty && committed != query;

    if (isTypingMode) {
      return _SearchTypingBody(state: state);
    }

    if (state.isSearchingResults && state.resultItems.isEmpty) {
      return ListView.separated(
        key: const PageStorageKey('search_loading_list'),
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        cacheExtent: 900,
        padding: EdgeInsets.fromLTRB(12, 4, 12, bottomInset),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) =>
            const RepaintBoundary(child: _SearchResultSkeleton()),
      );
    }

    if (committed.isNotEmpty && visibleItems.isEmpty) {
      return _NoResults(query: committed);
    }

    return Stack(
      children: [
        ListView.separated(
          key: const PageStorageKey('search_results_list'),
          controller: _scrollController,
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          cacheExtent: 1200,
          padding: EdgeInsets.fromLTRB(12, 4, 12, bottomInset),
          itemCount: visibleItems.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final p = visibleItems[i];
            return RepaintBoundary(
              child: SearchAdvancedResultTile(
                key: ValueKey(p.id),
                product: p,
                onTap: () {
                  ProductNavigation.open(
                    context,
                    productId: p.id,
                    initialProduct: p,
                  );
                },
                onAdded: _handleAddedToBasket,
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

class _SearchHeaderBar extends StatelessWidget {
  const _SearchHeaderBar({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.hasText,
    required this.onBack,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final bool hasText;
  final VoidCallback onBack;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: _wmSearchSurface,
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: const Color(0xFFCCD3DC), width: 1.1),
        boxShadow: const [
          BoxShadow(
              color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 2),
          IconButton(
            onPressed: onBack,
            splashRadius: 18,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.arrow_back_rounded,
                color: Color(0xFF111827), size: 24),
          ),
          const Icon(Icons.search_rounded, color: Color(0xFF374151), size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              textInputAction: TextInputAction.search,
              cursorColor: _wmSearchTextStrong,
              cursorWidth: 1.6,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 15.5,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                height: 1.1,
                letterSpacing: -0.1,
              ),
              onChanged: onChanged,
              onSubmitted: onSubmitted,
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 120),
            child: hasText
                ? IconButton(
                    key: const ValueKey('clear_action'),
                    onPressed: onClear,
                    splashRadius: 18,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close_rounded,
                        color: Color(0xFF6B7280), size: 24),
                  )
                : const SizedBox(key: ValueKey('empty_tail_space'), width: 12),
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}

class _SearchTypingBody extends ConsumerWidget {
  const _SearchTypingBody({required this.state});

  final SearchSessionState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = state.suggestionProducts.take(8).toList();
    final categories = state.suggestionCategories.take(4).toList();
    final trimmedQuery = state.query.trim();

    return ListView(
      key: const PageStorageKey('search_typing_body'),
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        if (state.isSuggesting && products.isEmpty && categories.isEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'Searching...',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _wmSearchTextSoft),
            ),
          ),
          const _SuggestionSkeletonList(),
          const SizedBox(height: 12),
        ],
        if (products.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'Top results',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _wmSearchTextSoft),
            ),
          ),
          ...List.generate(
              products.length,
              (i) => _LiveProductSuggestionTile(
                  product: products[i], isTopMatch: i == 0)),
          const SizedBox(height: 10),
        ],
        if (categories.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'Categories',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _wmSearchTextSoft),
            ),
          ),
          ...categories.map((c) => _CategorySuggestionTile(category: c)),
          const SizedBox(height: 8),
        ],
        if (trimmedQuery.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: _wmSearchSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _wmSearchBorder),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              leading:
                  const Icon(Icons.search_rounded, color: _wmSearchPrimary),
              title: Text(
                'Search all products for "$trimmedQuery"',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: _wmSearchTextStrong),
              ),
              onTap: () async {
                FocusScope.of(context).unfocus();
                await ref
                    .read(searchProvider.notifier)
                    .commitQuery(trimmedQuery);
              },
            ),
          ),
      ],
    );
  }
}

class _LiveProductSuggestionTile extends ConsumerWidget {
  const _LiveProductSuggestionTile(
      {required this.product, this.isTopMatch = false});

  final WmProductDto product;
  final bool isTopMatch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final image =
        product.images.isNotEmpty ? product.images.first.toString() : null;
    final brand = (product.brandName ?? '').trim();
    final price = '£${(product.displayPriceCents / 100.0).toStringAsFixed(2)}';

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () async {
          FocusScope.of(context).unfocus();
          await ref
              .read(searchProvider.notifier)
              .selectSuggestionProduct(product);
        },
        child: Container(
          height: 84,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: const BoxDecoration(
            border:
                Border(bottom: BorderSide(color: Color(0xFFE6E6E6), width: 1)),
          ),
          child: Row(
            children: [
              _AmazonSuggestionImage(imageUrl: image),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14.6,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111111),
                            height: 1.15),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (brand.isNotEmpty)
                            Expanded(
                              child: Text(
                                brand,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12.4,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF6B7280),
                                    height: 1.1),
                              ),
                            )
                          else
                            const Spacer(),
                          const SizedBox(width: 8),
                          Text(
                            price,
                            style: const TextStyle(
                                fontSize: 13.6,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF111111),
                                height: 1.0),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (isTopMatch) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7E6),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFF0D9A7)),
                  ),
                  child: const Text(
                    'Top',
                    style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF7C5A00),
                        height: 1),
                  ),
                ),
              ],
              const SizedBox(width: 10),
              const Icon(Icons.arrow_outward_rounded,
                  size: 20, color: Color(0xFF9CA3AF)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmazonSuggestionImage extends StatelessWidget {
  const _AmazonSuggestionImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 52,
        height: 52,
        color: const Color(0xFFF3F4F6),
        child: (imageUrl == null || imageUrl!.trim().isEmpty)
            ? const Center(
                child: Icon(Icons.shopping_bag_outlined,
                    size: 22, color: Color(0xFF9CA3AF)))
            : WmProductImage(
                imageUrl: imageUrl, width: 52, height: 52, borderRadius: 8),
      ),
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
        vsync: this, duration: const Duration(milliseconds: 320));
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
        CurvedAnimation(parent: _pulseController, curve: Curves.easeOutCubic));
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
                      colors: [_wmSearchPrimaryDark, _wmSearchPrimary]),
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
                        child: const Icon(Icons.shopping_bag_rounded,
                            color: Colors.white),
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
                                  fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _money(widget.totalCents),
                              style: const TextStyle(
                                  color: Color(0xFFE5E7EB),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                            color: _wmSearchCta,
                            borderRadius: BorderRadius.circular(999)),
                        child: const Text(
                          'View basket',
                          style: TextStyle(
                              color: _wmSearchCtaText,
                              fontWeight: FontWeight.w900,
                              fontSize: 13),
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
          if (!context.mounted) return;
          await Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => SubcategoryScreen(
                  parentName: category.name, parentSlug: category.slug),
            ),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8, left: 12, right: 12),
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
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.grid_view_rounded,
                    color: _wmSearchPrimary),
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
                      color: _wmSearchTextStrong),
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: _wmSearchTextMuted),
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
        upperBound: 1.0)
      ..repeat(reverse: true);
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
            borderRadius: BorderRadius.circular(999)),
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
                  borderRadius: BorderRadius.circular(14)),
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

class _StringToastData {
  final String message;
  final Key key;

  const _StringToastData({required this.message, required this.key});
}

class _AddedToBasketToast extends StatefulWidget {
  const _AddedToBasketToast({super.key, required this.message});

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
        vsync: this, duration: const Duration(milliseconds: 260))
      ..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slide =
        Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _scale = Tween<double>(begin: 0.985, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x26000000),
                        blurRadius: 18,
                        offset: Offset(0, 8)),
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
                      child: const Icon(Icons.check_rounded,
                          color: Color(0xFF86EFAC), size: 18),
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
                            fontWeight: FontWeight.w800),
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
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFFFF7E0) : _wmSearchSurface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border:
                Border.all(color: selected ? _wmSearchCta : _wmSearchBorder),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: _wmSearchTextStrong,
                height: 1.0),
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
    'Oil'
  ];
  static const List<String> _popularLabels = [
    'Chicken',
    'Vegetables',
    'Ready meals',
    'Biscuits'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchProvider);

    return ListView(
      key: const PageStorageKey('search_empty_state'),
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        if (state.recentQueries.isNotEmpty) ...[
          _RecentSectionHeader(queries: state.recentQueries),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _wmSearchBorder),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x05000000),
                    blurRadius: 6,
                    offset: Offset(0, 2))
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: List.generate(
                state.recentQueries.length,
                (index) => _RecentSearchRow(
                  query: state.recentQueries[index],
                  isLast: index == state.recentQueries.length - 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
        ],
        const _SearchSectionLabel('Quick picks'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickPickLabels
                .map((label) => _QuickPill(label: label))
                .toList(),
          ),
        ),
        const SizedBox(height: 18),
        const _SearchSectionLabel('Popular this week'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _popularLabels
                .map((label) => _QuickPill(label: label))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _RecentSectionHeader extends ConsumerWidget {
  const _RecentSectionHeader({required this.queries});

  final List<String> queries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 12, 8),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Recent searches',
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: _wmSearchTextSoft),
            ),
          ),
          TextButton(
            onPressed: () async {
              for (final q in List<String>.from(queries)) {
                await ref.read(searchProvider.notifier).removeRecentQuery(q);
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: _wmSearchPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Clear all',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _SearchSectionLabel extends StatelessWidget {
  const _SearchSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: _wmSearchTextSoft),
      ),
    );
  }
}

class _RecentSearchRow extends ConsumerWidget {
  const _RecentSearchRow({required this.query, this.isLast = false});

  final String query;
  final bool isLast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () async {
          await ref.read(searchProvider.notifier).rerunRecent(query);
          FocusScope.of(context).unfocus();
        },
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : const Border(
                    bottom: BorderSide(color: Color(0xFFE8E8E8), width: 1)),
          ),
          child: Row(
            children: [
              const Icon(Icons.history_rounded,
                  size: 24, color: Color(0xFF6B7280)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  query,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14.6,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111111),
                      height: 1.1),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () =>
                    ref.read(searchProvider.notifier).removeRecentQuery(query),
                splashRadius: 18,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.close_rounded,
                    size: 24, color: Color(0xFF6B7280)),
                tooltip: 'Delete',
              ),
            ],
          ),
        ),
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
      color: Colors.white,
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
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _wmSearchBorder),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 1))
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _wmSearchTextStrong,
                height: 1.0),
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
                  offset: Offset(0, 5))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_rounded,
                  size: 42, color: _wmSearchPrimary),
              const SizedBox(height: 12),
              Text(
                'We couldn’t find a close match for "$query"',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _wmSearchTextStrong),
              ),
              const SizedBox(height: 8),
              const Text(
                'Try another name, brand, or a simpler keyword.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _wmSearchTextSoft),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
