// lib/screens/customer/category_gallery.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:western_malabar/models/category_model.dart';
import 'package:western_malabar/services/category_service.dart';

/// Compare 6 modern category UIs.
/// Route to CategoryGalleryScreen() from AppShell when you want to preview.
class CategoryGalleryScreen extends StatefulWidget {
  const CategoryGalleryScreen({super.key});
  @override
  State<CategoryGalleryScreen> createState() => _CategoryGalleryScreenState();
}

class _CategoryGalleryScreenState extends State<CategoryGalleryScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<CategoryModel>> _catsFut;

  @override
  void initState() {
    super.initState();
    _catsFut = _load();
  }

  Future<List<CategoryModel>> _load() async {
    // Pull active categories from Supabase
    final rows = await CategoryService.fetchActive(limit: 200);
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF5A2D82);

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFFFF9EE),
          elevation: 0,
          title: const Text(
            'Categories — Layout Gallery',
            style: TextStyle(color: purple, fontWeight: FontWeight.w900),
          ),
          bottom: const TabBar(
            isScrollable: true,
            labelColor: purple,
            indicatorColor: purple,
            tabs: [
              Tab(text: '1 Glass Grid'),
              Tab(text: '2 Carousel'),
              Tab(text: '3 Icon + Filters'),
              Tab(text: '4 A→Z Sticky'),
              Tab(text: '5 Island Buttons'),
              Tab(text: '6 Masonry'),
            ],
          ),
        ),
        body: FutureBuilder<List<CategoryModel>>(
          future: _catsFut,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: purple, strokeWidth: 2),
              );
            }
            if (snap.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent),
                    const SizedBox(height: 8),
                    const Text('Couldn’t load categories'),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => setState(() =>
                          _catsFut = CategoryService.fetchActive(limit: 200)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            final cats = snap.data ?? const <CategoryModel>[];
            if (cats.isEmpty) {
              return const Center(child: Text('No categories yet'));
            }
            return TabBarView(
              children: [
                _GlassGrid(cats: cats),
                _CarouselCards(cats: cats),
                _IconGridWithFilters(cats: cats),
                _StickyAZList(cats: cats),
                _IslandButtons(cats: cats),
                _MasonryGrid(cats: cats),
              ],
            );
          },
        ),
      ),
    );
  }
}

/* ─────────────────────────────────────────────────────────────
 * 1) GLASS GRID
 * ───────────────────────────────────────────────────────────── */
class _GlassGrid extends StatelessWidget {
  const _GlassGrid({required this.cats});
  final List<CategoryModel> cats;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.15,
      ),
      itemCount: cats.length,
      itemBuilder: (_, i) =>
          _GlassCard(title: cats[i].name, color: _colorFor(cats[i].name)),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.title, required this.color});
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.10),
              color.withValues(alpha: 0.04)
            ],
          ),
          boxShadow: const [
            BoxShadow(
                color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 6))
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GlassIcon(color: color, emoji: _emojiFor(title)),
            const Spacer(),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

/* ─────────────────────────────────────────────────────────────
 * 2) CAROUSEL CARDS (Netflix-style)
 * ───────────────────────────────────────────────────────────── */
class _CarouselCards extends StatelessWidget {
  const _CarouselCards({required this.cats});
  final List<CategoryModel> cats;

  @override
  Widget build(BuildContext context) {
    final chunks = <List<CategoryModel>>[];
    for (var i = 0; i < cats.length; i += 6) {
      chunks.add(cats.sublist(i, math.min(i + 6, cats.length)));
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: chunks.length,
      itemBuilder: (_, idx) {
        final group = chunks[idx];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (idx == 0)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('Explore Categories',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: Color(0xFF5A2D82))),
              ),
            SizedBox(
              height: 140,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: group.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final c = group[i];
                  return _HeroCard(title: c.name, color: _colorFor(c.name));
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.title, required this.color});
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {},
      child: Container(
        width: 260,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.85),
              color.withValues(alpha: 0.55)
            ],
          ),
          boxShadow: const [
            BoxShadow(
                color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 6))
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
          ),
        ),
      ),
    );
  }
}

/* ─────────────────────────────────────────────────────────────
 * 3) ICON GRID + FILTERS
 * ───────────────────────────────────────────────────────────── */
class _IconGridWithFilters extends StatefulWidget {
  const _IconGridWithFilters({required this.cats});
  final List<CategoryModel> cats;

  @override
  State<_IconGridWithFilters> createState() => _IconGridWithFiltersState();
}

class _IconGridWithFiltersState extends State<_IconGridWithFilters> {
  String _filter = 'All';
  final _filters = const [
    'All',
    'Frozen',
    'Snacks',
    'Beverages',
    'Rice',
    'Masala'
  ];

  @override
  Widget build(BuildContext context) {
    final items = _filter == 'All'
        ? widget.cats
        : widget.cats
            .where((c) => c.name.toLowerCase().contains(_filter.toLowerCase()))
            .toList();

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Row(
            children: _filters.map((f) {
              final selected = f == _filter;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: ChoiceChip(
                  label: Text(f),
                  selected: selected,
                  onSelected: (_) => setState(() => _filter = f),
                  selectedColor:
                      const Color(0xFF5A2D82).withValues(alpha: 0.12),
                  labelStyle: TextStyle(
                    color: selected ? const Color(0xFF5A2D82) : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: GridView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: .88,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) => _IconTile(
                title: items[i].name, color: _colorFor(items[i].name)),
          ),
        ),
      ],
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.title, required this.color});
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 3))
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _GlassIcon(color: color, emoji: _emojiFor(title), big: true),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

/* ─────────────────────────────────────────────────────────────
 * 4) STICKY A→Z LIST
 * ───────────────────────────────────────────────────────────── */
class _StickyAZList extends StatelessWidget {
  const _StickyAZList({required this.cats});
  final List<CategoryModel> cats;

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<CategoryModel>>{};
    for (final c in cats) {
      final k = c.name.isEmpty ? '#' : c.name[0].toUpperCase();
      groups.putIfAbsent(k, () => []).add(c);
    }
    final letters = groups.keys.toList()..sort();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        for (final L in letters) ...[
          SliverPersistentHeader(
            pinned: true,
            delegate: _HeaderDelegate(
              height: 34,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerLeft,
                child: Text(L,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, color: Color(0xFF5A2D82))),
              ),
            ),
          ),
          SliverList.builder(
            itemCount: groups[L]!.length,
            itemBuilder: (_, i) => ListTile(
              leading: _GlassIcon(
                  color: _colorFor(groups[L]![i].name),
                  emoji: _emojiFor(groups[L]![i].name)),
              title: Text(groups[L]![i].name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {},
            ),
          ),
        ]
      ],
    );
  }
}

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  _HeaderDelegate({required this.height, required this.child});
  final double height;
  final Widget child;

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      child;

  @override
  bool shouldRebuild(covariant _HeaderDelegate oldDelegate) =>
      oldDelegate.height != height || oldDelegate.child != child;
}

/* ─────────────────────────────────────────────────────────────
 * 5) ISLAND BUTTONS (3D pills)
 * ───────────────────────────────────────────────────────────── */
class _IslandButtons extends StatelessWidget {
  const _IslandButtons({required this.cats});
  final List<CategoryModel> cats;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: cats
            .map((c) => _IslandPill(title: c.name, color: _colorFor(c.name)))
            .toList(),
      ),
    );
  }
}

class _IslandPill extends StatefulWidget {
  const _IslandPill({required this.title, required this.color});
  final String title;
  final Color color;

  @override
  State<_IslandPill> createState() => _IslandPillState();
}

class _IslandPillState extends State<_IslandPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _a;
  @override
  void initState() {
    super.initState();
    _a = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
  }

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _a.forward(),
      onTapUp: (_) => _a.reverse(),
      onTapCancel: () => _a.reverse(),
      onTap: () {},
      child: ScaleTransition(
        scale: Tween(begin: 1.0, end: 0.97)
            .animate(CurvedAnimation(parent: _a, curve: Curves.easeOut)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(colors: [
              widget.color.withValues(alpha: .18),
              widget.color.withValues(alpha: .08)
            ]),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 10,
                  offset: Offset(0, 6))
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _GlassIcon(color: widget.color, emoji: _emojiFor(widget.title)),
              const SizedBox(width: 10),
              Text(widget.title,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}

/* ─────────────────────────────────────────────────────────────
 * 6) MASONRY GRID (2-column manual)
 * ───────────────────────────────────────────────────────────── */
class _MasonryGrid extends StatelessWidget {
  const _MasonryGrid({required this.cats});
  final List<CategoryModel> cats;

  @override
  Widget build(BuildContext context) {
    // simple 2-column waterfall: alternate heights using title length
    final left = <CategoryModel>[];
    final right = <CategoryModel>[];
    for (var i = 0; i < cats.length; i++) {
      (i % 2 == 0 ? left : right).add(cats[i]);
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              child: Column(
                  children: left.map((c) => _MasonryTile(c: c)).toList())),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  children: right.map((c) => _MasonryTile(c: c)).toList())),
        ],
      ),
    );
  }
}

class _MasonryTile extends StatelessWidget {
  const _MasonryTile({required this.c});
  final CategoryModel c;

  @override
  Widget build(BuildContext context) {
    final h = 110 + (c.name.length % 3) * 20.0; // pseudo-variable height
    final color = _colorFor(c.name);
    return InkWell(
      onTap: () {},
      child: Container(
        height: h,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(colors: [
            color.withValues(alpha: .12),
            color.withValues(alpha: .06)
          ]),
          boxShadow: const [
            BoxShadow(
                color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 6))
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GlassIcon(color: color, emoji: _emojiFor(c.name)),
            const Spacer(),
            Text(c.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

/* ─────────────────────────────────────────────────────────────
 * Shared bits
 * ───────────────────────────────────────────────────────────── */
class _GlassIcon extends StatelessWidget {
  const _GlassIcon(
      {required this.color, required this.emoji, this.big = false});
  final Color color;
  final String emoji;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final size = big ? 50.0 : 44.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: color.withValues(alpha: 0.18),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: TextStyle(fontSize: big ? 26 : 22)),
    );
  }
}

String _emojiFor(String name) {
  final n = name.toLowerCase();
  if (n.contains('rice')) return '🍚';
  if (n.contains('masala') || n.contains('spice')) return '🫚';
  if (n.contains('frozen')) return '❄️';
  if (n.contains('snack')) return '🍘';
  if (n.contains('beverage') || n.contains('coffee') || n.contains('tea')) {
    return '☕️';
  }
  if (n.contains('dairy')) return '🥛';
  if (n.contains('vegetable') || n.contains('veg')) return '🥦';
  if (n.contains('oil')) return '🫙';
  if (n.contains('sweet')) return '🍬';
  return '🛒';
}

Color _colorFor(String s) {
  const palette = [
    Color(0xFF5A2D82), // purple
    Color(0xFFF0C53E), // gold
    Color(0xFF5DBB63), // green
    Color(0xFF6E7FF3), // blue-ish
    Color(0xFFFF9F59), // saffron
  ];
  final h = s.toLowerCase().hashCode;
  return palette[h % palette.length];
}
