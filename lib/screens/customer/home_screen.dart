// lib/screens/customer/home_screen.dart
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'package:western_malabar/widgets/edge_sweep_glow.dart';
import 'package:western_malabar/widgets/weather_taste_banner.dart';
import 'package:western_malabar/widgets/weather_taste_banner_live.dart';
import 'package:western_malabar/widgets/weather_smart_picks.dart';

import 'package:western_malabar/models/category_model.dart';
import 'package:western_malabar/services/category_service.dart';
import 'package:western_malabar/services/product_service.dart';

/// ─────────────────────────────────────────────────────────────
/// Moving gold edge glow (local helper used on search/header)
/// ─────────────────────────────────────────────────────────────
class _MovingEdgeGlow extends StatefulWidget {
  const _MovingEdgeGlow({
    this.inset = EdgeInsets.zero,
    this.cornerRadius = 24,
    this.thickness = 3,
    this.opacity = 0.5,
    this.speed = const Duration(seconds: 12),
    super.key,
  });

  final EdgeInsets inset; // how far the “stroke” sits inside the rect
  final double cornerRadius; // roundness
  final double thickness; // stroke width
  final double opacity; // brightness of the highlight
  final Duration speed; // rotation time

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

    // rotating gold highlight
    final shader = SweepGradient(
      startAngle: 0,
      endAngle: 2 * math.pi,
      colors: [
        Colors.transparent,
        const Color(0xFFF4B400).withOpacity(opacity), // gold
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

    // subtle base stroke under the glow
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withOpacity(0.06);

    canvas.drawRRect(rrect, base);
    canvas.drawRRect(rrect, glow);
  }

  @override
  bool shouldRepaint(covariant _EdgeGlowPainter old) =>
      old.angle != angle ||
      old.cornerRadius != cornerRadius ||
      old.thickness != thickness ||
      old.opacity != opacity ||
      old.inset != inset;
}

/// ─────────────────────────────────────────────────────────────
///  Lightweight UI model used by the grid
/// ─────────────────────────────────────────────────────────────
class WmProduct {
  final String id;
  final String name;
  final int priceCents;
  final String? imageUrl;
  const WmProduct({
    required this.id,
    required this.name,
    required this.priceCents,
    this.imageUrl,
  });
}

String _gbp(int cents) => '£${(cents / 100.0).toStringAsFixed(2)}';

// math helpers
double _lerp(double a, double b, double t) => a + (b - a) * t;
double _clamp01(num v) => v.clamp(0.0, 1.0).toDouble();

/// Colors
const _wmPurple = Color(0xFF4B208C); // stronger purple
const _wmLavender = Color(0xFFE5DBFF); // lighter, cool lavender
const _wmLavenderCard = Color(0xFFF3ECFF);
const _wmGold = Color(0xFFF4B400); // for shimmer highlight

/// ─────────────────────────────────────────────────────────────
///  HOME SCREEN
/// ─────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Scroll + collapse anim
  late final ScrollController _c;
  double _t = 0.0; // 0 = expanded, 1 = collapsed

  // Categories (quick strip + search hints)
  late Future<List<CategoryModel>> _catsFuture;

  // 🔁 Rotating search hints
  List<String> _searchHints = const [
    'Search products…',
    'Search rice…',
    'Search spices…'
  ];
  int _hintIndex = 0;
  Timer? _hintTimer;

  // Products: infinite feed
  final _productSvc = ProductService();
  final List<WmProduct> _feed = [];
  bool _loadingMore = false;
  bool _hasMore = true;
  static const int _pageSize = 24;

  @override
  void initState() {
    super.initState();
    _c = ScrollController()..addListener(_onScroll);
    _catsFuture = CategoryService.fetchTop(limit: 14);

    // Build rotating hints from live categories (fallback when empty)
    CategoryService.fetchTop(limit: 50).then((rows) {
      if (!mounted) return;
      final names =
          rows.map((c) => c.name.trim()).where((s) => s.isNotEmpty).toList();
      final seen = <String>{};
      final unique = <String>[];
      for (final n in names) {
        final k = n.toLowerCase();
        if (seen.add(k)) unique.add(n);
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

    // initial products
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
    // collapse factor for header shadow
    const expandedHeight = 170.0;
    final topPad = MediaQuery.of(context).padding.top;
    final h = expandedHeight - _c.offset;
    final t = _clamp01(
      1 -
          ((h - kToolbarHeight - topPad) /
              (expandedHeight - kToolbarHeight - topPad)),
    );
    if (t != _t) setState(() => _t = t);

    // infinite load trigger
    final pos = _c.position;
    if (_hasMore && !_loadingMore && pos.pixels > pos.maxScrollExtent - 800) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final dto = await _productSvc.fetchTodaysPicks(
        limit: _pageSize,
        offset: _feed.length,
      );
      final mapped = dto.map((p) => WmProduct(
            id: p.id,
            name: p.name,
            priceCents: p.displayPriceCents,
            imageUrl: p.firstImageUrl,
          ));

      setState(() {
        _feed.addAll(mapped);
        _hasMore = dto.length == _pageSize;
      });
    } catch (_) {
      // could show a SnackBar if needed
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _refresh() async {
    _hasMore = true;
    _feed.clear();
    await _loadMore();
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
    const double expandedHeight = 170;
    const double collapsedHeight = 64;

    // height for header gradient + edge glow
    final double headerBgHeight = topPad + expandedHeight + 260;

    return Scaffold(
      body: Stack(
        children: [
          // page base
          const Positioned.fill(child: ColoredBox(color: Colors.white)),

          // Header gradient + sweeping gold edges
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
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF3E1D65),
                            Color(0xFF5F2F8E),
                            Color(0xFF7B51B3),
                            Color(0xFFE9E0F7),
                            Colors.white,
                          ],
                          stops: [0.0, 0.18, 0.38, 0.82, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                EdgeSweepGlow(
                  height: headerBgHeight,
                  borderRadius: 28,
                  thickness: 8.2,
                  blurSigma: 4,
                  opacity: 0.2,
                  cycle: const Duration(seconds: 16),
                ),
              ],
            ),
          ),

          // Thin moving gold ring around the header zone
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
                opacity: 0.55,
                speed: Duration(seconds: 14),
              ),
            ),
          ),

          // content
          RefreshIndicator(
            onRefresh: _refresh,
            color: _wmPurple,
            child: CustomScrollView(
              controller: _c,
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                // Header
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

                      const cartCount = 2;

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
                                color: Colors.white
                                    .withOpacity(_lerp(0.0, 0.88, t)),
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
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '',
                                        style: TextStyle(
                                          color: _wmPurple,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 20,
                                          letterSpacing: .2,
                                        ),
                                      ),
                                      Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Icon(Icons.shopping_bag_outlined,
                                              color: _wmPurple),
                                          Positioned(
                                            right: -6,
                                            top: -4,
                                            child: _Badge(count: cartCount),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Search
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 140),
                            curve: Curves.easeOut,
                            left: 16,
                            right: 16,
                            top: searchTop,
                            height: searchH,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white
                                    .withOpacity(_lerp(0.92, 1.0, t)),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Color(0x14000000),
                                      blurRadius: 8,
                                      offset: Offset(0, 3)),
                                ],
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              alignment: Alignment.centerLeft,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                transitionBuilder: (child, anim) =>
                                    FadeTransition(opacity: anim, child: child),
                                child: _SearchField(
                                  key: ValueKey(
                                      _searchHints.isEmpty ? 0 : _hintIndex),
                                  hint: _searchHints.isEmpty
                                      ? 'Search products…'
                                      : _searchHints[_hintIndex],
                                ),
                              ),
                            ),
                          ),

                          // ✨ Search-bar tracking glow overlay (same geometry)
                          Positioned(
                            left: 16,
                            right: 16,
                            top: searchTop,
                            height: searchH,
                            child: const IgnorePointer(
                              child: Opacity(
                                opacity: 0.85,
                                child: _MovingEdgeGlow(
                                  inset: EdgeInsets.fromLTRB(2, 2, 2, 2),
                                  cornerRadius: 24,
                                  thickness: 2.5,
                                  opacity: 0.55,
                                  speed: Duration(seconds: 10),
                                ),
                              ),
                            ),
                          ),

                          // Location pill
                          Positioned(
                            left: 16,
                            right: 16,
                            top: searchTop + searchH + _lerp(8, 0, t),
                            child: Opacity(
                              opacity: (1 - t).clamp(0.0, 1.0),
                              child: const _LocationPill(
                                  label: 'Deliver to Leo – Scunthorpe DN15'),
                            ),
                          ),
                          // bottom shadow
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
                                      Colors.transparent
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

                // ─────────── BODY ───────────
// Weather-based suggestions card (replaces hero banner)
                const SliverToBoxAdapter(
                  child: WeatherSmartPicks(city: 'Scunthorpe', country: 'GB'),
                ),

                // Loyalty shimmer card
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: _LoyaltyCard(
                      miles: 120,
                      headline: 'You have rewards waiting!',
                      ctaText: 'Redeem',
                    ),
                  ),
                ),

                // Trending icons
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: _TrendingIconsRow(
                      items: [
                        _TrendItem('Kerala Snacks', Icons.emoji_food_beverage),
                        _TrendItem('Rice', Icons.rice_bowl_outlined),
                        _TrendItem('Spices', Icons.auto_awesome_outlined),
                        _TrendItem('Frozen', Icons.ac_unit_outlined),
                        _TrendItem('Beverages', Icons.local_cafe_outlined),
                        _TrendItem('Oil & Ghee', Icons.oil_barrel_outlined),
                      ],
                    ),
                  ),
                ),

                // Hero image (panning)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: _HeroImagePanCarousel(
                      images: [
                        'assets/banners/wm_hero_1.jpg',
                        'assets/banners/wm_hero_2.jpg',
                        'assets/banners/wm_hero_3.jpg',
                      ],
                      assetImages: true,
                      height: 160,
                      swapInterval: Duration(seconds: 3),
                      panPeriod: Duration(seconds: 6),
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                    ),
                  ),
                ),

                // Slim offer strip
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: _SlimOfferStrip(
                      offers: [
                        '🔥 Weekend Double Points on Frozen Foods',
                        '💜 Free Delivery over £30',
                        '🎁 100 Welcome Points for New Members',
                      ],
                      intervalSeconds: 3,
                    ),
                  ),
                ),

                // Free delivery card
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _FreeDeliveryCard(
                      title: 'Free Delivery on your first order!',
                      subtitle: 'No minimum order',
                      code: 'FIRST15',
                      footnote: '*T&Cs apply',
                    ),
                  ),
                ),

                // Rounded categories (Supabase)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: FutureBuilder<List<CategoryModel>>(
                      future: _catsFuture,
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const SizedBox(
                            height: 82,
                            child: Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 2)),
                          );
                        }
                        if (!snap.hasData || snap.data!.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        final rows = snap.data!;
                        return _RoundedCategoryRow(
                          items: rows
                              .map((c) => RoundedCat(
                                    label: c.name,
                                    icon: _iconForSlug(c.slug),
                                    onTap: () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Open category: ${c.slug}')),
                                      );
                                    },
                                  ))
                              .toList(),
                        );
                      },
                    ),
                  ),
                ),

                // Promo carousel
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: WmPromoAutoCarousel(),
                  ),
                ),

                // Infinite product grid
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: .78,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _ProductTile(
                        product: _feed[i],
                        onAdd: (p) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Added "${p.name}"')),
                          );
                        },
                        onTap: (p) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Open ${p.name}')),
                          );
                        },
                      ),
                      childCount: _feed.length,
                    ),
                  ),
                ),

                // Spacer
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 80),
                    child: Center(child: SizedBox.shrink()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Icons for categories
  IconData _iconForSlug(String slug) {
    switch (slug) {
      case 'rice':
        return Icons.rice_bowl_outlined;
      case 'masalas-spices':
      case 'spices':
        return Icons.auto_awesome_outlined;
      case 'frozen-snacks':
      case 'frozen-vegetables':
      case 'frozen-breakfast':
        return Icons.ac_unit_outlined;
      case 'beverages':
        return Icons.local_cafe_outlined;
      case 'dairy':
        return Icons.icecream_outlined;
      case 'snacks':
        return Icons.local_pizza_outlined;
      case 'pulses-lentils':
        return Icons.grain_outlined;
      case 'pickles':
        return Icons.emoji_food_beverage_outlined;
      case 'ready-to-eat':
        return Icons.fastfood_outlined;
      case 'cooking-oil':
        return Icons.oil_barrel_outlined;
      default:
        return Icons.category_outlined;
    }
  }
}

/// ────────────────── Small UI pieces ──────────────────
class _Badge extends StatelessWidget {
  const _Badge({required this.count});
  final int count;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
          color: _wmPurple, borderRadius: BorderRadius.circular(10)),
      child: Text('$count',
          style: const TextStyle(
              color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
    );
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
              color: Color(0x0F000000), blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, size: 18, color: _wmPurple),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

/// Search field with dynamic hint + camera action
class _SearchField extends StatelessWidget {
  const _SearchField({super.key, required this.hint});
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: hint,
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
      onSubmitted: (q) {
        if (q.trim().isEmpty) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Search: $q')));
      },
    );
  }
}

/// Product tile (used by infinite feed)
class _ProductTile extends StatefulWidget {
  const _ProductTile({required this.product, this.onAdd, this.onTap});
  final WmProduct product;
  final void Function(WmProduct product)? onAdd;
  final void Function(WmProduct product)? onTap;

  @override
  State<_ProductTile> createState() => _ProductTileState();
}

class _ProductTileState extends State<_ProductTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: () => widget.onTap?.call(p),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        scale: _pressed ? 0.98 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x15000000),
                  blurRadius: 12,
                  offset: Offset(0, 6))
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(18)),
                        child: (p.imageUrl == null || p.imageUrl!.isEmpty)
                            ? Container(
                                color: const Color(0xFFF1F1F4),
                                alignment: Alignment.center,
                                child: const Icon(Icons.image,
                                    size: 48, color: Colors.black26),
                              )
                            : Image.network(
                                p.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xFFF1F1F4),
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.broken_image_outlined,
                                      size: 44, color: Colors.black26),
                                ),
                              ),
                      ),
                    ),
                    Positioned(
                        right: 10,
                        bottom: 10,
                        child: _PriceTag(text: _gbp(p.priceCents))),
                    Positioned(
                      left: 10,
                      bottom: 10,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 150),
                        opacity: _pressed ? 1 : 0,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _wmPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => widget.onAdd?.call(p),
                          icon: const Icon(Icons.add_shopping_cart, size: 18),
                          label: const Text('Add'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(_gbp(p.priceCents),
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Colors.black87)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriceTag extends StatelessWidget {
  const _PriceTag({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: Text(text,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
    );
  }
}

/// ───────────────── Quick categories (rounded) ────────────────
class RoundedCat {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  RoundedCat({required this.label, required this.icon, this.onTap});
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
                          offset: Offset(0, 4))
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
                        fontWeight: FontWeight.w700, fontSize: 12),
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

/// ───────────────── Slim auto-rotating offer strip ─────────────────
class _SlimOfferStrip extends StatefulWidget {
  const _SlimOfferStrip({
    required this.offers,
    this.intervalSeconds = 3,
  });

  final List<String> offers;
  final int intervalSeconds;

  @override
  State<_SlimOfferStrip> createState() => _SlimOfferStripState();
}

class _SlimOfferStripState extends State<_SlimOfferStrip> {
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.offers.length > 1) {
      _timer = Timer.periodic(
        Duration(seconds: widget.intervalSeconds),
        (_) {
          if (!mounted) return;
          setState(() => _index = (_index + 1) % widget.offers.length);
        },
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: _wmLavenderCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: Color(0x12000000), blurRadius: 8, offset: Offset(0, 4))
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.local_offer_outlined, color: _wmPurple),
          const SizedBox(width: 10),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: Text(
                widget.offers[_index],
                key: ValueKey(_index),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _wmPurple,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('View'),
          ),
        ],
      ),
    );
  }
}

/// ───────────────── Free delivery card ─────────────────
class _FreeDeliveryCard extends StatelessWidget {
  const _FreeDeliveryCard({
    required this.title,
    required this.subtitle,
    required this.code,
    required this.footnote,
  });
  final String title;
  final String subtitle;
  final String code;
  final String footnote;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
              color: Color(0x16000000), blurRadius: 12, offset: Offset(0, 6))
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(height: 6),
                Text(subtitle,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: _wmPurple, borderRadius: BorderRadius.circular(8)),
                  child: Text('Use code: $code',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 6),
                Text(footnote,
                    style:
                        const TextStyle(color: Colors.black45, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 60,
            decoration: BoxDecoration(
                color: _wmLavender, borderRadius: BorderRadius.circular(16)),
            alignment: Alignment.center,
            child: const Icon(Icons.local_shipping, size: 48, color: _wmPurple),
          ),
        ],
      ),
    );
  }
}

/// ───────────────── Promo Carousel ─────────────────
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
      colors: [_wmPurple, Color(0xFF9C6ADE)],
    ),
    _PromoItem(
      title: 'Weekend Double Points',
      subtitle: 'on Frozen Foods',
      icon: Icons.star_outline,
      colors: [Color(0xFF1E88E5), Color(0xFF26C6DA)],
    ),
    _PromoItem(
      title: '100 Welcome Points',
      subtitle: 'for New Members',
      icon: Icons.card_giftcard_outlined,
      colors: [Color(0xFF00897B), Color(0xFF80CBC4)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      _page = (_page + 1) % _items.length;
      _ctrl.animateToPage(_page,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic);
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
            physics: const BouncingScrollPhysics(),
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
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
              color: Color(0x16000000), blurRadius: 12, offset: Offset(0, 6))
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
                Text(item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18)),
                const SizedBox(height: 4),
                Text(item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
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

/// ───────────────── Big hero IMAGE with VERTICAL PANNING ─────────────────
class _HeroImagePanCarousel extends StatefulWidget {
  const _HeroImagePanCarousel({
    required this.images,
    this.assetImages = true,
    this.height = 160,
    this.swapInterval = const Duration(seconds: 3),
    this.panPeriod = const Duration(seconds: 6),
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
  });

  final List<String> images;
  final bool assetImages;
  final double height;
  final Duration swapInterval;
  final Duration panPeriod;
  final BorderRadius borderRadius;

  @override
  State<_HeroImagePanCarousel> createState() => _HeroImagePanCarouselState();
}

class _HeroImagePanCarouselState extends State<_HeroImagePanCarousel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _panCtrl;
  late final Animation<double> _yAlign;

  int _index = 0;
  Timer? _swapTimer;

  @override
  void initState() {
    super.initState();

    _panCtrl = AnimationController(
      vsync: this,
      duration: widget.panPeriod,
    )..repeat(reverse: true);

    _yAlign = Tween<double>(begin: -0.9, end: 0.9)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_panCtrl);

    if (widget.images.length > 1) {
      _swapTimer = Timer.periodic(widget.swapInterval, (_) {
        if (!mounted) return;
        setState(() => _index = (_index + 1) % widget.images.length);
      });
    }
  }

  @override
  void dispose() {
    _swapTimer?.cancel();
    _panCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imgs = widget.images;
    final current = imgs[_index];
    final next = imgs[(_index + 1) % imgs.length];

    ImageProvider provider(String src) => widget.assetImages
        ? AssetImage(src)
        : NetworkImage(src) as ImageProvider;

    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 450),
              child: AnimatedBuilder(
                key: ValueKey(current),
                animation: _yAlign,
                builder: (_, __) {
                  return Image(
                    image: provider(current),
                    fit: BoxFit.cover,
                    alignment: Alignment(0, _yAlign.value),
                  );
                },
              ),
            ),
            // Preload next to avoid flicker
            Positioned.fill(
              child: Opacity(
                opacity: 0.001,
                child: Image(
                  image: provider(next),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ───────────────────── Shimmer + Loyalty + Trending ─────────────────────
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
    Key? key,
    required this.child,
    Color? baseColor,
    Color? highlightColor,
    Duration? speed,
  })  : baseColor = baseColor ?? const Color(0xFF6B3FA6),
        highlightColor = highlightColor ?? _wmGold,
        speed = speed ?? const Duration(seconds: 2),
        super(key: key);

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
        final t = _ctrl.value; // 0..1
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
                color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 6)),
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
                    Text(headline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('You have $miles Malabar Miles',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
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
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Open Rewards')),
                );
              },
              child: Text(ctaText,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendItem {
  final String label;
  final IconData icon;
  const _TrendItem(this.label, this.icon);
}

class _TrendingIconsRow extends StatelessWidget {
  const _TrendingIconsRow({required this.items});

  final List<_TrendItem> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final it = items[i];
          return _TrendPill(label: it.label, icon: it.icon);
        },
      ),
    );
  }
}

class _TrendPill extends StatefulWidget {
  const _TrendPill({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  State<_TrendPill> createState() => _TrendPillState();
}

class _TrendPillState extends State<_TrendPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 220));
  late final Animation<double> _scale =
      Tween<double>(begin: 1, end: 0.96).animate(
    CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapCancel: () => _ctrl.reverse(),
      onTapUp: (_) => _ctrl.reverse(),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Open ${widget.label}')),
        );
      },
      child: ScaleTransition(
        scale: _scale,
        child: Column(
          children: [
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_wmLavender, _wmLavenderCard],
                ),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 8,
                      offset: Offset(0, 4)),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(widget.icon, color: _wmPurple),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 84,
              child: Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────
/// Pair Splash Strip: shows 2 items per cycle, flying from back,
/// pulsing in center with a ripple "splash", then exiting.
/// Uses the same lavender gradient as the page.
/// ─────────────────────────────────────────────────────────────
class _PairSplashStrip extends StatefulWidget {
  const _PairSplashStrip({
    required this.images,
    this.height = 160,
    this.cycle = const Duration(seconds: 3),
    Key? key,
  }) : super(key: key);

  final List<String> images;
  final double height;
  final Duration cycle;

  @override
  State<_PairSplashStrip> createState() => _PairSplashStripState();
}

class _PairSplashStripState extends State<_PairSplashStrip>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  int _start = 0; // index of first in the current pair

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.cycle)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          _start = (_start + 2) % widget.images.length;
          _ctrl.forward(from: 0);
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // smoothstep
  double _smooth(double t) => (t * t * (3 - 2 * t)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    assert(widget.images.length >= 2,
        'Provide at least 2 images for _PairSplashStrip');

    // pair indices
    final i0 = _start % widget.images.length;
    final i1 = (_start + 1) % widget.images.length;
    final a = widget.images[i0];
    final b = widget.images[i1];

    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final h = widget.height;

            return Stack(
              fit: StackFit.expand,
              children: [
                // Lavender gradient background (same family as header)
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF6B3FA6),
                        Color(0xFF7B51B3),
                        _wmLavender,
                      ],
                      stops: [0.0, 0.55, 1.0],
                    ),
                  ),
                ),

                // Animated pair
                AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, __) {
                    final t = _ctrl.value; // 0..1

                    // Horizontal travel across the strip
                    double x(double k) => _lerp(-w * 0.35, w * 1.35, t);

                    // Depth/scale so it looks like "from the back"
                    double depthScale(double phase) {
                      // bell shape around center
                      final u = (t - phase);
                      final falloff = (1 - (u * 2).abs()).clamp(0.0, 1.0);
                      return 0.78 + 0.38 * falloff; // 0.78..1.16
                    }

                    // Light rotation + bob
                    double rot(double s) =>
                        0.06 * math.sin(2 * math.pi * (t + s));
                    double bob(double s) => 8 * math.sin(2 * math.pi * (t + s));

                    // Opacity fades in/out
                    double op(double phase) {
                      final u = (t - phase);
                      final on = _smooth((u + 0.35).clamp(0.0, 1.0));
                      final off = 1 - _smooth((u - 0.35).clamp(0.0, 1.0));
                      return (on * off).clamp(0.0, 1.0);
                    }

                    // Splash ripple near center (trigger around t≈0.5)
                    final splashPower =
                        (1 - ((t - 0.5).abs() / 0.18)).clamp(0.0, 1.0);
                    final splashOpacity = 0.35 * splashPower;
                    final splashRadius = _lerp(h * 0.35, h * 1.1, splashPower);

                    // Choose z-order: draw smaller first
                    final s0 = depthScale(0.0);
                    final s1 = depthScale(0.15);
                    final pair = [
                      _CardShot(
                        image: a,
                        x: x(0),
                        y: h * 0.5 + bob(0.0),
                        scale: s0,
                        rotation: rot(0.0),
                        opacity: op(0.0),
                      ),
                      _CardShot(
                        image: b,
                        x: x(0),
                        y: h * 0.5 + bob(0.15),
                        scale: s1,
                        rotation: rot(0.15),
                        opacity: op(0.15),
                      ),
                    ]..sort((l, r) => l.scale.compareTo(r.scale));

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Ripple splash
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _RipplePainter(
                                center: Offset(w * 0.5, h * 0.5),
                                radius: splashRadius,
                                color: Colors.white.withOpacity(splashOpacity),
                              ),
                            ),
                          ),
                        ),

                        // Draw pair (smaller first so bigger overlaps)
                        for (final shot in pair)
                          Positioned(
                            left: shot.x - 62, // half of card width
                            top: shot.y - 44,
                            child: Opacity(
                              opacity: shot.opacity,
                              child: Transform.rotate(
                                angle: shot.rotation,
                                child: Transform.scale(
                                  scale: shot.scale,
                                  child: _CardImage(image: shot.image),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CardShot {
  _CardShot({
    required this.image,
    required this.x,
    required this.y,
    required this.scale,
    required this.rotation,
    required this.opacity,
  });

  final String image;
  final double x;
  final double y;
  final double scale;
  final double rotation;
  final double opacity;
}

class _CardImage extends StatelessWidget {
  const _CardImage({required this.image});
  final String image;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      width: 124,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: Color(0x30000000), blurRadius: 14, offset: Offset(0, 6)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(image, fit: BoxFit.cover),
    );
  }
}

class _RipplePainter extends CustomPainter {
  _RipplePainter(
      {required this.center, required this.radius, required this.color});
  final Offset center;
  final double radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (radius <= 0) return;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withOpacity(0.0)],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _RipplePainter old) =>
      old.radius != radius || old.color != color || old.center != center;
}
