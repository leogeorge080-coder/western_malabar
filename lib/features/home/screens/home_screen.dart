import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:western_malabar/features/cart/providers/cart_provider.dart';
import 'package:western_malabar/features/cart/widgets/sticky_cart_bar.dart';
import 'package:western_malabar/features/catalog/models/category_model.dart';
import 'package:western_malabar/features/catalog/services/category_service.dart';
import 'package:western_malabar/features/catalog/services/product_service.dart';
import 'package:western_malabar/features/checkout/models/address_model.dart';
import 'package:western_malabar/features/checkout/providers/address_provider.dart';
import 'package:western_malabar/features/checkout/screens/saved_addresses_screen.dart';
import 'package:western_malabar/features/search/providers/search_controller.dart';
import 'package:western_malabar/features/search/screens/global_product_search_screen.dart';
import 'package:western_malabar/shared/utils/cart_fly_target.dart';
import 'package:western_malabar/shared/utils/fly_to_cart.dart';
import 'package:western_malabar/shared/utils/haptic.dart';

const _wmPrimary = Color(0xFF2A2F3A);
const _wmPrimaryDark = Color(0xFF171A20);

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

String _gbp(int cents) => '£${(cents / 100.0).toStringAsFixed(2)}';

double _lerp(double a, double b, double t) => a + (b - a) * t;
double _clamp01(num v) => v.clamp(0.0, 1.0).toDouble();

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

  final _buyItAgainKey = GlobalKey();
  final _weeklyEssentialsKey = GlobalKey();
  final _newInStoreKey = GlobalKey();
  final _popularThisWeekKey = GlobalKey();
  final _frozenFavouritesKey = GlobalKey();

  final GlobalKey<_SearchFieldState> _searchKey =
      GlobalKey<_SearchFieldState>();

  final List<String> _searchHints = const [
    'Search products',
    'Reorder your favourites',
    'Find rice, masala, snacks...',
  ];

  int _hintIndex = 0;
  Timer? _hintTimer;
  bool _freezeHint = true;

  @override
  void initState() {
    super.initState();
    _c = ScrollController();
    _startHintLoop();
    _homeFuture = _loadHomeBundle();

    _homeFuture.whenComplete(() {
      if (!mounted) return;
      setState(() => _freezeHint = false);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(searchProvider.notifier).hydrate();
    });
  }

  List<WmProduct> _uniqueRailProducts(
    List<WmProductDto> rows,
    Set<String> excluded, {
    int minItemsToShow = 1,
  }) {
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

  List<WmProduct> _softRail(
    List<WmProductDto> rows, {
    int minItemsToShow = 1,
  }) {
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

  void _reloadHome() {
    _homeFuture = _loadHomeBundle();
  }

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

    final buyItAgain = _uniqueRailProducts(
      buyAgainRows,
      priorityExcluded,
      minItemsToShow: 3,
    );

    final weeklyEssentials = _uniqueRailProducts(
      essentialsRows,
      priorityExcluded,
      minItemsToShow: 1,
    );

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

  void _startHintLoop() {
    _hintTimer?.cancel();
    if (_searchHints.length <= 1) return;

    _hintTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || _freezeHint) return;
      setState(() => _hintIndex = (_hintIndex + 1) % _searchHints.length);
    });
  }

  String _homeAddressLabel(AddressModel? address) {
    if (address == null) return 'Choose delivery address';

    final label = address.label.trim();
    final line1 = address.addressLine1.trim();
    final city = address.city.trim();
    final postcode = address.postcode.trim().toUpperCase();

    final primary = line1.isNotEmpty ? line1 : (city.isNotEmpty ? city : label);
    final secondary = postcode.isNotEmpty ? postcode : city;

    if (primary.isNotEmpty && secondary.isNotEmpty) {
      return 'Deliver to $primary, $secondary';
    }
    if (primary.isNotEmpty) {
      return 'Deliver to $primary';
    }
    return 'Choose delivery address';
  }

  Future<void> _openSavedAddresses() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SavedAddressesScreen(),
      ),
    );

    if (!mounted) return;
    ref.invalidate(addressesProvider);
    ref.invalidate(defaultAddressProvider);
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
    _hintTimer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    const double expandedHeight = 176;
    const double collapsedHeight = 64;

    final cartItems = ref.watch(cartProvider);
    final cartCount = cartItems.fold<int>(0, (sum, item) => sum + item.qty);
    final defaultAddressAsync = ref.watch(defaultAddressProvider);

    return Scaffold(
      backgroundColor: _wmCanvas,
      body: Stack(
        children: [
          const Positioned.fill(
            child: ColoredBox(color: _wmCanvas),
          ),
          RefreshIndicator(
            onRefresh: _refresh,
            color: _wmPrimary,
            child: CustomScrollView(
              controller: _c,
              cacheExtent: 1400,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
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
                      final t = _clamp01(
                        1 -
                            ((h - kToolbarHeight - topPad) /
                                (expandedHeight - kToolbarHeight - topPad)),
                      );

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
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              alignment: Alignment.centerLeft,
                              child: _SearchField(
                                key: _searchKey,
                                hint: _freezeHint
                                    ? _searchHints.first
                                    : _searchHints[_hintIndex],
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
                                subtitle: 'Tomorrow 6–8 PM',
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
                                child: _CategoryRowSkeleton(),
                              ),
                              Padding(
                                padding: EdgeInsets.fromLTRB(16, 6, 16, 10),
                                child: _PromoSkeleton(),
                              ),
                              _HomeSectionSkeleton(
                                title: 'Weekly essentials',
                                subtitleWidth: 220,
                              ),
                              _HomeSectionSkeleton(
                                title: 'New in store',
                                subtitleWidth: 170,
                              ),
                              _HomeSectionSkeleton(
                                title: 'Popular this week',
                                subtitleWidth: 180,
                              ),
                              SizedBox(height: 116),
                            ],
                          ),
                        );
                      }

                      if (snap.hasError || data == null) {
                        return const SizedBox.shrink();
                      }

                      final bundle = data;

                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeOut,
                        child: Column(
                          key: const ValueKey('home_loaded'),
                          children: [
                            if (bundle.categories.isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 10, 16, 12),
                                child: _RoundedCategoryRow(
                                  items: bundle.categories
                                      .map(
                                        (c) => RoundedCat(
                                          label: c.name,
                                          icon: _iconForSlug(c.slug),
                                          onTap: () {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Open category: ${c.slug}',
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            if (bundle.weeklyDeals.isNotEmpty)
                              const Padding(
                                padding: EdgeInsets.fromLTRB(16, 6, 16, 10),
                                child: WmPromoAutoCarousel(),
                              ),
                            if (bundle.buyItAgain.isNotEmpty)
                              _StaticProductRailSection(
                                key: _buyItAgainKey,
                                title: 'Buy it again',
                                subtitle:
                                    'Your usual favourites, ready faster.',
                                actionText: 'See all',
                                items: bundle.buyItAgain,
                                compact: true,
                                prominent: true,
                              ),
                            _StaticProductRailSection(
                              key: _weeklyEssentialsKey,
                              title: 'Weekly essentials',
                              subtitle: 'Your fastest path to a great basket.',
                              actionText: 'See all',
                              items: bundle.weeklyEssentials,
                              prominent: true,
                            ),
                            _StaticProductRailSection(
                              key: _newInStoreKey,
                              title: 'New in store',
                              subtitle:
                                  'Fresh arrivals worth trying this week.',
                              actionText: 'See all',
                              items: bundle.newInStore,
                              emptyTrustLabel: 'New in store',
                              surfaceTint: const Color(0xFFFFFBF4),
                              badgeTextOverride: 'New',
                            ),
                            _StaticProductRailSection(
                              key: _popularThisWeekKey,
                              title: 'Popular this week',
                              subtitle: 'Shoppers are adding these most.',
                              actionText: 'See all',
                              items: bundle.popularThisWeek,
                            ),
                            if (bundle.frozenFavourites.isNotEmpty)
                              _StaticProductRailSection(
                                key: _frozenFavouritesKey,
                                title: 'Frozen favourites',
                                subtitle: 'Easy stock-up picks for busy weeks.',
                                actionText: 'See all',
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
          if (cartCount > 0)
            const StickyCartBar(
              bottom: 64,
            ),
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

class _LocationPill extends StatelessWidget {
  const _LocationPill({
    required this.label,
    this.subtitle,
    this.onTap,
  });

  final String label;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _wmBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on, size: 18, color: _wmPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: _wmTextStrong,
                      ),
                    ),
                    if (subtitle != null && subtitle!.trim().isNotEmpty)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _wmTextSoft,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: _wmTextSoft,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.actionText,
    this.onAction,
    this.prominent = false,
  });

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
                  letterSpacing: -0.4,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _wmTextSoft,
                  fontSize: 13.25,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        if (actionText != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: _wmTextStrong,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            child: Text(
              actionText!,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
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
              onAction: () {},
              prominent: prominent,
            ),
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
                    onTap: (_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Open ${p.name}')),
                      );
                    },
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
  const _HomeSectionSkeleton({
    required this.title,
    this.subtitleWidth = 180,
  });

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
                Text(
                  title,
                  style: const TextStyle(
                    color: _wmSectionNeutral,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  width: subtitleWidth,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _wmBorderSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
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
              itemBuilder: (_, __) => const SizedBox(
                width: 176,
                child: _RailProductSkeleton(),
              ),
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
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
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
  const _ShimmerBar({
    required this.width,
    required this.height,
  });

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
          borderRadius: BorderRadius.circular(999),
        ),
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

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const GlobalProductSearchScreen(),
      ),
    );
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
              const Icon(
                Icons.search_rounded,
                color: Color(0xFF202124),
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeOutCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.08),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    widget.hint,
                    key: ValueKey(widget.hint),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _wmTextSoft,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductTile extends ConsumerStatefulWidget {
  const _ProductTile({
    required this.product,
    this.onTap,
    this.compact = false,
    this.emptyTrustLabel,
    this.surfaceTint,
    this.badgeTextOverride,
    this.emphasizeDeals = false,
  });

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to add item right now'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final addCount = quantity < 1 ? 1 : quantity;
      for (var i = 0; i < addCount; i++) {
        ref.read(cartProvider.notifier).add(full);
      }

      Haptic.medium(context);
      await Future<void>.delayed(const Duration(milliseconds: 30));

      await flyToCart(
        context: context,
        cartKey: wmBottomCartNavKey,
        imageKey: _imageKey,
      );
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

    if (qty == 0) {
      final suggestedQty = ((p.rememberedQty ?? 1).clamp(1, 6)) as int;

      return SizedBox(
        height: 34,
        child: ElevatedButton(
          onPressed:
              isAdding ? null : () => _handleAdd(p, quantity: suggestedQty),
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: _wmPrimary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFF4B5563),
            disabledForegroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: isAdding
              ? const SizedBox(
                  height: 14,
                  width: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  suggestedQty > 1 ? 'Add $suggestedQty' : 'Add',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      );
    }

    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: _wmPrimary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.remove, size: 16, color: Colors.white),
              onPressed: () {
                Haptic.light(context);
                ref.read(cartProvider.notifier).dec(item!.product);
              },
            ),
          ),
          Text(
            '$qty',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          SizedBox(
            width: 32,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.add, size: 16, color: Colors.white),
              onPressed: () {
                Haptic.light(context);
                ref.read(cartProvider.notifier).inc(item!.product);
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
          child: Text(
            'No ratings yet',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: _wmTextMuted,
              fontWeight: FontWeight.w500,
              height: 1.1,
            ),
          ),
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
              color: _wmGold,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '${avg.toStringAsFixed(1)} ($count)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: _wmTextSoft,
                fontWeight: FontWeight.w600,
                height: 1.1,
              ),
            ),
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
            colors: [
              Colors.white,
              Color(0xFFF8FAFC),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
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
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Positioned(
              left: -10,
              bottom: -10,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF1F5),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Center(
              child: Icon(
                Icons.shopping_basket_outlined,
                size: size,
                color: Colors.black26,
              ),
            ),
          ],
        ),
      );
    }

    final imageWidget = p.imageUrl == null || p.imageUrl!.isEmpty
        ? placeholderIcon(size: 38)
        : DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  Color(0xFFF8FAFC),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
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
        border: Border(
          bottom: BorderSide(
            color: Color(0x11000000),
            width: 1,
          ),
        ),
      ),
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
            color: Color(0x18000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final compact = widget.compact;
    final imageFlex = compact ? 7 : 8;
    final bodyFlex = compact ? 9 : 10;
    final titleSize = compact ? 15.0 : 16.0;
    final priceSize = compact ? 18.0 : 20.0;
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
                color: _pressed ? const Color(0xFFCBD5E1) : _wmBorder,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: imageFlex,
                  child: ClipRRect(
                    key: _imageKey,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: _buildImage(p),
                        ),
                        if (badge != null)
                          Positioned(
                            left: 10,
                            top: 10,
                            child: badge,
                          ),
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
                        Expanded(
                          child: Text(
                            p.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: titleSize,
                              height: 1.2,
                              color: _wmTextStrong,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (p.brandName != null &&
                            p.brandName!.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              p.brandName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: _wmTextMuted,
                                fontWeight: FontWeight.w600,
                                height: 1.1,
                              ),
                            ),
                          )
                        else
                          const SizedBox(height: 4),
                        if ((p.ratingCount ?? 0) > 0) ...[
                          _buildRatingRow(p),
                          const SizedBox(height: 4),
                        ] else
                          const SizedBox(height: 16),
                        if (trustLine != null)
                          Text(
                            trustLine,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: _wmTextMuted,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        else
                          const SizedBox(height: 16),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (widget.emphasizeDeals &&
                                      p.hasPriceDrop) ...[
                                    Text(
                                      _gbp(p.originalPriceCents!),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: _wmTextMuted,
                                        decoration: TextDecoration.lineThrough,
                                        decorationThickness: 2,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                  ],
                                  Text(
                                    _gbp(p.priceCents),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: priceSize,
                                      color: _wmSuccess,
                                      letterSpacing: -0.25,
                                    ),
                                  ),
                                  if (widget.emphasizeDeals &&
                                      p.hasPriceDrop &&
                                      p.savingCents != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Save ${_gbp(p.savingCents!)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: _wmSuccess,
                                      ),
                                    ),
                                  ] else if (_productPriceCue(p) != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      _productPriceCue(p)!,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: _wmSuccess,
                                      ),
                                    ),
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

  RoundedCat({
    required this.label,
    required this.icon,
    this.onTap,
  });
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

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
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
                Container(
                  height: 68,
                  width: 68,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _wmBorder),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Icon(it.icon, color: _wmPrimaryDark),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 96,
                  child: Text(
                    it.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 11.5,
                      height: 1.15,
                      color: _wmTextStrong,
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

class WmPromoAutoCarousel extends StatefulWidget {
  const WmPromoAutoCarousel({super.key});

  @override
  State<WmPromoAutoCarousel> createState() => _WmPromoAutoCarouselState();
}

class _WmPromoAutoCarouselState extends State<WmPromoAutoCarousel> {
  final _ctrl = PageController(viewportFraction: .92);
  int _page = 0;
  Timer? _timer;

  final _items = const <_PromoItem>[
    _PromoItem(
      title: 'Offers of the week',
      subtitle: 'Build your basket smarter and unlock free delivery over £30.',
      icon: Icons.local_shipping_outlined,
      colors: [Color(0xFF111827), Color(0xFF334155)],
    ),
    _PromoItem(
      title: 'Best value this week',
      subtitle: 'Sharp pricing on staples without the bargain-bin feel.',
      icon: Icons.local_offer_outlined,
      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    ),
    _PromoItem(
      title: 'Kitchen staples to start with',
      subtitle: 'A strong first basket starts with the right essentials.',
      icon: Icons.shopping_basket_outlined,
      colors: [Color(0xFF4B5563), Color(0xFF6B7280)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_ctrl.hasClients) return;
      _page = (_page + 1) % _items.length;
      _ctrl.animateToPage(
        _page,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
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

  const _PromoItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
  });
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.item});

  final _PromoItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
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
            blurRadius: 12,
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
              border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
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
                  item.title,
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
                  item.subtitle,
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
          const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
        ],
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
            borderRadius: BorderRadius.circular(999),
          ),
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
                border: Border.all(color: _wmBorder),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 76,
              height: 10,
              decoration: BoxDecoration(
                color: _wmBorderSoft,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
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
        border: Border.all(color: _wmBorder),
      ),
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
  const _Shimmer({
    super.key,
    required this.child,
    Color? baseColor,
    Color? highlightColor,
    Duration? speed,
  })  : baseColor = baseColor ?? const Color(0xFFD1D5DB),
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
