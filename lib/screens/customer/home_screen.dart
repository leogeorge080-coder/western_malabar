// lib/screens/customer/home_screen.dart
import 'dart:ui' show ImageFilter;
import 'dart:math' show max;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// Use a relative import so you don't have to change package names
import '../../widgets/wm_promo_carousel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ScrollController _c;
  double _t = 0.0; // 0 = expanded, 1 = collapsed

  @override
  void initState() {
    super.initState();
    _c = ScrollController()..addListener(() {});
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    // ---- Header dimensions ----
    const double expandedHeight = 150;
    const double collapsedHeight = 64;

    // ---- Title + spacing constants (fix the gap) ----
    const double titleVerticalPad = 4; // reduced
    const double titleRowHeight = 36; // fixed row height
    const double afterTitleGap = 4; // tiny breathing space under title

    // ---- Search bar sizes ----
    const double searchHCollapsed = 40;
    const double searchHExpanded = 46;

    // No blend at the bottom of header (gap source removed)
    const double blendHeight = 0.0;

    return Scaffold(
      body: CustomScrollView(
        controller: _c,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ───────────────── HEADER ─────────────────
          SliverAppBar(
            pinned: true,
            floating: true,
            snap: true,
            expandedHeight: expandedHeight,
            collapsedHeight: collapsedHeight,
            backgroundColor:
                const Color(0xFFFFF9EE).withOpacity(1.0 - (_t * 0.22)),
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 6 + (4 * _t),
                  sigmaY: 6 + (4 * _t),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final h = constraints.biggest.height;

                    // 0 (expanded) → 1 (collapsed)
                    final t = _clamp01(
                      1 -
                          ((h - kToolbarHeight - topPad) /
                              (expandedHeight - kToolbarHeight - topPad)),
                    );

                    if (t != _t) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() => _t = t);
                      });
                    }

                    // ── Search positioning ──
                    final double topWhenCollapsed =
                        topPad + (kToolbarHeight - searchHCollapsed) / 2;

                    // Pin search directly under title (no gap)
                    final double topWhenExpanded = topPad +
                        titleVerticalPad +
                        titleRowHeight +
                        afterTitleGap;

                    final double searchTop =
                        _lerp(topWhenExpanded, topWhenCollapsed, t);
                    final double searchHeight =
                        _lerp(searchHExpanded, searchHCollapsed, t);

                    // Subtle shadow only after small scroll
                    final double shadowRamp = _clamp01((t - 0.06) / 0.34);
                    final double shadowOpacity = 0.18 * shadowRamp;

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        // Title row (fixed height; reduced padding)
                        Positioned(
                          left: 0,
                          right: 0,
                          top: topPad,
                          child: IgnorePointer(
                            ignoring: t > 0.95,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 150),
                              opacity: _clamp01(1 - t),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: titleVerticalPad,
                                ),
                                child: SizedBox(
                                  height: titleRowHeight,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: const [
                                      Text(
                                        'WESTERN MALABAR',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 20,
                                          color: Color(0xFF5A2D82),
                                        ),
                                      ),
                                      Icon(Icons.shopping_bag_outlined,
                                          color: Color(0xFF5A2D82)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // SAME search bar sliding up
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 140),
                          curve: Curves.easeOut,
                          left: 16,
                          right: 16,
                          top: searchTop,
                          height: searchHeight,
                          child: _MovingSearchBar(
                            backgroundOpacity: _lerp(1.0, 0.75, t),
                          ),
                        ),

                        // (No blend container here — removed to kill the “gap”)

                        // Subtle shadow after tiny scroll
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
                                    Colors.black.withOpacity(shadowOpacity),
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
            ),
          ),

          // ───────────────── LOCATION ROW (snug) ─────────────────
          SliverPersistentHeader(
            pinned: false,
            delegate: _LocationHeader(
              maxH: 40,
              minH: 0,
              builder: (context, shrinkT) {
                final opacity = _clamp01(1 - max(_t, shrinkT));
                final y = 6 * shrinkT;
                return Transform.translate(
                  offset: Offset(0, -y),
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      color: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 0.0, // tightened
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.location_on,
                              color: Color(0xFF5A2D82), size: 18),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Deliver to Leo – Scunthorpe DN15',
                              style: TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ───────────────── BODY ─────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ======= NEW: Auto-scrolling single banner =======
                  WMPromoCarousel(
                    height: 120, // try 110–140 to taste
                    interval: const Duration(seconds: 4),
                    items: wmPromoItems(
                      i1: Icons.local_fire_department_outlined,
                      t1: 'Weekend Double Points',
                      s1: 'on Frozen Foods',
                      i2: Icons.favorite_border_outlined,
                      t2: 'Free Delivery over £30',
                      s2: 'Limited time',
                      i3: Icons.card_giftcard_outlined,
                      t3: '100 Welcome Points',
                      s3: 'for New Members',
                    ),
                    onTap: (idx) {
                      // TODO: navigate per banner index if needed
                      // if (idx == 0) { ... }
                    },
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    "Today's Picks",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF5A2D82),
                    ),
                  ),
                  const SizedBox(height: 10),

                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _ProductCard(
                          name: 'Kerala Matta Rice 5kg',
                          price: '£12.99',
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _ProductCard(
                          name: 'Sambar Powder 200g',
                          price: '£2.49',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Browse by Category',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF5A2D82),
                    ),
                  ),
                  const SizedBox(height: 10),

                  const Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _CategoryChip(label: 'Rice'),
                      _CategoryChip(label: 'Masalas'),
                      _CategoryChip(label: 'Frozen'),
                      _CategoryChip(label: 'Beverages'),
                      _CategoryChip(label: 'Dairy'),
                      _CategoryChip(label: 'Snacks'),
                      _CategoryChip(label: 'Vegetables'),
                      _CategoryChip(label: 'Household'),
                    ],
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────── Moving Search Bar ─────────
class _MovingSearchBar extends StatelessWidget {
  const _MovingSearchBar({required this.backgroundOpacity});
  final double backgroundOpacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(backgroundOpacity),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          // softer so it doesn't read as a “gap”
          BoxShadow(
              color: Color(0x1A000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search Masalas & Spices 🔍',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF5A2D82)),
          suffixIcon: IconButton(
            icon: const Icon(Icons.mic_none_outlined, color: Color(0xFF5A2D82)),
            onPressed: () {},
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        ),
      ),
    );
  }
}

// ───────── Location header delegate ─────────
class _LocationHeader extends SliverPersistentHeaderDelegate {
  _LocationHeader({
    required this.maxH,
    required this.minH,
    required this.builder,
  }) : assert(maxH >= minH);

  final double maxH;
  final double minH;
  final Widget Function(BuildContext context, double t) builder;

  @override
  double get minExtent => minH;
  @override
  double get maxExtent => max(maxH, minH);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    final total = (maxExtent - minExtent);
    final t = total <= 0 ? 1.0 : _clamp01(shrinkOffset / total);
    return builder(context, t);
  }

  @override
  bool shouldRebuild(covariant _LocationHeader old) =>
      old.maxH != maxH || old.minH != minH || old.builder != builder;
}

// ───────── Existing helpers ─────────
class _ProductCard extends StatelessWidget {
  final String name;
  final String price;
  const _ProductCard({required this.name, required this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.image, size: 50, color: Colors.black26),
            ),
          ),
          const SizedBox(height: 8),
          Text(name,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(price, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 6),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5A2D82),
              minimumSize: const Size.fromHeight(38),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {},
            icon: const Icon(Icons.add_shopping_cart, size: 18),
            label: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  const _CategoryChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

// math helpers
double _lerp(double a, double b, double t) => a + (b - a) * t;
double _clamp01(num v) => v.clamp(0.0, 1.0).toDouble();
