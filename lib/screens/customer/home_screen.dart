// lib/screens/customer/home_screen.dart
import 'dart:async';
import 'dart:math' show max;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'package:western_malabar/models/category_model.dart';
import 'package:western_malabar/services/category_service.dart';

/// ─────────────────────────────────────────────────────────────
///  Modern product grid (floating price tags) – demo data
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

class WMTodaysPicksGrid extends StatelessWidget {
  const WMTodaysPicksGrid({
    super.key,
    required this.products,
    this.title = "Today's Picks",
    this.onAdd,
    this.onTap,
    this.crossAxisCount = 2,
  });

  final List<WmProduct> products;
  final String title;
  final void Function(WmProduct product)? onAdd;
  final void Function(WmProduct product)? onTap;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF5A2D82);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: purple,
          ),
        ),
        const SizedBox(height: 10),
        if (products.isEmpty)
          const _EmptyState()
        else
          GridView.builder(
            shrinkWrap: true,
            primary: false,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: .78,
            ),
            itemCount: products.length,
            itemBuilder: (context, i) => _ProductTile(
              product: products[i],
              onAdd: onAdd,
              onTap: onTap,
            ),
          ),
      ],
    );
  }
}

class _ProductTile extends StatefulWidget {
  const _ProductTile({
    required this.product,
    this.onAdd,
    this.onTap,
  });

  final WmProduct product;
  final void Function(WmProduct product)? onAdd;
  final void Function(WmProduct product)? onTap;

  @override
  State<_ProductTile> createState() => _ProductTileState();
}

class _ProductTileState extends State<_ProductTile>
    with SingleTickerProviderStateMixin {
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
                offset: Offset(0, 6),
              ),
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
                          top: Radius.circular(18),
                        ),
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
                      child: _PriceTag(text: _gbp(p.priceCents)),
                    ),
                    Positioned(
                      left: 10,
                      bottom: 10,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 150),
                        opacity: _pressed ? 1 : 0,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5A2D82),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
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
                    Text(
                      p.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _gbp(p.priceCents),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
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
            color: Color(0x22000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        'No picks yet — check back soon!',
        style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
      ),
    );
  }
}

String _gbp(int cents) => '£${(cents / 100.0).toStringAsFixed(2)}';

/// ─────────────────────────────────────────────────────────────
///  HOME SCREEN (loads categories from Supabase)
/// ─────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ScrollController _c;
  double _t = 0.0; // 0 = expanded, 1 = collapsed

  late Future<List<CategoryModel>> _catsFuture;

  @override
  void initState() {
    super.initState();
    _c = ScrollController()..addListener(() {});
    _catsFuture = CategoryService.fetchTop(limit: 14);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    const double expandedHeight = 170;
    const double collapsedHeight = 64;

    return Scaffold(
      body: CustomScrollView(
        controller: _c,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ───────── Header (frosted + moving search + ONE location pill) ─────────
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
                if (t != _t) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _t = t);
                  });
                }

                final shadow = (t > 0.06)
                    ? 0.16 * ((t - 0.06) / .34).clamp(0.0, 1.0)
                    : 0.0;

                const searchHExpanded = 46.0;
                const searchHCollapsed = 40.0;
                final searchTopExpanded = topPad + 46;
                final searchTopCollapsed =
                    topPad + (kToolbarHeight - searchHCollapsed) / 2;

                final searchTop =
                    _lerp(searchTopExpanded, searchTopCollapsed, t);
                final searchH = _lerp(searchHExpanded, searchHCollapsed, t);

                const cartCount = 2;

                return Stack(
                  fit: StackFit.expand,
                  children: [
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
                          child: SizedBox(
                            height: 36,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
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
                                    const Icon(Icons.shopping_bag_outlined,
                                        color: Color(0xFF5A2D82)),
                                    if (cartCount > 0)
                                      const Positioned(
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

                    // Moving search bar
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 140),
                      curve: Curves.easeOut,
                      left: 16,
                      right: 16,
                      top: searchTop,
                      height: searchH,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(_lerp(1.0, 0.78, t)),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.centerLeft,
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search Masalas & Spices 🔍',
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Color(0xFF5A2D82),
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(
                                Icons.mic_none_outlined,
                                color: Color(0xFF5A2D82),
                              ),
                              onPressed: () {},
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
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
                          label: 'Deliver to Leo – Scunthorpe DN15',
                        ),
                      ),
                    ),

                    // soft shadow after a tiny scroll
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

          // ─────────── BODY ───────────
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // QUICK CATEGORY STRIP (LIVE from Supabase)
                  FutureBuilder<List<CategoryModel>>(
                    future: _catsFuture,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 60,
                          child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        );
                      }
                      if (snap.hasError) {
                        return _QuickCatError(
                          message: 'Couldn’t load categories',
                          onRetry: () {
                            setState(() {
                              _catsFuture = CategoryService.fetchTop(limit: 14);
                            });
                          },
                        );
                      }
                      final rows = snap.data ?? const <CategoryModel>[];
                      if (rows.isEmpty) {
                        return _QuickCatEmpty(
                          onRetry: () {
                            setState(() {
                              _catsFuture = CategoryService.fetchTop(limit: 14);
                            });
                          },
                        );
                      }
                      final items =
                          rows.map((r) => _mapRowToQuickCat(r)).toList();
                      return Column(
                        children: [
                          WmQuickCategories(
                            items: items,
                            onTap: (slug) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Open category: $slug')),
                              );
                              // TODO: Navigate to CategoryScreen filtered by `slug`
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                      );
                    },
                  ),

                  // Animated promo carousel (non-gold)
                  const WmPromoAutoCarousel(),

                  const SizedBox(height: 16),

                  // Products Grid (sample)
                  const WMTodaysPicksGrid(
                    products: [
                      WmProduct(
                        id: '1',
                        name: 'Appam Podi 1kg',
                        priceCents: 349,
                        imageUrl: null,
                      ),
                      WmProduct(
                        id: '2',
                        name: 'Murukku 200g',
                        priceCents: 279,
                        imageUrl: null,
                      ),
                      WmProduct(
                        id: '3',
                        name: 'Jeerakasala Rice 5kg',
                        priceCents: 2399,
                        imageUrl: null,
                      ),
                      WmProduct(
                        id: '4',
                        name: 'Coconut Oil 1L',
                        priceCents: 599,
                        imageUrl: null,
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
                      _CategoryChip(label: 'Today’s Offers'),
                      _CategoryChip(label: 'Health & Ayurvedic Items'),
                      _CategoryChip(label: 'Household & Religious Items'),
                      _CategoryChip(label: 'Pulses & Lentils'),
                      _CategoryChip(label: 'Seasonal & Festival Specials'),
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

  // Map DB row to visual pill (icon + gradient)
  QuickCat _mapRowToQuickCat(CategoryModel r) {
    final icon = _iconForSlug(r.slug);
    final colors = _gradientForSlug(r.slug);
    return QuickCat(slug: r.slug, label: r.name, icon: icon, colors: colors);
  }

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

  List<Color> _gradientForSlug(String slug) {
    switch (slug) {
      case 'rice':
        return const [Color(0xFF5A2D82), Color(0xFF9C6ADE)]; // purple→lavender
      case 'masalas-spices':
      case 'spices':
        return const [Color(0xFF3949AB), Color(0xFF4FC3F7)]; // indigo→cyan
      case 'frozen-snacks':
      case 'frozen-vegetables':
      case 'frozen-breakfast':
        return const [Color(0xFF009688), Color(0xFF80CBC4)]; // teal→mint
      case 'snacks':
        return const [Color(0xFF8E24AA), Color(0xFFE1BEE7)]; // violet→lilac
      case 'beverages':
        return const [Color(0xFF1E88E5), Color(0xFF90CAF9)]; // blue→light
      case 'dairy':
        return const [Color(0xFF43A047), Color(0xFFA5D6A7)]; // green→light
      case 'pulses-lentils':
        return const [Color(0xFF6D4C41), Color(0xFFBCAAA4)]; // brown→sand
      case 'pickles':
        return const [Color(0xFF558B2F), Color(0xFFAED581)]; // olive→lime
      case 'ready-to-eat':
        return const [Color(0xFFBA68C8), Color(0xFFFFCDD2)]; // mauve→rose
      case 'cooking-oil':
        return const [Color(0xFFFF7043), Color(0xFFFFB74D)]; // orange→amber
      default:
        return const [Color(0xFF607D8B), Color(0xFFB0BEC5)]; // blue grey
    }
  }
}

/// ────────────────── helpers / small widgets ──────────────────
class _Badge extends StatelessWidget {
  const _Badge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF5A2D82),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
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
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, size: 18, color: Color(0xFF5A2D82)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
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

/// ─────────────────────────────────────────────────────────────
///  Quick Category Strip (scrolling gradient pills)
/// ─────────────────────────────────────────────────────────────
class QuickCat {
  final String slug;
  final String label;
  final IconData icon;
  final List<Color> colors; // [start, end]
  const QuickCat({
    required this.slug,
    required this.label,
    required this.icon,
    required this.colors,
  });
}

class WmQuickCategories extends StatelessWidget {
  const WmQuickCategories({
    super.key,
    required this.items,
    this.onTap,
    this.height = 60,
    this.itemWidth = 160,
  });

  final List<QuickCat> items;
  final void Function(String slug)? onTap;
  final double height;
  final double itemWidth;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final it = items[i];
          return _CatPill(
            width: itemWidth,
            icon: it.icon,
            label: it.label,
            colors: it.colors,
            onTap: () => onTap?.call(it.slug),
          );
        },
      ),
    );
  }
}

class _CatPill extends StatelessWidget {
  const _CatPill({
    required this.width,
    required this.icon,
    required this.label,
    required this.colors,
    this.onTap,
  });

  final double width;
  final IconData icon;
  final String label;
  final List<Color> colors;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          boxShadow: const [
            BoxShadow(
                color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.22),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(.35)),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────
///  QuickCat states: error & empty (added to fix missing widgets)
/// ─────────────────────────────────────────────────────────────
class _QuickCatError extends StatelessWidget {
  const _QuickCatError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFD32F2F)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF7A1B1B),
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _QuickCatEmpty extends StatelessWidget {
  const _QuickCatEmpty({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E6F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.tag_outlined, color: Color(0xFF5A2D82)),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'No categories yet — add some in Supabase.',
              style: TextStyle(
                color: Color(0xFF475467),
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: onRetry,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────
///  Animated Promo Carousel (non-gold, auto-scrolling)
/// ─────────────────────────────────────────────────────────────
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
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
              color: Color(0x16000000), blurRadius: 12, offset: Offset(0, 6)),
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
            color:
                i == index ? const Color(0xFF5A2D82) : const Color(0xFFD8CFEA),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

// math helpers
double _lerp(double a, double b, double t) => a + (b - a) * t;
double _clamp01(num v) => v.clamp(0.0, 1.0).toDouble();
