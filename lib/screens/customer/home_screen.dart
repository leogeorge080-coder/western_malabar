// lib/screens/customer/home_screen.dart
import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'package:western_malabar/models/category_model.dart';
import 'package:western_malabar/services/category_service.dart';
import 'package:western_malabar/services/product_service.dart';

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

/// ─────────────────────────────────────────────────────────────
///  HOME SCREEN (Noon-style sections + infinite products)
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
    }).catchError((_) => _startHintLoop());

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
      // keep previous state; could show a SnackBar if needed
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

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: const Color(0xFF5A2D82),
        child: CustomScrollView(
          controller: _c,
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // ───────── Header (warm gradient + rotating search + location) ─────────
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
                  final searchH = _lerp(searchHExpanded, searchHCollapsed, t);

                  final shadow = (t > 0.06)
                      ? 0.16 * ((t - 0.06) / .34).clamp(0.0, 1.0)
                      : 0.0;

                  const cartCount = 2;

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      // Warm gradient + subtle blur
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFFFF4DE), Color(0xFFFFF9EE)],
                          ),
                        ),
                      ),
                      ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: const SizedBox.expand(),
                        ),
                      ),

                      // Title row
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
                                    'WESTERN MALABAR',
                                    style: TextStyle(
                                      color: Color(0xFF5A2D82),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 20,
                                      letterSpacing: .2,
                                    ),
                                  ),
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Icon(Icons.shopping_bag_outlined,
                                          color: Color(0xFF5A2D82)),
                                      if (cartCount > 0)
                                        Positioned(
                                          right: -6,
                                          top: -4,
                                          child: _Badge(count: 2),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Moving search bar with rotating hint + camera icon
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
                                .withValues(alpha: _lerp(1.0, 0.78, t)),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [
                              BoxShadow(
                                  color: Color(0x14000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 3)),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
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

                      // SINGLE location pill
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

                      // Bottom shadow as it collapses
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
                                  Colors.black.withValues(alpha: shadow),
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

            // 1) Shortcuts row (Noon-style)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _ShortcutRow(
                  items: [
                    ShortcutItem(
                        label: 'Groceries', icon: Icons.local_grocery_store),
                    ShortcutItem(
                        label: 'Deals', icon: Icons.local_fire_department),
                    ShortcutItem(
                        label: 'Express', icon: Icons.flash_on_outlined),
                    ShortcutItem(label: 'NowNow', icon: Icons.timer_outlined),
                  ],
                ),
              ),
            ),

            // 2) Big hero banner
            const SliverToBoxAdapter(
                child:
                    Padding(padding: EdgeInsets.all(16), child: _HeroBanner())),

            // 3) Slim offer strip
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _OfferStrip(
                    textLeft: 'Up to 20% cashback',
                    cta: 'Apply Now',
                    icon: Icons.credit_card),
              ),
            ),

            // 4) Free delivery card
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

            // 5) Rounded category icons (from Supabase)
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
                            child: CircularProgressIndicator(strokeWidth: 2)),
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
                                  // TODO: navigate to category page with slug
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text('Open category: ${c.slug}')),
                                  );
                                },
                              ))
                          .toList(),
                    );
                  },
                ),
              ),
            ),

            // 6) Promo carousel
            const SliverToBoxAdapter(
              child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: WmPromoAutoCarousel()),
            ),

            // 7) Infinite product grid (real data)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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

            // 8) Loaders / end spacer
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 80),
                child: Center(
                  child: _loadingMore
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : (!_hasMore
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Text('You’re all caught up!',
                                  style: TextStyle(
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w600)),
                            )
                          : const SizedBox.shrink()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Icons/gradients for categories (unchanged from your file)
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
          color: const Color(0xFF5A2D82),
          borderRadius: BorderRadius.circular(10)),
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
          const Icon(Icons.location_on, size: 18, color: Color(0xFF5A2D82)),
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
        prefixIcon: const Icon(Icons.search, color: Color(0xFF5A2D82)),
        suffixIcon: IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Camera search coming soon')),
            );
          },
          icon: const Icon(Icons.camera_alt_outlined, color: Color(0xFF5A2D82)),
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
    const purple = Color(0xFF5A2D82);
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
                            backgroundColor: purple,
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

/// ───────────────── Quick categories (Noon-style, rounded) ────────────────
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
                    color: const Color(0xFFFFF4DE),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x12000000),
                          blurRadius: 8,
                          offset: Offset(0, 4))
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Icon(it.icon, color: const Color(0xFF5A2D82)),
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

/// ───────────────── Shortcuts row ─────────────────
class ShortcutItem {
  final String label;
  final IconData icon;
  const ShortcutItem({required this.label, required this.icon});
}

class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow({required this.items});
  final List<ShortcutItem> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final it = items[i];
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {},
            child: Container(
              width: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 8,
                      offset: Offset(0, 4))
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Container(
                    height: 36,
                    width: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFF5A2D82).withValues(alpha: .08),
                    ),
                    alignment: Alignment.center,
                    child: Icon(it.icon, color: const Color(0xFF5A2D82)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      it.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// ───────────────── Big hero banner ─────────────────
class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE97A), Color(0xFFFFF9D6)],
        ),
        boxShadow: const [
          BoxShadow(
              color: Color(0x16000000), blurRadius: 12, offset: Offset(0, 6))
        ],
        image: const DecorationImage(
          image: AssetImage('assets/icon/wm_mark.png'),
          alignment: Alignment.centerRight,
          opacity: .06,
          fit: BoxFit.contain,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'SAVE ON\nEVERY SINGLE THING',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.black.withValues(alpha: .85),
            height: 1.05,
          ),
        ),
      ),
    );
  }
}

/// ───────────────── Offer strip ─────────────────
class _OfferStrip extends StatelessWidget {
  const _OfferStrip(
      {required this.textLeft, required this.cta, required this.icon});
  final String textLeft;
  final String cta;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: Color(0x12000000), blurRadius: 8, offset: Offset(0, 4))
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF5A2D82)),
          const SizedBox(width: 10),
          Expanded(
              child: Text(textLeft,
                  style: const TextStyle(fontWeight: FontWeight.w800))),
          TextButton(onPressed: () {}, child: Text(cta)),
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
      height: 140,
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
                      color: const Color(0xFF5A2D82),
                      borderRadius: BorderRadius.circular(8)),
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
            width: 120,
            decoration: BoxDecoration(
                color: const Color(0xFFFFF4DE),
                borderRadius: BorderRadius.circular(16)),
            alignment: Alignment.center,
            child: const Icon(Icons.local_shipping,
                size: 48, color: Color(0xFF5A2D82)),
          ),
        ],
      ),
    );
  }
}

/// ───────────────── Promo Carousel (as in your file) ─────────────────
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
      colors: [Color(0xFF5A2D82), Color(0xFF9C6ADE)],
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
              color: Colors.white.withValues(alpha: .20),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: .35)),
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
            color:
                i == index ? const Color(0xFF5A2D82) : const Color(0xFFD8CFEA),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}
