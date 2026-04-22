import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:western_malabar/features/catalog/models/category_model.dart';
import 'package:western_malabar/features/search/screens/global_product_search_screen.dart';
import 'package:western_malabar/features/catalog/services/category_service.dart';
import 'package:western_malabar/features/cart/widgets/sticky_cart_bar.dart';
import 'package:western_malabar/features/catalog/screens/subcategory_products_screen.dart';

const _wmSubBg = Color(0xFFF7F7F7);
const _wmSubSurface = Colors.white;
const _wmSubBorder = Color(0xFFE5E7EB);

const _wmSubTextStrong = Color(0xFF111827);
const _wmSubTextSoft = Color(0xFF6B7280);
const _wmSubTextMuted = Color(0xFF9CA3AF);

const _wmSubPrimary = Color(0xFF2A2F3A);
const _wmSubPrimaryDark = Color(0xFF171A20);

class SubcategoryScreen extends ConsumerStatefulWidget {
  const SubcategoryScreen({
    super.key,
    required this.parentName,
    required this.parentSlug,
  });

  final String parentName;
  final String parentSlug;

  @override
  ConsumerState<SubcategoryScreen> createState() => _SubcategoryScreenState();
}

class _SubcategoryScreenState extends ConsumerState<SubcategoryScreen> {
  bool _loading = true;
  List<CategoryModel> _items = [];
  final TextEditingController _search = TextEditingController();
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
      final data = await CategoryService.fetchChildrenByParentSlug(
        widget.parentSlug,
      );
      if (!mounted) return;
      setState(() {
        _items = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load subcategories: $e')),
      );
    }
  }

  List<CategoryModel> get _filtered {
    if (_query.isEmpty) return _items;
    final q = _query.toLowerCase();
    return _items.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  void _openGlobalSearch([String initial = '']) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GlobalProductSearchScreen(initialQuery: initial),
      ),
    );
  }

  void _openSubcategory(CategoryModel c) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubcategoryProductsScreen(
          title: c.name,
          subcategorySlug: c.slug,
        ),
      ),
    );
  }

  List<CategoryModel> _topPicks(List<CategoryModel> source) {
    return source.take(5).toList();
  }

  List<CategoryModel> _guidedChoices(List<CategoryModel> source) {
    return source.take(6).toList();
  }

  String _choiceLabel(String name) {
    final n = name.toLowerCase();
    if (n.contains('rice') || n.contains('grain')) return 'Everyday staples';
    if (n.contains('frozen')) return 'Quick meals';
    if (n.contains('snack') || n.contains('sweet')) return 'Treats';
    if (n.contains('spice') || n.contains('masala')) return 'Cook tonight';
    if (n.contains('tea') || n.contains('coffee')) return 'Tea break';
    return name;
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;

    return Scaffold(
      backgroundColor: _wmSubBg,
      body: Stack(
        children: [
          Container(
            color: _wmSubBg,
            child: RefreshIndicator(
              onRefresh: _load,
              color: _wmSubPrimary,
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
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: _wmSubSurface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _wmSubBorder),
                            ),
                            child: IconButton(
                              onPressed: () => Navigator.maybePop(context),
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: _wmSubPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.parentName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w900,
                                color: _wmSubTextStrong,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                      child: Text(
                        'Choose a subcategory or search all products across the store.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _wmSubTextSoft.withOpacity(0.95),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: _SearchLaunchField(
                        controller: _search,
                        hint: 'Search subcategories or all products…',
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
                      child: _AisleHeroCard(
                        title: widget.parentName,
                        onSearchTap: () {
                          if (_search.text.trim().isEmpty) {
                            _openGlobalSearch(widget.parentName);
                          } else {
                            _openGlobalSearch(_search.text.trim());
                          }
                        },
                      ),
                    ),
                  ),
                  if (!_loading && items.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                        child: const _SectionHeading(
                          title: 'Top picks in this aisle',
                          subtitle:
                              'Start with the most likely paths to the product you need.',
                        ),
                      ),
                    ),
                  if (!_loading && items.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 0, 0),
                        child: _TopPickStrip(
                          items: _topPicks(items),
                          onTap: _openSubcategory,
                        ),
                      ),
                    ),
                  if (!_loading && items.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _guidedChoices(items)
                              .map(
                                (c) => _QuickChoiceChip(
                                  label: _choiceLabel(c.name),
                                  onTap: () => _openSubcategory(c),
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
                            ? 'All sub-aisles'
                            : 'Matching sub-aisles',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: _wmSubTextStrong,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    sliver: _loading
                        ? const _ShimmerGrid()
                        : items.isEmpty
                            ? const SliverToBoxAdapter(
                                child: _EmptyState(
                                  title: 'No subcategories found',
                                  subtitle:
                                      'Try another keyword or search the full catalog.',
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
                                    return _SubcategoryCard(
                                      name: c.name,
                                      subtitle:
                                          'Jump straight into products in this aisle',
                                      onTap: () => _openSubcategory(c),
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
          const StickyCartBar(bottom: 16),
        ],
      ),
    );
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
    return Container(
      decoration: BoxDecoration(
        color: _wmSubSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _wmSubBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
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
          hintStyle: const TextStyle(
            color: _wmSubTextSoft,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: const Icon(Icons.search, color: _wmSubPrimary),
          suffixIcon: IconButton(
            onPressed: onSearchTap,
            icon: const Icon(Icons.arrow_forward_rounded, color: _wmSubPrimary),
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

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: _wmSubTextStrong,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _wmSubTextSoft,
          ),
        ),
      ],
    );
  }
}

class _AisleHeroCard extends StatelessWidget {
  const _AisleHeroCard({
    required this.title,
    required this.onSearchTap,
  });

  final String title;
  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [_wmSubPrimaryDark, _wmSubPrimary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shop $title faster',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Start with the best-known sub-aisles, then drop into products with fewer taps.',
                  style: TextStyle(
                    color: Color(0xFFE5E7EB),
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
              foregroundColor: _wmSubPrimary,
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

class _TopPickStrip extends StatelessWidget {
  const _TopPickStrip({
    required this.items,
    required this.onTap,
  });

  final List<CategoryModel> items;
  final ValueChanged<CategoryModel> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(right: 16),
        itemBuilder: (context, index) {
          final item = items[index];
          return _TopPickCard(
            name: item.name,
            onTap: () => onTap(item),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: items.length,
      ),
    );
  }
}

class _TopPickCard extends StatelessWidget {
  const _TopPickCard({
    required this.name,
    required this.onTap,
  });

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 144,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _wmSubSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _wmSubBorder),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: const Color(0xFFF3F4F6),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.chevron_right_rounded,
                color: _wmSubPrimary,
              ),
            ),
            const Spacer(),
            Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: _wmSubTextStrong,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickChoiceChip extends StatelessWidget {
  const _QuickChoiceChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _wmSubSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _wmSubBorder),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: _wmSubTextStrong,
          ),
        ),
      ),
    );
  }
}

class _SubcategoryCard extends StatelessWidget {
  const _SubcategoryCard({
    required this.name,
    required this.subtitle,
    this.onTap,
  });

  final String name;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: _wmSubSurface,
          border: Border.all(color: _wmSubBorder),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C000000),
              blurRadius: 10,
              offset: Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFFF3F4F6),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.category_outlined,
                color: _wmSubPrimary,
                size: 26,
              ),
            ),
            const Spacer(),
            Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: _wmSubTextStrong,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _wmSubTextSoft,
              ),
            ),
          ],
        ),
      ),
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
          color: _wmSubSurface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _wmSubBorder),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C000000),
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
              color: _wmSubPrimary,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: _wmSubTextStrong,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _wmSubTextSoft,
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
