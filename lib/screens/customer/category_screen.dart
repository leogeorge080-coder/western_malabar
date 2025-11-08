// lib/screens/customer/category_screen.dart
import 'package:flutter/material.dart';

import 'package:western_malabar/models/category_model.dart';
import 'package:western_malabar/services/category_service.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final _scroll = ScrollController();
  final _search = TextEditingController();

  List<CategoryModel> _all = [];
  bool _loading = true;
  String _query = '';
  final Map<String, int> _letterIndex = {}; // letter -> list index

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(() => setState(() => _query = _search.text.trim()));
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await CategoryService.fetchActive(limit: 200);
      data.sort((a, b) {
        final so = (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0);
        return so != 0
            ? so
            : (a.name).toLowerCase().compareTo((b.name).toLowerCase());
      });
      _buildLetterIndex(data);
      if (!mounted) return;
      setState(() {
        _all = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load categories: $e')),
      );
      setState(() => _loading = false);
    }
  }

  void _buildLetterIndex(List<CategoryModel> data) {
    _letterIndex.clear();
    for (int i = 0; i < data.length; i++) {
      final name = (data[i].name).trim();
      final letter = name.isEmpty ? '#' : name[0].toUpperCase();
      _letterIndex.putIfAbsent(letter, () => i);
    }
  }

  List<CategoryModel> get _filtered {
    if (_query.isEmpty) return _all;
    final q = _query.toLowerCase();
    return _all.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  void _jumpToLetter(String letter) {
    final items = _filtered;
    if (items.isEmpty) return;
    final idx = items.indexWhere(
      (c) => c.name.isNotEmpty && c.name[0].toUpperCase() == letter,
    );
    if (idx <= 0) {
      _scroll.animateTo(0,
          duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
    } else {
      final row = (idx / 2).floor(); // 2 columns
      final maxOff = _scroll.position.maxScrollExtent;
      final offset = ((row * 140.0)).clamp(0.0, maxOff).toDouble();
      _scroll.animateTo(offset,
          duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF5A2D82);

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _load,
        color: purple,
        child: CustomScrollView(
          controller: _scroll,
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // Sticky header with title + search
            SliverAppBar(
              pinned: true,
              floating: false,
              expandedHeight: 120,
              backgroundColor: const Color(0xFFFFF9EE),
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              flexibleSpace: LayoutBuilder(
                builder: (context, c) {
                  final t = _clamp01(
                    (c.biggest.height - kToolbarHeight) /
                        (120 - kToolbarHeight),
                  );
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned(
                        left: 16,
                        right: 16,
                        top: MediaQuery.of(context).padding.top + (t * 8),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Categories',
                              style: TextStyle(
                                color: purple,
                                fontWeight: FontWeight.w900,
                                fontSize: 22,
                              ),
                            ),
                            Icon(Icons.grid_view_rounded, color: purple),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 10,
                        child: _SearchField(controller: _search),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Quick Picks chips (top 8)
            SliverToBoxAdapter(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _loading
                    ? const SizedBox(height: 60)
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _all.take(8).map((c) {
                            return _QuickChip(
                              label: c.name,
                              onTap: () => _onCategoryTap(c),
                            );
                          }).toList(),
                        ),
                      ),
              ),
            ),

            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 6),
                child: Text(
                  'All Categories',
                  style: TextStyle(
                    color: purple,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            // Grid
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 80),
              sliver: _loading
                  ? _ShimmerGrid()
                  : SliverLayoutBuilder(
                      builder: (context, constraints) {
                        final w = constraints.crossAxisExtent;
                        final cols = w > 720
                            ? 4
                            : w > 520
                                ? 3
                                : 2;
                        final items = _filtered;
                        return SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.15,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, i) {
                              final c = items[i];
                              return _CategoryCard(
                                name: c.name,
                                accentColor: _colorFor(c.name),
                                onTap: () => _onCategoryTap(c),
                              );
                            },
                            childCount: items.length,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),

      // A→Z jump bar
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      floatingActionButton: _AZBar(
        onTap: _jumpToLetter,
      ),
    );
  }

  // Simple brand-colored loop for variety
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

  void _onCategoryTap(CategoryModel c) {
    // TODO: navigate to your Category → Product listing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Open "${c.name}"')),
    );
  }
}

/// Search field used in the header
class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF5A2D82);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: const InputDecoration(
          hintText: 'Search categories…',
          prefixIcon: Icon(Icons.search, color: purple),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        ),
      ),
    );
  }
}

/// Small rounded chips for quick picks
class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.label, this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
                color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Category card with subtle glass look + icon
class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.name,
    required this.accentColor,
    this.onTap,
  });

  final String name;
  final Color accentColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final emoji = _pickEmoji(name);
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 280),
      tween: Tween(begin: 0.94, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accentColor.withValues(alpha: 0.10),
                accentColor.withValues(alpha: 0.04),
              ],
            ),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 10,
                  offset: Offset(0, 6)),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GlassIcon(accentColor: accentColor, emoji: emoji),
              const Spacer(),
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _pickEmoji(String name) {
    final n = name.toLowerCase();
    if (n.contains('rice')) return '🍚';
    if (n.contains('masala') || n.contains('spice')) return '🫚';
    if (n.contains('frozen')) return '❄️';
    if (n.contains('snack')) return '🍘';
    if (n.contains('beverage') || n.contains('coffee') || n.contains('tea')) {
      return '☕';
    }
    if (n.contains('dairy')) return '🥛';
    if (n.contains('vegetable') || n.contains('veg')) return '🥦';
    if (n.contains('oil')) return '🫙';
    if (n.contains('sweet')) return '🍬';
    return '🛒';
  }
}

class _GlassIcon extends StatelessWidget {
  const _GlassIcon({required this.accentColor, required this.emoji});
  final Color accentColor;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: accentColor.withValues(alpha: 0.18),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 22)),
    );
  }
}

/// Lightweight shimmer without extra packages
class _ShimmerGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.15,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, i) {
          return _ShimmerBox();
        },
        childCount: 6,
      ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _a;

  @override
  void initState() {
    super.initState();
    _a = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (context, _) {
        final t = _a.value;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment(-1 + t * 2, -1),
              end: Alignment(1 + t * 2, 1),
              colors: const [
                Color(0xFFF5F5F5),
                Color(0xFFEDEDED),
                Color(0xFFF5F5F5),
              ],
              stops: const [0.2, 0.5, 0.8],
            ),
          ),
        );
      },
    );
  }
}

/// A→Z bar (simple)
class _AZBar extends StatelessWidget {
  const _AZBar({required this.onTap});
  final void Function(String letter) onTap;

  @override
  Widget build(BuildContext context) {
    const letters = [
      'A',
      'B',
      'C',
      'D',
      'E',
      'F',
      'G',
      'H',
      'I',
      'J',
      'K',
      'L',
      'M',
      'N',
      'O',
      'P',
      'Q',
      'R',
      'S',
      'T',
      'U',
      'V',
      'W',
      'X',
      'Y',
      'Z'
    ];
    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 70),
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: letters.map((l) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(l),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                child: const Text(
                  '', // keep narrow tap target; add letters if you prefer
                  style: TextStyle(fontSize: 11, color: Colors.black45),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ---- helpers (double-safe) ----
double _clamp01(num v) => v.clamp(0.0, 1.0).toDouble();
