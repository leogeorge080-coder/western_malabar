import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:western_malabar/features/catalog/models/category_model.dart';
import 'package:western_malabar/features/cart/screens/cart_screen.dart';
import 'package:western_malabar/features/search/screens/global_product_search_screen.dart';
import 'package:western_malabar/features/catalog/screens/subcategory_screen.dart';
import 'package:western_malabar/features/catalog/services/category_service.dart';
import 'package:western_malabar/features/cart/providers/cart_provider.dart';
import 'package:western_malabar/shared/theme/wm_gradients.dart';
import 'package:western_malabar/features/cart/widgets/sticky_cart_bar.dart';

class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({super.key});

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  final _search = TextEditingController();

  List<CategoryModel> _all = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(() {
      setState(() => _query = _search.text.trim());
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await CategoryService.fetchCatalogCategories(limit: 200);
      data.sort((a, b) {
        final so = a.sortOrder.compareTo(b.sortOrder);
        return so != 0
            ? so
            : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      if (!mounted) return;
      setState(() {
        _all = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load categories: $e')),
      );
    }
  }

  List<CategoryModel> get _filtered {
    if (_query.isEmpty) return _all;
    final q = _query.toLowerCase();
    return _all.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  void _openGlobalSearch([String initial = '']) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GlobalProductSearchScreen(initialQuery: initial),
      ),
    );
  }

  void _onCategoryTap(CategoryModel c) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubcategoryScreen(
          parentName: c.name,
          parentSlug: c.slug,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF5A2D82);
    final items = _filtered;

    // Watch cart provider
    final cartItems = ref.watch(cartProvider);
    final cartCount = cartItems.fold<int>(0, (sum, item) => sum + item.qty);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: WMGradients.pageBackground,
            ),
            child: RefreshIndicator(
              onRefresh: _load,
              color: purple,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        MediaQuery.of(context).padding.top + 10,
                        16,
                        0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Browse Categories',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: purple,
                            ),
                          ),
                          Stack(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.shopping_cart_outlined,
                                  color: purple,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const CartScreen(),
                                    ),
                                  );
                                },
                              ),
                              if (cartCount > 0)
                                Positioned(
                                  right: 6,
                                  top: 6,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Text(
                                      '$cartCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Text(
                        'Find South Indian groceries faster with category browse or global search.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black.withValues(alpha: 0.58),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: _SearchLaunchField(
                        controller: _search,
                        hint: 'Search categories or all products…',
                        onSubmitted: (value) {
                          if (value.trim().isEmpty) {
                            _openGlobalSearch();
                          } else {
                            _openGlobalSearch(value.trim());
                          }
                        },
                        onSearchTap: () {
                          if (_search.text.trim().isEmpty) {
                            _openGlobalSearch();
                          } else {
                            _openGlobalSearch(_search.text.trim());
                          }
                        },
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: _HeroBrowseCard(
                        onSearchTap: () => _openGlobalSearch(),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            (_query.isEmpty ? _all.take(8) : items.take(8))
                                .map(
                                  (c) => _QuickChip(
                                    label: c.name,
                                    onTap: () => _onCategoryTap(c),
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        _query.isEmpty
                            ? 'All Categories'
                            : 'Matching Categories',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: purple,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: _loading
                        ? const _ShimmerGrid()
                        : items.isEmpty
                            ? const SliverToBoxAdapter(
                                child: _EmptyState(
                                  title: 'No categories found',
                                  subtitle:
                                      'Try a different category keyword or search all products instead.',
                                ),
                              )
                            : SliverGrid(
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 14,
                                  mainAxisSpacing: 14,
                                  childAspectRatio: 1.05,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, i) {
                                    final c = items[i];
                                    return _CategoryCard(
                                      name: c.name,
                                      subtitle:
                                          'Browse items inside this section',
                                      accentColor: _colorFor(c.name),
                                      onTap: () => _onCategoryTap(c),
                                    );
                                  },
                                  childCount: items.length,
                                ),
                              ),
                  ),
                ],
              ),
            ),
          ),
          const StickyCartBar(
            bottom: 76,
          ),
        ],
      ),
    );
  }

  Color _colorFor(String s) {
    const palette = [
      Color(0xFF5A2D82),
      Color(0xFFF0C53E),
      Color(0xFF5DBB63),
      Color(0xFF6E7FF3),
      Color(0xFFFF9F59),
    ];
    final h = s.toLowerCase().hashCode;
    return palette[h % palette.length];
  }
}

class _SearchLaunchField extends StatelessWidget {
  const _SearchLaunchField({
    required this.controller,
    required this.hint,
    required this.onSubmitted,
    required this.onSearchTap,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF5A2D82);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search, color: purple),
          suffixIcon: IconButton(
            onPressed: onSearchTap,
            icon: const Icon(Icons.arrow_forward_rounded, color: purple),
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

class _HeroBrowseCard extends StatelessWidget {
  const _HeroBrowseCard({required this.onSearchTap});

  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF5A2D82);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF5A2D82), Color(0xFF7B4AB1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shop by category or search everything',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Rice, masala, frozen foods, snacks, tea, and more.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: onSearchTap,
            style: TextButton.styleFrom(
              foregroundColor: purple,
              backgroundColor: Colors.white,
            ),
            child: const Text(
              'Search',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

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
              color: Color(0x14000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.name,
    required this.subtitle,
    required this.accentColor,
    this.onTap,
  });

  final String name;
  final String subtitle;
  final Color accentColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final emoji = _pickEmoji(name);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accentColor.withValues(alpha: 0.11),
              accentColor.withValues(alpha: 0.05),
            ],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 10,
              offset: Offset(0, 6),
            ),
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
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black.withValues(alpha: 0.56),
              ),
            ),
          ],
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
    if (n.contains('sweet')) return '🍬';
    return '🛒';
  }
}

class _GlassIcon extends StatelessWidget {
  const _GlassIcon({
    required this.accentColor,
    required this.emoji,
  });

  final Color accentColor;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: accentColor.withValues(alpha: 0.18),
        border: Border.all(color: accentColor.withValues(alpha: 0.20)),
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 28)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 42,
              color: Color(0xFF5A2D82),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerGrid extends StatelessWidget {
  const _ShimmerGrid();

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.05,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, i) => const _ShimmerBox(),
        childCount: 6,
      ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox();

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
            borderRadius: BorderRadius.circular(20),
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




