import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:western_malabar/features/catalog/models/category_model.dart';
import 'package:western_malabar/features/catalog/services/product_service.dart';
import 'package:western_malabar/features/catalog/screens/subcategory_screen.dart';
import 'package:western_malabar/features/search/providers/search_controller.dart';
import 'package:western_malabar/shared/widgets/wm_product_image.dart';

class SearchSuggestions extends ConsumerWidget {
  const SearchSuggestions({
    super.key,
    required this.state,
  });

  final SearchSessionState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = state.suggestionProducts.take(6).toList();
    final categories = state.suggestionCategories.take(3).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
      children: [
        if (products.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 2, 4, 10),
            child: Text(
              'Top results',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.black54,
              ),
            ),
          ),
          SizedBox(
            height: 176,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _SuggestionProductCard(
                product: products[i],
                isTopMatch: i == 0,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (state.isSuggesting && products.isEmpty) ...[
          const _SuggestionSkeleton(),
          const SizedBox(height: 12),
          const _SuggestionSkeleton(),
          const SizedBox(height: 12),
        ],
        if (categories.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 6, 4, 8),
            child: Text(
              'Categories',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.black54,
              ),
            ),
          ),
          ...categories.map((c) => _CategorySuggestionTile(category: c)),
          const SizedBox(height: 10),
        ],
        if (state.query.trim().isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE8E1EE)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 2,
              ),
              leading: const Icon(
                Icons.search_rounded,
                color: Color(0xFF5A2D82),
              ),
              title: Text(
                'Search all products for "${state.query.trim()}"',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              onTap: () async {
                FocusScope.of(context).unfocus();
                await ref
                    .read(searchProvider.notifier)
                    .commitQuery(state.query);
              },
            ),
          ),
      ],
    );
  }
}

class _SuggestionProductCard extends ConsumerWidget {
  const _SuggestionProductCard({
    required this.product,
    this.isTopMatch = false,
  });

  final WmProductDto product;
  final bool isTopMatch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final image =
        product.images.isNotEmpty ? product.images.first.toString() : null;
    final price = product.displayPriceCents / 100.0;
    final brand = (product.brandName ?? '').trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          FocusScope.of(context).unfocus();
          await ref
              .read(searchProvider.notifier)
              .selectSuggestionProduct(product);
        },
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: 150,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE6E6E6)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: ColoredBox(
                    color: const Color(0xFFF7F4FA),
                    child: WmProductImage(
                      imageUrl: image,
                      width: double.infinity,
                      height: double.infinity,
                      borderRadius: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (isTopMatch) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3ECFB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Top match',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF5A2D82),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],
              if (brand.isNotEmpty) ...[
                Text(
                  brand,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 3),
              ],
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.3,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '£${price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF5A2D82),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategorySuggestionTile extends ConsumerWidget {
  const _CategorySuggestionTile({required this.category});

  final CategoryModel category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          FocusScope.of(context).unfocus();
          ref.read(searchProvider.notifier).collapseForHome();

          await Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => SubcategoryScreen(
                parentName: category.name,
                parentSlug: category.slug,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8E1EE)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F1FC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.grid_view_rounded,
                  color: Color(0xFF5A2D82),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.black38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestionSkeleton extends StatefulWidget {
  const _SuggestionSkeleton();

  @override
  State<_SuggestionSkeleton> createState() => _SuggestionSkeletonState();
}

class _SuggestionSkeletonState extends State<_SuggestionSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
      lowerBound: 0.72,
      upperBound: 1.0,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _bar(double width, double height) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFEFE9F5),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 116,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E1EE)),
      ),
      child: Row(
        children: [
          FadeTransition(
            opacity: _controller,
            child: Container(
              width: 90,
              height: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF1ECF6),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(70, 10),
                const SizedBox(height: 10),
                _bar(double.infinity, 14),
                const SizedBox(height: 8),
                _bar(120, 12),
                const Spacer(),
                _bar(92, 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
