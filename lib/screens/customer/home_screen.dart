import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:western_malabar/theme/wm_gradients.dart';
import 'package:western_malabar/widgets/edge_sweep_glow.dart';
import 'package:western_malabar/widgets/search_suggestions.dart';

import 'package:western_malabar/models/category_model.dart';
import 'package:western_malabar/services/category_service.dart';
import 'package:western_malabar/services/product_service.dart';
import 'package:western_malabar/state/search_controller.dart';
import 'package:western_malabar/state/cart_provider.dart';
import 'package:western_malabar/utils/cart_fly_target.dart';
import 'package:western_malabar/utils/fly_to_cart.dart';
import 'package:western_malabar/utils/haptic.dart';
import 'package:western_malabar/widgets/cart/sticky_cart_bar.dart';
import 'cart_screen.dart';
import 'global_product_search_screen.dart';
import 'search_screen.dart';

class _MovingEdgeGlow extends StatefulWidget {
  const _MovingEdgeGlow({
    this.inset = EdgeInsets.zero,
    this.cornerRadius = 24,
    this.thickness = 3,
    this.opacity = 0.5,
    this.speed = const Duration(seconds: 12),
    super.key,
  });

  final EdgeInsets inset;
  final double cornerRadius;
  final double thickness;
  final double opacity;
  final Duration speed;

  @override
  State<_MovingEdgeGlow> createState() => _MovingEdgeGlowState();
}

class _MovingEdgeGlowState extends State<_MovingEdgeGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: widget.speed)..repeat();

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
        return CustomPaint(
          painter: _EdgeGlowPainter(
            angle: _ctrl.value * 2 * math.pi,
            inset: widget.inset,
            cornerRadius: widget.cornerRadius,
            thickness: widget.thickness,
            opacity: widget.opacity,
          ),
        );
      },
    );
  }
}

class _EdgeGlowPainter extends CustomPainter {
  _EdgeGlowPainter({
    required this.angle,
    required this.inset,
    required this.cornerRadius,
    required this.thickness,
    required this.opacity,
  });

  final double angle;
  final EdgeInsets inset;
  final double cornerRadius;
  final double thickness;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final inner = Rect.fromLTWH(
      rect.left + inset.left,
      rect.top + inset.top,
      rect.width - inset.horizontal,
      rect.height - inset.vertical,
    );
    final rrect = RRect.fromRectAndRadius(inner, Radius.circular(cornerRadius));

    final shader = SweepGradient(
      startAngle: 0,
      endAngle: 2 * math.pi,
      colors: [
        Colors.transparent,
        const Color(0xFFF4B400).withOpacity(opacity),
        Colors.transparent,
      ],
      stops: const [0.45, 0.50, 0.55],
      transform: GradientRotation(angle),
    ).createShader(inner);

    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..shader = shader
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..blendMode = BlendMode.plus;

    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withOpacity(0.06);

    canvas.drawRRect(rrect, base);
    canvas.drawRRect(rrect, glow);
  }

  @override
  bool shouldRepaint(covariant _EdgeGlowPainter old) {
    return old.angle != angle ||
        old.cornerRadius != cornerRadius ||
        old.thickness != thickness ||
        old.opacity != opacity ||
        old.inset != inset;
  }
}

class WmProduct {
  final String id;
  final String name;
  final String? brandName;
  final int priceCents;
  final String? imageUrl;
  final double? avgRating;
  final int? ratingCount;
  final ProductCursor? cursor;

  const WmProduct({
    required this.id,
    required this.name,
    required this.priceCents,
    this.brandName,
    this.imageUrl,
    this.avgRating,
    this.ratingCount,
    this.cursor,
  });
}

String _gbp(int cents) => '£${(cents / 100.0).toStringAsFixed(2)}';

double _lerp(double a, double b, double t) => a + (b - a) * t;
double _clamp01(num v) => v.clamp(0.0, 1.0).toDouble();

const _wmPurple = Color(0xFF5A2D82);
const _wmLavender = Color(0xFFF3ECFB);
const _wmGold = Color(0xFFF0C53E);
const _wmCream = Color(0xFFFFFBF4);
const _wmDeepPlum = Color(0xFF442062);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends ConsumerState<HomeScreen> {
  late final ScrollController _c;
  late Future<List<CategoryModel>> _catsFuture;

  List<String> _searchHints = const [
    'Search products…',
    'Search rice…',
    'Search spices…',
  ];
  int _hintIndex = 0;
  Timer? _hintTimer;

  final _productSvc = ProductService();
  final List<WmProduct> _feed = [];
  bool _loadingMore = false;
  bool _hasMore = true;
  int _backendOffset = 0;
  static const int _pageSize = 24;

  @override
  void initState() {
    super.initState();
    _c = ScrollController()..addListener(_onScroll);
    _catsFuture = CategoryService.fetchHomeCategories(limit: 14);

    CategoryService.fetchHomeCategories(limit: 50).then((rows) {
      if (!mounted) return;

      final names =
          rows.map((c) => c.name.trim()).where((s) => s.isNotEmpty).toList();

      final seen = <String>{};
      final unique = <String>[];

      for (final n in names) {
        final key = n.toLowerCase();
        if (seen.add(key)) unique.add(n);
      }

      setState(() {
        _searchHints = unique.isEmpty
            ? const ['Search products…', 'Search rice…', 'Search spices…']
            : unique.map((n) => 'Search $n…').toList();
        _hintIndex = 0;
      });

      _startHintLoop();
    }).catchError((_) {
      _startHintLoop();
    });

    _loadMore();
  }

  void _startHintLoop() {
    _hintTimer?.cancel();
    if (_searchHints.length <= 1) return;

    _hintTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() => _hintIndex = (_hintIndex + 1) % _searchHints.length);
    });
  }

  void _onScroll() {
    final pos = _c.position;
    if (_hasMore && !_loadingMore && pos.pixels > pos.maxScrollExtent - 400) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;

    setState(() => _loadingMore = true);

    try {
      final dto = await _productSvc.fetchTodaysPicks(
        limit: _pageSize,
        offset: _backendOffset,
      );

      if (!mounted) return;

      final existingIds = _feed.map((e) => e.id).toSet();

      final uniqueNewItems = dto
          .where((p) => !existingIds.contains(p.id))
          .map(
            (p) => WmProduct(
              id: p.id,
              name: p.name,
              brandName: p.brandName,
              priceCents: p.displayPriceCents,
              imageUrl: p.firstImageUrl,
              avgRating: p.avgRating,
              ratingCount: p.ratingCount,
              cursor: p.cursor,
            ),
          )
          .toList();

      setState(() {
        _feed.addAll(uniqueNewItems);

        // Advance by raw page size consumed from backend,
        // not by visible feed count.
        _backendOffset += _pageSize;

        // If this page returned nothing after service call,
        // we've likely reached the end.
        _hasMore = dto.isNotEmpty;
      });
    } catch (_) {
      //
    } finally {
      if (mounted) {
        setState(() => _loadingMore = false);
      }
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _hasMore = true;
      _backendOffset = 0;
      _feed.clear();
    });
    await _loadMore();
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _c.dispose();
    super.dispose();
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
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    const double expandedHeight = 170;
    const double collapsedHeight = 64;
    final cartItems = ref.watch(cartProvider);
    final cartCount = cartItems.fold<int>(0, (sum, item) => sum + item.qty);

    final double headerBgHeight = topPad + expandedHeight + 260;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(
            child: ColoredBox(color: _wmCream),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: headerBgHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: WMGradients.homeBackground,
                      ),
                    ),
                  ),
                ),
                EdgeSweepGlow(
                  height: headerBgHeight,
                  borderRadius: 28,
                  thickness: 8.2,
                  blurSigma: 4,
                  opacity: 0.12,
                  cycle: const Duration(seconds: 16),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: topPad + expandedHeight + 220,
            child: const IgnorePointer(
              child: _MovingEdgeGlow(
                inset: EdgeInsets.fromLTRB(12, 10, 12, 14),
                cornerRadius: 32,
                thickness: 3,
                opacity: 0.28,
                speed: Duration(seconds: 14),
              ),
            ),
          ),
          RefreshIndicator(
            onRefresh: _refresh,
            color: _wmPurple,
            child: CustomScrollView(
              controller: _c,
              cacheExtent: 1200,
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

                      const searchHExpanded = 46.0;
                      const searchHCollapsed = 40.0;
                      final searchTopExpanded = topPad + 46;
                      final searchTopCollapsed =
                          topPad + (kToolbarHeight - searchHCollapsed) / 2;

                      final searchTop =
                          _lerp(searchTopExpanded, searchTopCollapsed, t);
                      final searchH =
                          _lerp(searchHExpanded, searchHCollapsed, t);

                      final shadow = (t > 0.02)
                          ? 0.20 * ((t - 0.02) / .30).clamp(0.0, 1.0)
                          : 0.0;

                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRect(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                              child: const SizedBox.expand(),
                            ),
                          ),
                          Positioned.fill(
                            child: IgnorePointer(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOut,
                                color: const Color(0xFFFFFCF7)
                                    .withOpacity(_lerp(0.0, 0.82, t)),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 16,
                            right: 16,
                            top: topPad + 4,
                            child: IgnorePointer(
                              ignoring: t > 0.95,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 150),
                                opacity: (1 - t).clamp(0.0, 1.0),
                                child: const SizedBox(
                                  height: 36,
                                ),
                              ),
                            ),
                          ),
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 140),
                            curve: Curves.easeOut,
                            left: 16,
                            right: 16,
                            top: searchTop,
                            height: searchH,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFCF7)
                                    .withOpacity(_lerp(0.94, 1.0, t)),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x14000000),
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              alignment: Alignment.centerLeft,
                              child: _SearchField(
                                hint: _searchHints.isEmpty
                                    ? 'Search products…'
                                    : _searchHints[_hintIndex],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 16,
                            right: 16,
                            top: searchTop,
                            height: searchH,
                            child: const IgnorePointer(
                              child: Opacity(
                                opacity: 0.55,
                                child: _MovingEdgeGlow(
                                  inset: EdgeInsets.fromLTRB(2, 2, 2, 2),
                                  cornerRadius: 24,
                                  thickness: 2.5,
                                  opacity: 0.22,
                                  speed: Duration(seconds: 10),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 16,
                            right: 16,
                            top: searchTop + searchH + _lerp(8, 0, t),
                            child: Opacity(
                              opacity: (1 - t).clamp(0.0, 1.0),
                              child: const _LocationPill(
                                label: 'Deliver to Leo – Scunthorpe DN15',
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: IgnorePointer(
                              child: Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withOpacity(shadow),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                    child: FutureBuilder<List<CategoryModel>>(
                      future: _catsFuture,
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const SizedBox(
                            height: 82,
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }
                        if (snap.hasError) {
                          return SizedBox(
                            height: 82,
                            child: Center(
                              child: Text(
                                'Failed to load categories',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          );
                        }
                        if (!snap.hasData || snap.data!.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        final rows = snap.data!;
                        return _RoundedCategoryRow(
                          items: rows
                              .map(
                                (c) => RoundedCat(
                                  label: c.name,
                                  icon: _iconForSlug(c.slug),
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('Open category: ${c.slug}'),
                                      ),
                                    );
                                  },
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: WmPromoAutoCarousel(),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: _LoyaltyCard(
                      miles: 120,
                      headline: 'You have rewards waiting!',
                      ctaText: 'Redeem',
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Text(
                      'Today’s Picks',
                      style: TextStyle(
                        color: _wmPurple,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: .69,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _ProductTile(
                        product: _feed[i],
                        onTap: (p) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Open ${p.name}')),
                          );
                        },
                      ),
                      childCount: _feed.length,
                      addAutomaticKeepAlives: false,
                      addRepaintBoundaries: true,
                      addSemanticIndexes: false,
                    ),
                  ),
                ),
                if (_loadingMore)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 8, bottom: 18),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 72),
                    child: SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
          if (cartCount > 0)
            const StickyCartBar(
              bottom: 64,
            ),
          const SearchSuggestions(
            top: 110,
            left: 16,
            right: 16,
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
  const _LocationPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, size: 18, color: _wmPurple),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: const Icon(Icons.search, color: _wmPurple),
        suffixIcon: IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Camera search coming soon')),
            );
          },
          icon: const Icon(Icons.camera_alt_outlined, color: _wmPurple),
        ),
        border: InputBorder.none,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      ),
      onChanged: (q) {
        ref.read(searchProvider.notifier).search(q);
      },
      onSubmitted: (q) {
        final trimmed = q.trim();
        ref.read(searchProvider.notifier).clear();

        if (trimmed.isEmpty) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GlobalProductSearchScreen(initialQuery: trimmed),
          ),
        );
      },
    );
  }
}

class _ProductTile extends ConsumerStatefulWidget {
  const _ProductTile({required this.product, this.onTap});

  final WmProduct product;
  final void Function(WmProduct product)? onTap;

  @override
  ConsumerState<_ProductTile> createState() => _ProductTileState();
}

class _ProductTileState extends ConsumerState<_ProductTile> {
  bool _pressed = false;
  final GlobalKey _imageKey = GlobalKey();

  Future<void> _handleAdd(WmProduct p) async {
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

      ref.read(cartProvider.notifier).add(full);

      Haptic.medium(context);

      await Future<void>.delayed(const Duration(milliseconds: 30));

      await flyToCart(
        context: context,
        cartKey: wmBottomCartNavKey,
        imageKey: _imageKey,
      );
    } finally {
      if (mounted) {
        final addingIds = ref.read(addingProductIdsProvider);
        final updated = {...addingIds}..remove(p.id);
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
      return SizedBox(
        height: 34,
        child: ElevatedButton(
          onPressed: isAdding ? null : () => _handleAdd(p),
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: _wmPurple,
            foregroundColor: Colors.white,
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
              : const Text(
                  '+ Add',
                  style: TextStyle(
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
        color: _wmPurple,
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
              color: Colors.black45,
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
              color: const Color(0xFFF0C53E),
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
                color: Colors.black54,
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
    final imageWidget = p.imageUrl == null || p.imageUrl!.isEmpty
        ? Container(
            color: const Color(0xFFF6F4F8),
            alignment: Alignment.center,
            child: const Icon(
              Icons.shopping_basket_outlined,
              size: 40,
              color: Colors.black26,
            ),
          )
        : CachedNetworkImage(
            imageUrl: p.imageUrl!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            fadeInDuration: const Duration(milliseconds: 120),
            placeholder: (_, __) => Container(
              color: const Color(0xFFF6F4F8),
              alignment: Alignment.center,
              child: const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black26),
                ),
              ),
            ),
            errorWidget: (_, __, ___) => Container(
              color: const Color(0xFFF6F4F8),
              alignment: Alignment.center,
              child: const Icon(
                Icons.shopping_basket_outlined,
                size: 40,
                color: Colors.black26,
              ),
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

  @override
  Widget build(BuildContext context) {
    final p = widget.product;

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
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _pressed
                    ? _wmPurple.withOpacity(0.18)
                    : Colors.black.withOpacity(0.05),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 8,
                  child: ClipRRect(
                    key: _imageKey,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: _buildImage(p),
                    ),
                  ),
                ),
                Expanded(
                  flex: 10,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (p.brandName != null &&
                            p.brandName!.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              p.brandName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                              ),
                            ),
                          )
                        else
                          const SizedBox(height: 15),
                        Expanded(
                          child: Text(
                            p.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              height: 1.2,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildRatingRow(p),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  _gbp(p.priceCents),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                    color: _wmPurple,
                                    letterSpacing: -0.2,
                                  ),
                                ),
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
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        physics: const BouncingScrollPhysics(),
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) {
          final it = items[i];
          return InkWell(
            onTap: it.onTap,
            child: Column(
              children: [
                Container(
                  height: 64,
                  width: 64,
                  decoration: BoxDecoration(
                    color: _wmLavender,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      )
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Icon(it.icon, color: _wmPurple),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 80,
                  child: Text(
                    it.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
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
      title: 'Free Delivery over £30',
      subtitle: 'Limited time',
      icon: Icons.local_shipping_outlined,
      colors: [_wmDeepPlum, Color(0xFF8E67BA)],
    ),
    _PromoItem(
      title: 'Weekend Double Points',
      subtitle: 'on Frozen Foods',
      icon: Icons.star_outline,
      colors: [Color(0xFF2E7D5A), Color(0xFF8BC9A7)],
    ),
    _PromoItem(
      title: '100 Welcome Points',
      subtitle: 'for New Members',
      icon: Icons.card_giftcard_outlined,
      colors: [Color(0xFFC9821E), Color(0xFFF2C46D)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
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
          height: 140,
          child: PageView.builder(
            controller: _ctrl,
            itemCount: _items.length,
            onPageChanged: (i) => setState(() => _page = i),
            physics: const PageScrollPhysics(),
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: item.colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.20),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(.35)),
            ),
            child: Icon(item.icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
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
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
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
            color: i == index ? _wmPurple : _wmLavender,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
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
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration speed;

  const _Shimmer({
    super.key,
    required this.child,
    Color? baseColor,
    Color? highlightColor,
    Duration? speed,
  })  : baseColor = baseColor ?? const Color(0xFF6B3FA6),
        highlightColor = highlightColor ?? _wmGold,
        speed = speed ?? const Duration(seconds: 3);

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
                widget.baseColor.withOpacity(.18),
                widget.highlightColor.withOpacity(.55),
                widget.baseColor.withOpacity(.18),
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

class _LoyaltyCard extends StatelessWidget {
  const _LoyaltyCard({
    required this.miles,
    this.headline = 'Malabar Miles',
    this.ctaText = 'View',
  });

  final int miles;
  final String headline;
  final String ctaText;

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF7B51B3), _wmPurple],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 10,
              offset: Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(.35)),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.loyalty, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DefaultTextStyle(
                style: const TextStyle(color: Colors.white),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      headline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'You have $miles Malabar Miles',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withOpacity(.12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Open Rewards')),
                );
              },
              child: Text(
                ctaText,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
