import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:western_malabar/features/cart/providers/cart_provider.dart';
import 'package:western_malabar/features/cart/screens/cart_screen.dart';
import 'package:western_malabar/features/cart/widgets/sticky_cart_bar.dart';
import 'package:western_malabar/features/catalog/models/category_model.dart';
import 'package:western_malabar/features/catalog/services/category_service.dart';
import 'package:western_malabar/features/catalog/services/product_service.dart';
import 'package:western_malabar/features/checkout/models/address_model.dart';
import 'package:western_malabar/features/checkout/providers/address_provider.dart';
import 'package:western_malabar/features/checkout/screens/saved_addresses_screen.dart';
import 'package:western_malabar/features/search/providers/search_controller.dart';
import 'package:western_malabar/features/search/screens/global_product_search_screen.dart';
import 'package:western_malabar/shared/navigation/product_navigation.dart';
import 'package:western_malabar/shared/utils/cart_fly_target.dart';
import 'package:western_malabar/shared/utils/fly_to_cart.dart';
import 'package:western_malabar/shared/utils/haptic.dart';

const _wmPrimary = Color(0xFF202531);
const _wmPrimaryDark = Color(0xFF121722);
const _wmCanvas = Color(0xFFF7F7F7);
const _wmSurface = Colors.white;
const _wmTextStrong = Color(0xFF111827);
const _wmTextSoft = Color(0xFF6B7280);
const _wmTextMuted = Color(0xFF9CA3AF);
const _wmBorder = Color(0xFFE5E7EB);
const _wmBorderSoft = Color(0xFFF1F5F9);
const _wmSuccess = Color(0xFF15803D);
const _wmDeal = Color(0xFFF59E0B);
const _wmGold = Color(0xFFF59E0B);
const _wmSectionNeutral = Color(0xFF111827);
const _wmCta = Color(0xFFF4B400);
const _wmCtaSoft = Color(0xFFFFF7E0);
const _wmCtaText = Color(0xFF111827);
const _wmInfo = Color(0xFF1D4ED8);
const _wmInfoSoft = Color(0xFFEFF6FF);

String _gbp(int cents) => '£${(cents / 100.0).toStringAsFixed(2)}';
double _lerp(double a, double b, double t) => a + (b - a) * t;
double _clamp01(num v) => v.clamp(0.0, 1.0).toDouble();
String _cleanUiText(String text) =>
    text.replaceAll('Â£', '£').replaceAll('â€“', '–');
String _compactProductLabel(String text) {
  final words = text.trim().split(RegExp(r'\s+'));
  if (words.length <= 2) return text.trim();
  return '${words[0]} ${words[1]}';
}

final addingProductIdsProvider =
    StateProvider<Set<String>>((ref) => <String>{});

class WmProduct {
  final String id;
  final String name;
  final String? brandName;
  final int priceCents;
  final int? originalPriceCents;
  final String? imageUrl;
  final double? avgRating;
  final int? ratingCount;
  final ProductCursor? cursor;
  final String? sellerId;
  final int? sellerBasePriceCents;
  final int? rememberedQty;
  final bool isWeeklyDeal;
  final String? dealBadgeText;

  const WmProduct({
    required this.id,
    required this.name,
    required this.priceCents,
    this.originalPriceCents,
    this.brandName,
    this.imageUrl,
    this.avgRating,
    this.ratingCount,
    this.cursor,
    this.sellerId,
    this.sellerBasePriceCents,
    this.rememberedQty,
    this.isWeeklyDeal = false,
    this.dealBadgeText,
  });

  bool get hasPriceDrop =>
      originalPriceCents != null &&
      originalPriceCents! > 0 &&
      originalPriceCents! > priceCents;
  int? get savingCents =>
      hasPriceDrop ? (originalPriceCents! - priceCents) : null;
}

class _HomeRailBundle {
  final List<WmProduct> buyItAgain;
  final List<WmProduct> weeklyEssentials;
  final List<WmProduct> weeklyDeals;
  final List<WmProduct> newInStore;
  final List<WmProduct> popularThisWeek;
  final List<WmProduct> frozenFavourites;
  final List<CategoryModel> categories;

  const _HomeRailBundle({
    required this.buyItAgain,
    required this.weeklyEssentials,
    required this.weeklyDeals,
    required this.newInStore,
    required this.popularThisWeek,
    required this.frozenFavourites,
    required this.categories,
  });
}

class WmCategoryStyle {
  final Color bg;
  final Color fg;
  const WmCategoryStyle({required this.bg, required this.fg});
}

WmCategoryStyle _categoryStyleForSlug(String slug) {
  switch (slug) {
    case 'frozen':
      return const WmCategoryStyle(
          bg: Color(0xFFEFF6FF), fg: Color(0xFF2563EB));
    case 'rice-flour-grains':
      return const WmCategoryStyle(
          bg: Color(0xFFF0FDF4), fg: Color(0xFF15803D));
    case 'spices-masala':
      return const WmCategoryStyle(
          bg: Color(0xFFFFF7ED), fg: Color(0xFFEA580C));
    case 'snacks-sweets':
      return const WmCategoryStyle(
          bg: Color(0xFFFFF1F2), fg: Color(0xFFE11D48));
    case 'beverages':
      return const WmCategoryStyle(
          bg: Color(0xFFECFEFF), fg: Color(0xFF0891B2));
    case 'pantry-grocery':
      return const WmCategoryStyle(
          bg: Color(0xFFF5F3FF), fg: Color(0xFF7C3AED));
    default:
      return const WmCategoryStyle(
          bg: Color(0xFFF9FAFB), fg: Color(0xFF374151));
  }
}

String? _productBadgeText(WmProduct p) {
  final avg = p.avgRating ?? 0;
  final count = p.ratingCount ?? 0;
  if (avg >= 4.6 && count >= 8) return 'Top Rated';
  if (count >= 12) return 'Popular';
  return null;
}

Color _productBadgeColor(WmProduct p) {
  final avg = p.avgRating ?? 0;
  final count = p.ratingCount ?? 0;
  if (avg >= 4.6 && count >= 8) return _wmSuccess;
  if (count >= 12) return _wmDeal;
  return _wmPrimary;
}

String? _productTrustLine(WmProduct p) {
  final avg = p.avgRating ?? 0;
  final count = p.ratingCount ?? 0;
  if (avg >= 4.6 && count >= 8) return 'Customers love this';
  if (count >= 12) return 'Frequently added to baskets';
  if (count > 0) return 'Getting noticed';
  return null;
}

String? _productPriceCue(WmProduct p) {
  final avg = p.avgRating ?? 0;
  final count = p.ratingCount ?? 0;
  if (avg >= 4.6 && count >= 8) return 'Top rated';
  if (count >= 12) return 'Popular choice';
  return null;
}

WmProduct _mapDtoToProduct(WmProductDto p) {
  return WmProduct(
    id: p.id,
    name: p.name,
    brandName: p.brandName,
    priceCents: p.displayPriceCents,
    originalPriceCents: p.originalPriceCents,
    imageUrl: p.firstImageUrl,
    avgRating: p.avgRating,
    ratingCount: p.ratingCount,
    cursor: p.cursor,
    sellerId: p.sellerId,
    sellerBasePriceCents: p.sellerBasePriceCents,
    rememberedQty: p.rememberedQty,
    isWeeklyDeal: p.isWeeklyDeal,
    dealBadgeText: p.dealBadgeText,
  );
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends ConsumerState<HomeScreen> {
  late final ScrollController _c;
  late Future<_HomeRailBundle> _homeFuture;
  final _productSvc = ProductService();
  static const _searchHint = 'Search products';

  final _buyItAgainKey = GlobalKey();
  final _weeklyEssentialsKey = GlobalKey();
  final _newInStoreKey = GlobalKey();
  final _popularThisWeekKey = GlobalKey();
  final _frozenFavouritesKey = GlobalKey();
  final GlobalKey<_SearchFieldState> _searchKey =
      GlobalKey<_SearchFieldState>();

  @override
  void initState() {
    super.initState();
    _c = ScrollController();
    _homeFuture = _loadHomeBundle();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(searchProvider.notifier).hydrate();
    });
  }

  List<WmProduct> _uniqueRailProducts(
      List<WmProductDto> rows, Set<String> excluded,
      {int minItemsToShow = 1}) {
    final seen = <String>{};
    final filtered = <WmProductDto>[];
    for (final row in rows) {
      if (row.id.isEmpty) continue;
      if (excluded.contains(row.id)) continue;
      if (!seen.add(row.id)) continue;
      filtered.add(row);
    }
    if (filtered.length < minItemsToShow) return const <WmProduct>[];
    excluded.addAll(filtered.map((e) => e.id));
    return filtered.map(_mapDtoToProduct).toList();
  }

  List<WmProduct> _softRail(List<WmProductDto> rows, {int minItemsToShow = 1}) {
    final localSeen = <String>{};
    final filtered = <WmProductDto>[];
    for (final row in rows) {
      if (row.id.isEmpty) continue;
      if (!localSeen.add(row.id)) continue;
      filtered.add(row);
    }
    if (filtered.length < minItemsToShow) return const <WmProduct>[];
    return filtered.map(_mapDtoToProduct).toList();
  }

  void _reloadHome() => _homeFuture = _loadHomeBundle();

  Future<_HomeRailBundle> _loadHomeBundle() async {
    final results = await Future.wait<dynamic>([
      _productSvc.fetchBuyItAgain(limit: 12),
      _productSvc.fetchWeeklyEssentials(limit: 12),
      _productSvc.fetchWeeklyDeals(limit: 12),
      _productSvc.fetchPopularThisWeek(limit: 12),
      _productSvc.fetchFrozenFavourites(limit: 12),
      _productSvc.fetchNewInStore(limit: 12),
      CategoryService.fetchHomeCategories(limit: 12),
    ]);

    final buyAgainRows = results[0] as List<WmProductDto>;
    final essentialsRows = results[1] as List<WmProductDto>;
    final dealsRows = results[2] as List<WmProductDto>;
    final popularRows = results[3] as List<WmProductDto>;
    final frozenRows = results[4] as List<WmProductDto>;
    final newRows = results[5] as List<WmProductDto>;
    final categories = results[6] as List<CategoryModel>;

    final priorityExcluded = <String>{};
    final buyItAgain =
        _uniqueRailProducts(buyAgainRows, priorityExcluded, minItemsToShow: 3);
    final weeklyEssentials = _uniqueRailProducts(
        essentialsRows, priorityExcluded,
        minItemsToShow: 1);

    return _HomeRailBundle(
      buyItAgain: buyItAgain,
      weeklyEssentials: weeklyEssentials,
      weeklyDeals: _softRail(dealsRows),
      newInStore: _softRail(newRows),
      popularThisWeek: _softRail(popularRows),
      frozenFavourites: _softRail(frozenRows),
      categories: categories,
    );
  }

  Future<void> _refresh() async {
    setState(_reloadHome);
    await _homeFuture;
  }

  Future<void> _scrollToSection(GlobalKey key) async {
    final targetContext = key.currentContext;
    if (targetContext == null) return;
    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  String _homeAddressLabel(AddressModel? address) {
    if (address == null) return 'Choose delivery address';
    final label = address.label.trim();
    final line1 = address.addressLine1.trim();
    final city = address.city.trim();
    final postcode = address.postcode.trim().toUpperCase();
    final primary = line1.isNotEmpty ? line1 : (city.isNotEmpty ? city : label);
    final secondary = postcode.isNotEmpty ? postcode : city;
    if (primary.isNotEmpty && secondary.isNotEmpty)
      return 'Deliver to $primary, $secondary';
    if (primary.isNotEmpty) return 'Deliver to $primary';
    return 'Choose delivery address';
  }

  String _homeAddressSubtitle(AddressModel? address) {
    if (address == null) return 'Add an address to see delivery options';
    return 'Tap to update your delivery address';
  }

  Future<void> _openSearch() async {
    final controller = ref.read(searchProvider.notifier);
    await controller.hydrate();
    controller.collapseForHome();
    if (!mounted) return;
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => const GlobalProductSearchScreen()));
  }

  Future<void> _openSavedAddresses() async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => const SavedAddressesScreen()));
    if (!mounted) return;
    ref.invalidate(addressesProvider);
    ref.invalidate(defaultAddressProvider);
  }

  Future<void> _openCart() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const CartScreen(),
      ),
    );
  }

  void _openProduct(WmProduct product) {
    openProductDetail(context, productId: product.id);
  }

  void scrollToTop() {
    if (!_c.hasClients) return;
    _c.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    const expandedHeight = 176.0;
    const collapsedHeight = 64.0;

    final cartItems = ref.watch(cartProvider);
    final cartCount = cartItems.fold<int>(0, (sum, item) => sum + item.qty);
    final cartSubtotalCents = cartItems.fold<int>(
        0,
        (sum, item) =>
            sum +
            (((item.product.salePriceCents ?? item.product.priceCents ?? 0)) *
                item.qty));
    final defaultAddressAsync = ref.watch(defaultAddressProvider);

    return Scaffold(
      backgroundColor: _wmCanvas,
      body: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: _wmCanvas)),
          RefreshIndicator(
            onRefresh: _refresh,
            color: _wmPrimary,
            child: CustomScrollView(
              controller: _c,
              cacheExtent: 1400,
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  floating: true,
                  snap: true,
                  expandedHeight: expandedHeight,
                  collapsedHeight: collapsedHeight,
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  flexibleSpace: LayoutBuilder(
                    builder: (context, c) {
                      final h = c.biggest.height;
                      final t = _clamp01(1 -
                          ((h - kToolbarHeight - topPad) /
                              (expandedHeight - kToolbarHeight - topPad)));
                      const searchHExpanded = 52.0;
                      const searchHCollapsed = 42.0;
                      final searchTopExpanded = topPad + 42;
                      final searchTopCollapsed =
                          topPad + (kToolbarHeight - searchHCollapsed) / 2;
                      final searchTop =
                          _lerp(searchTopExpanded, searchTopCollapsed, t);
                      final searchH =
                          _lerp(searchHExpanded, searchHCollapsed, t);

                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRect(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: const SizedBox.expand(),
                            ),
                          ),
                          Positioned.fill(
                            child: IgnorePointer(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOut,
                                color: const Color(0xFFF7F7F7)
                                    .withValues(alpha: _lerp(0.0, 0.96, t)),
                              ),
                            ),
                          ),
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 140),
                            curve: Curves.easeOutCubic,
                            left: 16,
                            right: 16,
                            top: searchTop,
                            height: searchH,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              curve: Curves.easeOutCubic,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: t > 0.55
                                      ? const Color(0xFFD5DAE1)
                                      : _wmBorder,
                                  width: 1,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Color(0x0A000000),
                                      blurRadius: 8,
                                      offset: Offset(0, 2))
                                ],
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              alignment: Alignment.centerLeft,
                              child: _SearchField(
                                key: _searchKey,
                                hint: _searchHint,
                              ),
                            ),
                          ),
                          Positioned(
                            left: 16,
                            right: 16,
                            top: searchTop + searchH + _lerp(12, 0, t),
                            child: Opacity(
                              opacity: (1 - t).clamp(0.0, 1.0),
                              child: _LocationPill(
                                label: defaultAddressAsync.when(
                                  data: _homeAddressLabel,
                                  loading: () => 'Choose delivery address',
                                  error: (_, __) => 'Choose delivery address',
                                ),
                                subtitle: defaultAddressAsync.when(
                                  data: _homeAddressSubtitle,
                                  loading: () =>
                                      'Add an address to see delivery options',
                                  error: (_, __) =>
                                      'Add an address to see delivery options',
                                ),
                                onTap: _openSavedAddresses,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: FutureBuilder<_HomeRailBundle>(
                    future: _homeFuture,
                    builder: (context, snap) {
                      final waiting =
                          snap.connectionState == ConnectionState.waiting;
                      final data = snap.data;

                      if (waiting && data == null) {
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          child: Column(
                            key: const ValueKey('home_loading'),
                            children: const [
                              Padding(
                                  padding: EdgeInsets.fromLTRB(16, 10, 16, 12),
                                  child: _CategoryRowSkeleton()),
                              Padding(
                                  padding: EdgeInsets.fromLTRB(16, 6, 16, 10),
                                  child: _PromoSkeleton()),
                              _HomeSectionSkeleton(
                                  title: 'Weekly essentials',
                                  subtitleWidth: 220),
                              _HomeSectionSkeleton(
                                  title: 'New in store', subtitleWidth: 170),
                              _HomeSectionSkeleton(
                                  title: 'Popular this week',
                                  subtitleWidth: 180),
                              SizedBox(height: 116),
                            ],
                          ),
                        );
                      }

                      if (snap.hasError || data == null) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 116),
                          child: _HomeLoadError(
                            onRetry: () {
                              setState(_reloadHome);
                            },
                            onSearch: () {
                              _openSearch();
                            },
                          ),
                        );
                      }
                      final bundle = data;
                      final buyAgainIds =
                          bundle.buyItAgain.map((e) => e.id).toSet();
                      final cartProductIds =
                          cartItems.map((item) => item.product.id).toSet();
                      final missingStaples = bundle.weeklyEssentials
                          .where((item) => cartCount > 0
                              ? !cartProductIds.contains(item.id)
                              : !buyAgainIds.contains(item.id))
                          .take(4)
                          .toList();
                      final quickEssentials = (cartCount > 0
                              ? missingStaples
                              : bundle.weeklyEssentials)
                          .take(3)
                          .toList();

                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeOut,
                        child: Column(
                          key: const ValueKey('home_loaded'),
                          children: [
                            if (cartCount > 0)
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 10, 16, 10),
                                child: _CartMomentumCard(
                                  itemCount: cartCount,
                                  subtotalCents: cartSubtotalCents,
                                  cartItems: cartItems,
                                  onPrimary: () {
                                    _openCart();
                                  },
                                  onSecondary: () {
                                    _openSearch();
                                  },
                                ),
                              )
                            else if (bundle.buyItAgain.isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 10, 16, 10),
                                child: _ReorderHeroCard(
                                  items: bundle.buyItAgain,
                                  onPrimary: () {
                                    _scrollToSection(_buyItAgainKey);
                                  },
                                  onSecondary: () {
                                    _openSearch();
                                  },
                                  onPreviewTap: _openProduct,
                                ),
                              ),
                            if (missingStaples.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                                child: _MissingStaplesCard(
                                  items: missingStaples,
                                  title: cartCount > 0
                                      ? 'Finish your weekly staples'
                                      : 'You may need these this week',
                                  subtitle: cartCount > 0
                                      ? 'A few staples are still missing.'
                                      : 'Likely staples, surfaced early.',
                                  onItemTap: _openProduct,
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                              child: _BasketProgressCard(
                                  subtotalCents: cartSubtotalCents,
                                  suggestions: quickEssentials,
                                  onTap: () {
                                    if (cartCount > 0) {
                                      _openCart();
                                    } else {
                                      _openSearch();
                                    }
                                  },
                                  onSuggestionTap: _openProduct),
                            ),
                            if (bundle.buyItAgain.isNotEmpty)
                              _StaticProductRailSection(
                                key: _buyItAgainKey,
                                title: 'Buy it again',
                                subtitle: 'Your usuals, ready faster.',
                                items: bundle.buyItAgain,
                                compact: true,
                                prominent: true,
                              ),
                            _StaticProductRailSection(
                              key: _weeklyEssentialsKey,
                              title: 'Weekly essentials',
                              subtitle: 'Fast basket builders.',
                              items: bundle.weeklyEssentials,
                              prominent: true,
                            ),
                            if (bundle.categories.isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 2, 16, 12),
                                child: _RoundedCategoryRow(
                                  items: bundle.categories
                                      .map((c) => RoundedCat(
                                            label: c.name,
                                            icon: _iconForSlug(c.slug),
                                            style:
                                                _categoryStyleForSlug(c.slug),
                                          ))
                                      .toList(),
                                ),
                              ),
                            if (bundle.weeklyDeals.isNotEmpty)
                              const Padding(
                                padding: EdgeInsets.fromLTRB(16, 4, 16, 10),
                                child: WmPromoAutoCarousel(),
                              ),
                            _StaticProductRailSection(
                              key: _newInStoreKey,
                              title: 'New in store',
                              subtitle: 'Fresh arrivals.',
                              items: bundle.newInStore,
                              emptyTrustLabel: 'New in store',
                              surfaceTint: const Color(0xFFFFFBF4),
                              badgeTextOverride: 'New',
                            ),
                            _StaticProductRailSection(
                              key: _popularThisWeekKey,
                              title: 'Popular this week',
                              subtitle: 'Most added this week.',
                              items: bundle.popularThisWeek,
                            ),
                            if (bundle.frozenFavourites.isNotEmpty)
                              _StaticProductRailSection(
                                key: _frozenFavouritesKey,
                                title: 'Frozen favourites',
                                subtitle: 'Easy stock-up picks.',
                                items: bundle.frozenFavourites,
                              ),
                            const SizedBox(height: 116),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (cartCount > 0) const StickyCartBar(bottom: 64),
        ],
      ),
    );
  }

  IconData _iconForSlug(String slug) {
    switch (slug) {
      case 'frozen':
        return Icons.ac_unit_outlined;
      case 'rice-flour-grains':
        return Icons.rice_bowl_outlined;
      case 'spices-masala':
        return Icons.auto_awesome_outlined;
      case 'snacks-sweets':
        return Icons.cookie_outlined;
      case 'beverages':
        return Icons.local_cafe_outlined;
      case 'pantry-grocery':
        return Icons.shopping_basket_outlined;
      default:
        return Icons.category_outlined;
    }
  }
}

class _BasketProgressCard extends StatelessWidget {
  const _BasketProgressCard(
      {required this.subtotalCents,
      this.targetCents = 3000,
      this.onTap,
      this.suggestions = const <WmProduct>[],
      this.onSuggestionTap});
  final int subtotalCents;
  final int targetCents;
  final VoidCallback? onTap;
  final List<WmProduct> suggestions;
  final ValueChanged<WmProduct>? onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    final remaining = (targetCents - subtotalCents).clamp(0, targetCents);
    final progress = (subtotalCents / targetCents).clamp(0.0, 1.0);
    final unlocked = remaining <= 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _wmBorder),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 10,
                  offset: Offset(0, 4))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: unlocked ? _wmCtaSoft : _wmInfoSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      unlocked
                          ? Icons.local_shipping_rounded
                          : Icons.shopping_bag_rounded,
                      color: unlocked ? _wmDeal : _wmInfo,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      unlocked
                          ? 'Free delivery unlocked'
                          : '${_gbp(remaining)} away from free delivery',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _wmTextStrong),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFF3F4F6),
                  valueColor: const AlwaysStoppedAnimation(_wmDeal),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                unlocked
                    ? 'Ready to check out.'
                    : 'Add a little more for free delivery.',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _wmTextSoft),
              ),
              if (suggestions.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Quick picks',
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: _wmTextSoft),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: suggestions
                      .map((item) => _QuickSuggestionChip(
                            item: item,
                            onTap: onSuggestionTap == null
                                ? null
                                : () => onSuggestionTap!(item),
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReorderHeroCard extends StatelessWidget {
  const _ReorderHeroCard(
      {required this.items,
      required this.onPrimary,
      required this.onSecondary,
      required this.onPreviewTap});

  final List<WmProduct> items;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;
  final ValueChanged<WmProduct> onPreviewTap;

  @override
  Widget build(BuildContext context) {
    final previewItems = items.take(4).toList();
    final extraCount = items.length - previewItems.length;
    final estimatedTotal = items.fold<int>(0, (sum, item) => sum + item.priceCents);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF111827), Color(0xFF1F2937)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
              color: Color(0x18000000), blurRadius: 18, offset: Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: const Text(
              'YOUR USUALS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.7,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Continue your weekly basket',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.45,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${items.length} items | est. ${_gbp(estimatedTotal)}',
            style: const TextStyle(
              color: Color(0xFFE5E7EB),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final item in previewItems)
                _ReorderPreviewChip(item: item, onTap: () => onPreviewTap(item)),
              if (extraCount > 0)
                Container(
                  width: 76,
                  height: 88,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.10)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '+$extraCount more',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onPrimary,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _wmPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Resume basket',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onSecondary,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.24)),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Edit items',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CartMomentumCard extends StatelessWidget {
  const _CartMomentumCard({
    required this.itemCount,
    required this.subtotalCents,
    required this.cartItems,
    required this.onPrimary,
    required this.onSecondary,
  });

  final int itemCount;
  final int subtotalCents;
  final List<CartItem> cartItems;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    final remaining = (3000 - subtotalCents).clamp(0, 3000);
    final readyForCheckout = remaining == 0;
    final previewNames = cartItems
        .map((item) => _compactProductLabel(item.product.name))
        .toSet()
        .take(3)
        .toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF111827), Color(0xFF1F2937)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
              color: Color(0x18000000), blurRadius: 18, offset: Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: const Text(
              'BASKET IN PROGRESS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.7,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            readyForCheckout
                ? 'You are ready to check out'
                : 'Your basket is already in motion',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.45,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$itemCount items | ${_gbp(subtotalCents)}'
            '${readyForCheckout ? ' | ready' : ' | ${_gbp(remaining)} to free delivery'}',
            style: const TextStyle(
              color: Color(0xFFE5E7EB),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          if (previewNames.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: previewNames
                  .map(
                    (label) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.10)),
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onPrimary,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _wmPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Continue to basket',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onSecondary,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.24)),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Add missing items',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReorderPreviewChip extends StatelessWidget {
  const _ReorderPreviewChip({required this.item, required this.onTap});

  final WmProduct item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          width: 76,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  height: 48,
                  width: 48,
                  child: item.imageUrl == null || item.imageUrl!.isEmpty
                      ? Container(
                          color: Colors.white.withValues(alpha: 0.12),
                          alignment: Alignment.center,
                          child: const Icon(Icons.shopping_basket_outlined,
                              color: Colors.white70, size: 22),
                        )
                      : CachedNetworkImage(
                          imageUrl: item.imageUrl!,
                          fit: BoxFit.cover,
                          memCacheWidth: 180,
                          fadeInDuration: const Duration(milliseconds: 100),
                          placeholder: (_, __) => Container(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.white.withValues(alpha: 0.12),
                            alignment: Alignment.center,
                            child: const Icon(Icons.shopping_basket_outlined,
                                color: Colors.white70, size: 22),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissingStaplesCard extends StatelessWidget {
  const _MissingStaplesCard(
      {required this.items,
      required this.onItemTap,
      this.title = 'You may need these this week',
      this.subtitle = 'Likely staples, surfaced early.'});

  final List<WmProduct> items;
  final ValueChanged<WmProduct> onItemTap;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _wmCtaSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.playlist_add_check_rounded,
                    color: _wmDeal, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _wmTextStrong,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: _wmTextSoft,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items
                .map((item) => _QuickSuggestionChip(
                      item: item,
                      onTap: () => onItemTap(item),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _QuickSuggestionChip extends StatelessWidget {
  const _QuickSuggestionChip({required this.item, this.onTap});

  final WmProduct item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _compactProductLabel(item.name),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: _wmTextStrong,
                    fontSize: 12,
                    fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 8),
              Text(
                _gbp(item.priceCents),
                style: const TextStyle(
                    color: _wmSuccess,
                    fontSize: 12,
                    fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeLoadError extends StatelessWidget {
  const _HomeLoadError({required this.onRetry, required this.onSearch});

  final VoidCallback onRetry;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _wmBorder),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _wmInfoSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.wifi_off_rounded, color: _wmInfo),
          ),
          const SizedBox(height: 14),
          const Text(
            'Home is unavailable right now',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: _wmTextStrong,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try loading the latest sections again, or use search to keep shopping.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _wmTextSoft,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onRetry,
                  style: FilledButton.styleFrom(
                    backgroundColor: _wmPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Try again',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onSearch,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _wmTextStrong,
                    side: const BorderSide(color: _wmBorder),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Open search',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocationPill extends StatelessWidget {
  const _LocationPill({required this.label, this.subtitle, this.onTap});
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasSubtitle = subtitle != null && subtitle!.trim().isNotEmpty;
    final effectiveSubtitle = !hasSubtitle
        ? null
        : subtitle!.contains('Tomorrow')
            ? (label == 'Choose delivery address'
                ? 'Add an address to see delivery options'
                : 'Tap to update your delivery address')
            : _cleanUiText(subtitle!);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _wmBorder),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x0C000000), blurRadius: 8, offset: Offset(0, 3))
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                    color: _wmInfoSoft,
                    borderRadius: BorderRadius.circular(999)),
                child: const Icon(Icons.location_on_rounded,
                    size: 16, color: _wmInfo),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _cleanUiText(label),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: _wmTextStrong),
                    ),
                    if (effectiveSubtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          effectiveSubtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: _wmSuccess),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  size: 18, color: _wmTextSoft),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(
      {required this.title,
      required this.subtitle,
      this.actionText,
      this.onAction,
      this.prominent = false});
  final String title;
  final String subtitle;
  final String? actionText;
  final VoidCallback? onAction;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: _wmSectionNeutral,
                  fontSize: prominent ? 24 : 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.35,
                  height: 1.08,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(
                    color: _wmTextSoft,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.22),
              ),
            ],
          ),
        ),
        if (actionText != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
                foregroundColor: _wmTextStrong,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
            child: Text(actionText!,
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          ),
      ],
    );
  }
}

class _StaticProductRailSection extends StatelessWidget {
  const _StaticProductRailSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.items,
    this.actionText,
    this.compact = false,
    this.emptyTrustLabel,
    this.surfaceTint,
    this.badgeTextOverride,
    this.prominent = false,
    this.emphasizeDeals = false,
  });

  final String title;
  final String subtitle;
  final List<WmProduct> items;
  final String? actionText;
  final bool compact;
  final String? emptyTrustLabel;
  final Color? surfaceTint;
  final String? badgeTextOverride;
  final bool prominent;
  final bool emphasizeDeals;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final railHeight = compact ? 286.0 : 308.0;
    final cardWidth = compact ? 168.0 : 176.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(0, prominent ? 12 : 10, 0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _SectionHeader(
                title: title,
                subtitle: subtitle,
                actionText: actionText,
                onAction: null,
                prominent: prominent),
          ),
          SizedBox(
            height: railHeight,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, i) {
                final p = items[i];
                return SizedBox(
                  width: cardWidth,
                  child: _ProductTile(
                    product: p,
                    compact: compact,
                    emptyTrustLabel: emptyTrustLabel,
                    surfaceTint: surfaceTint,
                    badgeTextOverride: badgeTextOverride,
                    emphasizeDeals: emphasizeDeals,
                    onTap: (_) => openProductDetail(context, productId: p.id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeSectionSkeleton extends StatelessWidget {
  const _HomeSectionSkeleton({required this.title, this.subtitleWidth = 180});
  final String title;
  final double subtitleWidth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: _wmSectionNeutral,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4)),
                const SizedBox(height: 5),
                Container(
                    width: subtitleWidth,
                    height: 12,
                    decoration: BoxDecoration(
                        color: _wmBorderSoft,
                        borderRadius: BorderRadius.circular(999))),
              ],
            ),
          ),
          SizedBox(
            height: 308,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 2,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, __) =>
                  const SizedBox(width: 176, child: _RailProductSkeleton()),
            ),
          ),
        ],
      ),
    );
  }
}

class _RailProductSkeleton extends StatelessWidget {
  const _RailProductSkeleton();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _wmSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _wmBorder),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 3))
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 150,
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _ShimmerBar(width: 72, height: 10),
                  SizedBox(height: 10),
                  _ShimmerBar(width: double.infinity, height: 14),
                  SizedBox(height: 8),
                  _ShimmerBar(width: 108, height: 12),
                  Spacer(),
                  _ShimmerBar(width: 72, height: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerBar extends StatelessWidget {
  const _ShimmerBar({required this.width, required this.height});
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
            color: const Color(0xFFD1D5DB),
            borderRadius: BorderRadius.circular(999)),
      ),
    );
  }
}

class _SearchField extends ConsumerStatefulWidget {
  const _SearchField({super.key, required this.hint});
  final String hint;
  @override
  ConsumerState<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<_SearchField> {
  Future<void> _openSearch() async {
    final controller = ref.read(searchProvider.notifier);
    await controller.hydrate();
    controller.collapseForHome();
    if (!mounted) return;
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => const GlobalProductSearchScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: _openSearch,
        child: SizedBox(
          height: double.infinity,
          child: Row(
            children: [
              const SizedBox(width: 2),
              const Icon(Icons.search_rounded,
                  color: Color(0xFF374151), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                              begin: const Offset(0, 0.08), end: Offset.zero)
                          .animate(animation),
                      child: child,
                    ),
                  ),
                  child: Text(
                    widget.hint,
                    key: ValueKey(widget.hint),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: _wmTextSoft,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1),
                  ),
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _wmBorder)),
                child: const Icon(Icons.arrow_forward_rounded,
                    size: 16, color: _wmPrimary),
              ),
              const SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductTile extends ConsumerStatefulWidget {
  const _ProductTile(
      {required this.product,
      this.onTap,
      this.compact = false,
      this.emptyTrustLabel,
      this.surfaceTint,
      this.badgeTextOverride,
      this.emphasizeDeals = false});
  final WmProduct product;
  final void Function(WmProduct product)? onTap;
  final bool compact;
  final String? emptyTrustLabel;
  final Color? surfaceTint;
  final String? badgeTextOverride;
  final bool emphasizeDeals;

  @override
  ConsumerState<_ProductTile> createState() => _ProductTileState();
}

class _ProductTileState extends ConsumerState<_ProductTile> {
  bool _pressed = false;
  final GlobalKey _imageKey = GlobalKey();

  void _showStockLimitMessage(int? qty) {
    if (!mounted) return;
    final message =
        qty != null && qty > 0 ? 'Only $qty left' : 'No more stock available';
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleAdd(WmProduct p, {int quantity = 1}) async {
    final addingIds = ref.read(addingProductIdsProvider);
    if (addingIds.contains(p.id)) return;
    Haptic.light(context);
    ref.read(addingProductIdsProvider.notifier).state = {...addingIds, p.id};
    try {
      final svc = ProductService();
      final full = await svc.fetchProductModelById(p.id);
      if (!mounted) return;
      if (full == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Unable to add item right now'),
            behavior: SnackBarBehavior.floating));
        return;
      }
      final cartState = ref.read(cartProvider.notifier);
      final currentQty = cartState.quantityFor(full.id);
      final maxQty = full.maxCartQuantity;
      final remainingQty = maxQty == null ? quantity : (maxQty - currentQty);
      if (remainingQty <= 0) {
        _showStockLimitMessage(full.stockQty);
        return;
      }
      final addCount = maxQty == null
          ? (quantity < 1 ? 1 : quantity)
          : (quantity < 1 ? 1 : quantity).clamp(1, remainingQty);
      for (var i = 0; i < addCount; i++) {
        final added = cartState.add(full);
        if (!added) {
          _showStockLimitMessage(full.stockQty);
          break;
        }
      }
      Haptic.medium(context);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await flyToCart(
          context: context, cartKey: wmBottomCartNavKey, imageKey: _imageKey);
    } finally {
      if (mounted) {
        final ids = ref.read(addingProductIdsProvider);
        final updated = {...ids}..remove(p.id);
        ref.read(addingProductIdsProvider.notifier).state = updated;
      }
    }
  }

  Widget _buildQuantityControl(WmProduct p, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final addingIds = ref.watch(addingProductIdsProvider);
    final isAdding = addingIds.contains(p.id);
    final matches = cart.where((e) => e.product.id == p.id);
    final item = matches.isNotEmpty ? matches.first : null;
    final qty = item?.qty ?? 0;
    final maxQty = item?.product.maxCartQuantity;
    final canIncrease = item == null
        ? true
        : item.product.canAddToCartQuantity(qty);

    if (qty == 0) {
      final suggestedQty = ((p.rememberedQty ?? 1).clamp(1, 6)) as int;
      return SizedBox(
        height: 36,
        child: ElevatedButton(
          onPressed:
              isAdding ? null : () => _handleAdd(p, quantity: suggestedQty),
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: _wmCta,
            foregroundColor: _wmCtaText,
            disabledBackgroundColor: const Color(0xFFE5E7EB),
            disabledForegroundColor: _wmTextSoft,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: isAdding
              ? const SizedBox(
                  height: 15,
                  width: 15,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _wmTextStrong))
              : Text(suggestedQty > 1 ? 'Add usual' : 'Add',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800)),
        ),
      );
    }

    return Container(
      height: 36,
      decoration: BoxDecoration(
          color: _wmPrimary, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 34,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.remove, size: 16, color: Colors.white),
              onPressed: () {
                Haptic.light(context);
                ref.read(cartProvider.notifier).dec(item!.product);
              },
            ),
          ),
          Text('$qty',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13)),
          SizedBox(
            width: 34,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.add, size: 16, color: Colors.white),
              onPressed: () {
                if (!canIncrease) {
                  _showStockLimitMessage(maxQty);
                  return;
                }
                Haptic.light(context);
                final added = ref.read(cartProvider.notifier).inc(item!.product);
                if (!added) {
                  _showStockLimitMessage(maxQty);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingRow(WmProduct p) {
    final avg = p.avgRating;
    final count = p.ratingCount ?? 0;
    if (avg == null || count <= 0) {
      return const SizedBox(
        height: 16,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('No ratings yet',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 12,
                  color: _wmTextSoft,
                  fontWeight: FontWeight.w500,
                  height: 1.1)),
        ),
      );
    }
    final fullStars = avg.floor().clamp(0, 5);
    return SizedBox(
      height: 16,
      child: Row(
        children: [
          ...List.generate(
              5,
              (index) => Icon(
                  index < fullStars
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  size: 13,
                  color: _wmGold)),
          const SizedBox(width: 4),
          Flexible(
            child: Text('${avg.toStringAsFixed(1)} ($count)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12,
                    color: _wmTextSoft,
                    fontWeight: FontWeight.w600,
                    height: 1.1)),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(WmProduct p) {
    Widget placeholderIcon({double size = 36}) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [Colors.white, Color(0xFFF8FAFC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
                right: -12,
                top: -12,
                child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(999)))),
            Positioned(
                left: -10,
                bottom: -10,
                child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                        color: const Color(0xFFEFF1F5),
                        borderRadius: BorderRadius.circular(999)))),
            Center(
                child: Icon(Icons.shopping_basket_outlined,
                    size: size, color: Colors.black26)),
          ],
        ),
      );
    }

    final imageWidget = p.imageUrl == null || p.imageUrl!.isEmpty
        ? placeholderIcon(size: 38)
        : DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.white, Color(0xFFF8FAFC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
            ),
            child: CachedNetworkImage(
              imageUrl: p.imageUrl!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              memCacheWidth: 500,
              maxWidthDiskCache: 800,
              filterQuality: FilterQuality.low,
              fadeInDuration: const Duration(milliseconds: 120),
              placeholder: (_, __) => placeholderIcon(size: 34),
              errorWidget: (_, __, ___) => placeholderIcon(size: 34),
            ),
          );

    return Container(
      decoration: const BoxDecoration(
          border:
              Border(bottom: BorderSide(color: Color(0x11000000), width: 1))),
      child: imageWidget,
    );
  }

  Widget? _buildTopBadge(WmProduct p) {
    final weeklyDealText = widget.emphasizeDeals && p.isWeeklyDeal
        ? ((p.dealBadgeText ?? '').trim().isNotEmpty
            ? p.dealBadgeText!.trim()
            : 'Weekly Deal')
        : null;
    final text =
        widget.badgeTextOverride ?? weeklyDealText ?? _productBadgeText(p);
    if (text == null) return null;
    final bg = widget.badgeTextOverride != null
        ? _wmDeal
        : weeklyDealText != null
            ? _wmDeal
            : _productBadgeColor(p);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [
            BoxShadow(
                color: Color(0x18000000), blurRadius: 6, offset: Offset(0, 2))
          ]),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              height: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final compact = widget.compact;
    final imageFlex = compact ? 7 : 8;
    final bodyFlex = compact ? 9 : 10;
    final badge = _buildTopBadge(p);
    final trustLine = _productTrustLine(p) ?? widget.emptyTrustLabel;

    return RepaintBoundary(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: () => widget.onTap?.call(p),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          scale: _pressed ? 0.985 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            decoration: BoxDecoration(
              color: widget.surfaceTint ?? _wmSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: _pressed
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFFE7EBF0)),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x0F111827),
                    blurRadius: 16,
                    offset: Offset(0, 6))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: imageFlex,
                  child: ClipRRect(
                    key: _imageKey,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        SizedBox(width: double.infinity, child: _buildImage(p)),
                        if (badge != null)
                          Positioned(left: 10, top: 10, child: badge),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: bodyFlex,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(12, compact ? 8 : 10, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: compact ? 15 : 16,
                              height: 1.2,
                              color: _wmTextStrong),
                        ),
                        const SizedBox(height: 4),
                        if (p.brandName != null &&
                            p.brandName!.trim().isNotEmpty)
                          Text(
                            p.brandName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12,
                                color: _wmTextSoft,
                                fontWeight: FontWeight.w700,
                                height: 1.1),
                          )
                        else
                          const SizedBox(height: 14),
                        const SizedBox(height: 6),
                        if ((p.ratingCount ?? 0) > 0)
                          _buildRatingRow(p)
                        else if (trustLine != null)
                          Text(trustLine,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: _wmTextSoft,
                                  fontWeight: FontWeight.w700))
                        else
                          const SizedBox(height: 16),
                        const Spacer(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (widget.emphasizeDeals &&
                                      p.hasPriceDrop &&
                                      p.originalPriceCents != null) ...[
                                    Text(_gbp(p.originalPriceCents!),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: _wmTextSoft,
                                            decoration:
                                                TextDecoration.lineThrough,
                                            decorationThickness: 2)),
                                    const SizedBox(height: 2),
                                  ],
                                  Text(_gbp(p.priceCents),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: compact ? 18 : 20,
                                          color: _wmSuccess,
                                          letterSpacing: -0.25)),
                                  if (widget.emphasizeDeals &&
                                      p.hasPriceDrop &&
                                      p.savingCents != null) ...[
                                    const SizedBox(height: 2),
                                    Text('Save ${_gbp(p.savingCents!)}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: _wmSuccess)),
                                  ] else if (_productPriceCue(p) != null) ...[
                                    const SizedBox(height: 2),
                                    Text(_productPriceCue(p)!,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: _wmSuccess)),
                                  ],
                                ],
                              ),
                            ),
                            _buildQuantityControl(p, ref),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RoundedCat {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final WmCategoryStyle? style;
  RoundedCat({required this.label, required this.icon, this.onTap, this.style});
}

class _RoundedCategoryRow extends StatelessWidget {
  const _RoundedCategoryRow({required this.items});
  final List<RoundedCat> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        physics: const ClampingScrollPhysics(),
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) => _CategoryQuickTile(item: items[i]),
      ),
    );
  }
}

class _CategoryQuickTile extends StatefulWidget {
  const _CategoryQuickTile({required this.item});
  final RoundedCat item;

  @override
  State<_CategoryQuickTile> createState() => _CategoryQuickTileState();
}

class _CategoryQuickTileState extends State<_CategoryQuickTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final it = widget.item;
    final isInteractive = it.onTap != null;
    final style =
        it.style ?? const WmCategoryStyle(bg: Colors.white, fg: _wmPrimaryDark);
    return GestureDetector(
      onTapDown: isInteractive ? (_) => setState(() => _pressed = true) : null,
      onTapCancel: isInteractive ? () => setState(() => _pressed = false) : null,
      onTapUp: isInteractive ? (_) => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: _pressed ? 0.97 : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: it.onTap,
            borderRadius: BorderRadius.circular(18),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  height: 68,
                  width: 68,
                  decoration: BoxDecoration(
                    color: style.bg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: _pressed
                            ? style.fg.withValues(alpha: 0.24)
                            : _wmBorder),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x08000000),
                          blurRadius: 10,
                          offset: Offset(0, 3))
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Icon(it.icon, color: style.fg),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 96,
                  child: Text(it.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          height: 1.15,
                          color: _wmTextStrong)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WmPromoAutoCarousel extends StatefulWidget {
  const WmPromoAutoCarousel({super.key});
  @override
  State<WmPromoAutoCarousel> createState() => _WmPromoAutoCarouselState();
}

class _WmPromoAutoCarouselState extends State<WmPromoAutoCarousel> {
  final _ctrl = PageController(viewportFraction: .92);
  int _page = 0;

  final _items = const <_PromoItem>[
    _PromoItem(
        title: 'Offers of the week',
        subtitle:
            'Build your basket smarter and unlock free delivery over £30.',
        icon: Icons.local_shipping_outlined,
        colors: [Color(0xFF111827), Color(0xFF334155)]),
    _PromoItem(
        title: 'Best value this week',
        subtitle: 'Sharp pricing on staples without the bargain-bin feel.',
        icon: Icons.local_offer_outlined,
        colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
    _PromoItem(
        title: 'Kitchen staples to start with',
        subtitle: 'A strong first basket starts with the right essentials.',
        icon: Icons.shopping_basket_outlined,
        colors: [Color(0xFF4B5563), Color(0xFF6B7280)]),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 148,
          child: PageView.builder(
            controller: _ctrl,
            itemCount: _items.length,
            onPageChanged: (i) => setState(() => _page = i),
            physics: const ClampingScrollPhysics(),
            itemBuilder: (_, i) => _PromoCard(item: _items[i]),
          ),
        ),
        const SizedBox(height: 8),
        _Dots(count: _items.length, index: _page),
      ],
    );
  }
}

class _PromoItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  const _PromoItem(
      {required this.title,
      required this.subtitle,
      required this.icon,
      required this.colors});
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.item});
  final _PromoItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: item.colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                height: 58,
                width: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.20),
                  ),
                ),
                child: Icon(item.icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _cleanUiText(item.title),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 19,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _cleanUiText(item.subtitle),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFE5E7EB),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.20),
                  ),
                ),
                child: const Text(
                  'Featured',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: i == index ? 16 : 6,
          height: 6,
          decoration: BoxDecoration(
              color: i == index ? _wmPrimary : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(999)),
        ),
      ),
    );
  }
}

class _CategoryRowSkeleton extends StatelessWidget {
  const _CategoryRowSkeleton();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, __) => Column(
          children: [
            Container(
                height: 68,
                width: 68,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _wmBorder))),
            const SizedBox(height: 6),
            Container(
                width: 76,
                height: 10,
                decoration: BoxDecoration(
                    color: _wmBorderSoft,
                    borderRadius: BorderRadius.circular(999))),
          ],
        ),
      ),
    );
  }
}

class _PromoSkeleton extends StatelessWidget {
  const _PromoSkeleton();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 148,
      decoration: BoxDecoration(
          color: const Color(0xFFEDEFF3),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _wmBorder)),
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.slidePercent);
  final double slidePercent;
  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final dx = bounds.width * (slidePercent * 2 - 1);
    return Matrix4.translationValues(dx, 0.0, 0.0);
  }
}

class _Shimmer extends StatefulWidget {
  const _Shimmer(
      {super.key,
      required this.child,
      Color? baseColor,
      Color? highlightColor,
      Duration? speed})
      : baseColor = baseColor ?? const Color(0xFFD1D5DB),
        highlightColor = highlightColor ?? const Color(0xFFF3F4F6),
        speed = speed ?? const Duration(seconds: 3);

  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration speed;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.speed)..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        return ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.baseColor.withValues(alpha: 0.18),
                widget.highlightColor.withValues(alpha: 0.45),
                widget.baseColor.withValues(alpha: 0.18),
              ],
              stops: const [0.35, 0.5, 0.65],
              transform: _SlidingGradientTransform(t),
            ).createShader(rect);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}
