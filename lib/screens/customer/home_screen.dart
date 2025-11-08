// lib/screens/customer/home_screen.dart
import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';

import 'package:western_malabar/models/category_model.dart';
import 'package:western_malabar/services/category_service.dart';

/// Palette (model-style)
const _green900 = Color(0xFF063B36);
const _green700 = Color(0xFF0C5C52);
const _mint = Color(0xFFE9F7F2);
const _pill = Colors.white;
const _purple = Color(0xFF5A2D82);

/// Drop-in Home (round icon scroller + product rail)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ScrollController _c;
  double _t = 0;

  late Future<List<CategoryModel>> _catsFuture;

  // rotating search hint from categories
  List<String> _hints = const [
    'Search grocery…',
    'Search rice…',
    'Search spices…'
  ];
  int _hintIndex = 0;
  Timer? _hintTimer;

  @override
  void initState() {
    super.initState();
    _c = ScrollController();

    _catsFuture = CategoryService.fetchTop(limit: 18);

    CategoryService.fetchTop(limit: 50).then((rows) {
      final names =
          rows.map((e) => e.name.trim()).where((e) => e.isNotEmpty).toList();
      final seen = <String>{};
      final list = <String>[];
      for (final n in names) {
        final k = n.toLowerCase();
        if (seen.add(k)) list.add(n);
      }
      if (list.isNotEmpty) {
        setState(() => _hints = list.map((e) => 'Search $e…').toList());
      }
    }).whenComplete(() {
      if (_hints.length > 1) {
        _hintTimer?.cancel();
        _hintTimer = Timer.periodic(const Duration(seconds: 3), (_) {
          if (mounted)
            setState(() => _hintIndex = (_hintIndex + 1) % _hints.length);
        });
      }
    });
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padTop = MediaQuery.of(context).padding.top;
    final padBottom = MediaQuery.of(context).padding.bottom;
    const navH = kBottomNavigationBarHeight;
    final bottomSpace = padBottom + navH + 40; // keep free for your FAB/bubble

    const expandedH = 220.0;
    const collapsedH = 68.0;

    return Scaffold(
      backgroundColor: _mint,
      body: CustomScrollView(
        controller: _c,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: true,
            snap: true,
            expandedHeight: expandedH,
            collapsedHeight: collapsedH,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: LayoutBuilder(
              builder: (context, c) {
                final h = c.biggest.height;
                final t = _clamp01(
                  1 -
                      ((h - kToolbarHeight - padTop) /
                          (expandedH - kToolbarHeight - padTop)),
                );
                if (t != _t) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _t = t);
                  });
                }

                const searchHBig = 50.0;
                const searchHSmall = 42.0;
                final searchTopExpanded = padTop + 54;
                final searchTopCollapsed =
                    padTop + (kToolbarHeight - searchHSmall) / 2;
                final searchTop =
                    _lerp(searchTopExpanded, searchTopCollapsed, t);
                final searchH = _lerp(searchHBig, searchHSmall, t);

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Curved deep green header
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [_green900, _green700],
                        ),
                      ),
                    ),
                    // soft frosted
                    ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                        child: const SizedBox.expand(),
                      ),
                    ),
                    // Title + cart
                    Positioned(
                      left: 16,
                      right: 16,
                      top: padTop + 6,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            'WESTERN MALABAR',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                              letterSpacing: .2,
                            ),
                          ),
                          _CartIcon(),
                        ],
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
                      child: _SearchBar(
                        hint: _hints[_hintIndex % _hints.length],
                        onTapCamera: () => _toast(context, 'Camera search'),
                        onSubmitted: (q) {
                          if (q.trim().isEmpty) return;
                          _toast(context, 'Search: $q');
                        },
                      ),
                    ),

                    // Location pill
                    Positioned(
                      left: 16,
                      right: 16,
                      top: searchTop + searchH + _lerp(10, 0, t),
                      child: Opacity(
                        opacity: (1 - t).clamp(0, 1),
                        child: const _LocationPill(
                            label: 'Deliver to Leo — Scunthorpe DN15'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Round icon scroller (categories)
                  FutureBuilder<List<CategoryModel>>(
                    future: _catsFuture,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 90,
                          child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        );
                      }
                      if (snap.hasError) {
                        return _RetryCard(
                          message: 'Couldn’t load categories',
                          onRetry: () => setState(() => _catsFuture =
                              CategoryService.fetchTop(limit: 18)),
                        );
                      }
                      final rows = snap.data ?? const <CategoryModel>[];
                      if (rows.isEmpty) {
                        return _RetryCard(
                          message: 'No categories yet',
                          onRetry: () => setState(() => _catsFuture =
                              CategoryService.fetchTop(limit: 18)),
                        );
                      }
                      return _RoundIconStrip(
                        items: rows
                            .map((c) => _RoundIconItem(
                                  label: c.name,
                                  // fallback emoji for now
                                  icon: _emojiFor(c.slug),
                                  onTap: () =>
                                      _toast(context, 'Open ${c.slug}'),
                                ))
                            .toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // "You might need" rail
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('You might need',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: _green900)),
                      Text('See more',
                          style: TextStyle(
                              color: _green700, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const _ProductRail(),

                  const SizedBox(height: 14),

                  // Two small tiles like “Grocery / Wholesale”
                  Row(
                    children: const [
                      Expanded(
                          child: _SmallTile(
                              title: 'Grocery',
                              subtitle: 'Free delivery',
                              icon: Icons.delivery_dining)),
                      SizedBox(width: 12),
                      Expanded(
                          child: _SmallTile(
                              title: 'Wholesale',
                              subtitle: 'Best prices',
                              icon: Icons.local_mall_outlined)),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // bottom spacer to avoid overlap with nav + ask bubble
          SliverToBoxAdapter(child: SizedBox(height: bottomSpace)),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────
///  Header parts
/// ─────────────────────────────────────────────────────────────
class _CartIcon extends StatelessWidget {
  const _CartIcon();
  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: const [
        Icon(Icons.shopping_bag_outlined, color: Colors.white),
        Positioned(
          right: -6,
          top: -4,
          child: _Badge(count: 2),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.hint, this.onSubmitted, this.onTapCamera});
  final String hint;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTapCamera;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _pill,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 3))
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.search, color: Colors.black87),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                isDense: true,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: onSubmitted,
            ),
          ),
          IconButton(
            onPressed: onTapCamera,
            icon:
                const Icon(Icons.photo_camera_outlined, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

class _LocationPill extends StatelessWidget {
  const _LocationPill({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _pill,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0F000000), blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, size: 18, color: Colors.white),
          Container(
            width: 18,
            height: 18,
            margin: const EdgeInsets.only(right: 6),
            decoration:
                const BoxDecoration(color: _green700, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const Icon(Icons.location_on, size: 12, color: Colors.white),
          ),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: _green900),
            ),
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────
///  Round icon strip (categories)
/// ─────────────────────────────────────────────────────────────
class _RoundIconItem {
  final String label;
  final String icon; // using emoji for now
  final VoidCallback onTap;
  _RoundIconItem(
      {required this.label, required this.icon, required this.onTap});
}

class _RoundIconStrip extends StatelessWidget {
  const _RoundIconStrip({required this.items});
  final List<_RoundIconItem> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final it = items[i];
          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: it.onTap,
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _pill,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 8,
                          offset: Offset(0, 4))
                    ],
                    border: Border.all(color: _mint, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(it.icon, style: const TextStyle(fontSize: 28)),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 74,
                  child: Text(
                    it.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: _green900),
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

/// ─────────────────────────────────────────────────────────────
///  Product rail (demo content; swap to live later)
/// ─────────────────────────────────────────────────────────────
class _ProductRail extends StatelessWidget {
  const _ProductRail();

  @override
  Widget build(BuildContext context) {
    const items = <_DemoP>[
      _DemoP('Beetroot (Local shop)', 1795, '🫐'),
      _DemoP('Italian Avocado', 1495, '🥑'),
      _DemoP('Jeera Rice 5kg', 2399, '🍚'),
      _DemoP('Coconut Oil 1L', 599, '🫙'),
    ];
    return SizedBox(
      height: 176,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _ProductCard(p: items[i]),
      ),
    );
  }
}

class _DemoP {
  final String name;
  final int cents;
  final String emoji;
  const _DemoP(this.name, this.cents, this.emoji);
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.p});
  final _DemoP p;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      decoration: BoxDecoration(
          color: _pill,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
                color: Color(0x16000000), blurRadius: 12, offset: Offset(0, 6)),
          ]),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 120,
            height: 80,
            decoration: BoxDecoration(
              color: _mint,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(p.emoji, style: const TextStyle(fontSize: 34)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Text(
              p.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Row(
              children: [
                Text('£${(p.cents / 100).toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, color: _green900)),
                const Spacer(),
                _QtyButton(onTap: () => _toast(context, 'Add to cart')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({this.onTap});
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: _green700, borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.add, size: 16, color: Colors.white),
      ),
    );
  }
}

/// Small lower tiles
class _SmallTile extends StatelessWidget {
  const _SmallTile(
      {required this.title, required this.subtitle, required this.icon});
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      decoration: BoxDecoration(
          color: _pill,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
                color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 6)),
          ]),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _mint,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: _green700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, color: _green900)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: _green700)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: _green700),
        ],
      ),
    );
  }
}

/// Utility cards / bits
class _RetryCard extends StatelessWidget {
  const _RetryCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      alignment: Alignment.center,
      decoration:
          BoxDecoration(color: _pill, borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count});
  final int count;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
          color: _purple, borderRadius: BorderRadius.circular(10)),
      child: Text('$count',
          style: const TextStyle(
              color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}

/// helpers
void _toast(BuildContext context, String msg) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
double _lerp(double a, double b, double t) => a + (b - a) * t;
double _clamp01(num v) => v.clamp(0.0, 1.0).toDouble();

/// simple emoji pick for category slug
String _emojiFor(String slug) {
  switch (slug) {
    case 'meats':
      return '🥩';
    case 'veg' || 'vegetables' || 'vegetable':
      return '🥦';
    case 'fruits' || 'fruit':
      return '🍎';
    case 'breads' || 'bakery':
      return '🥖';
    case 'rice':
      return '🍚';
    case 'beverages':
      return '🥤';
    case 'snacks':
      return '🍿';
    case 'masalas-spices':
      return '🫚';
    default:
      return '🛒';
  }
}
