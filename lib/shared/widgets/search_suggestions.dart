import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:western_malabar/features/catalog/models/category_model.dart';
import 'package:western_malabar/features/search/screens/global_product_search_screen.dart';
import 'package:western_malabar/features/catalog/screens/subcategory_screen.dart';
import 'package:western_malabar/features/catalog/services/product_service.dart';
import 'package:western_malabar/features/search/providers/search_controller.dart';

class SearchSuggestions extends ConsumerWidget {
  final double top;
  final double left;
  final double right;

  const SearchSuggestions({
    super.key,
    this.top = 110,
    this.left = 16,
    this.right = 16,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchProvider);

    if (state.isEmpty) {
      return const SizedBox.shrink();
    }

    final products = state.products.take(5).toList();
    final categories = state.categories.take(3).toList();

    return Positioned(
      left: left,
      right: right,
      top: top,
      child: Material(
        elevation: 12,
        borderRadius: BorderRadius.circular(20),
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(
            maxHeight: 380,
            minHeight: 72,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SearchAllTile(
                query: state.query,
                onTap: () {
                  ref.read(searchProvider.notifier).clear();
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => GlobalProductSearchScreen(
                        initialQuery: state.query,
                      ),
                    ),
                  );
                },
              ),
              if (categories.isNotEmpty) ...[
                const Divider(height: 1),
                _SectionHeader(title: 'Categories'),
                ...categories.map(
                  (c) => _CategorySuggestionTile(
                    category: c,
                    onTap: () {
                      ref.read(searchProvider.notifier).clear();
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => SubcategoryScreen(
                            parentName: c.name,
                            parentSlug: c.slug,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              if (products.isNotEmpty) ...[
                const Divider(height: 1),
                _SectionHeader(title: 'Products'),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: products.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: Colors.grey.shade200,
                    ),
                    itemBuilder: (context, i) => _ProductSuggestionTile(
                      product: products[i],
                      onTap: () {
                        ref.read(searchProvider.notifier).clear();
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => GlobalProductSearchScreen(
                              initialQuery: products[i].name,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.black54,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _SearchAllTile extends StatelessWidget {
  const _SearchAllTile({
    required this.query,
    required this.onTap,
  });

  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF5A2D82);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4EDFB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.search_rounded, color: purple),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                    ),
                    children: [
                      const TextSpan(
                        text: 'Search all products for ',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(
                        text: '"$query"',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: purple,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.black38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategorySuggestionTile extends StatelessWidget {
  const _CategorySuggestionTile({
    required this.category,
    required this.onTap,
  });

  final CategoryModel category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF5A2D82);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                  color: purple,
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
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductSuggestionTile extends StatelessWidget {
  const _ProductSuggestionTile({
    required this.product,
    required this.onTap,
  });

  final WmProductDto product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final price = product.displayPriceCents / 100.0;
    final brand = (product.brandName ?? '').trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              _SuggestionImage(imageUrl: product.firstImageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (brand.isNotEmpty) ...[
                      Text(
                        brand,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 3),
                    ],
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestionImage extends StatelessWidget {
  const _SuggestionImage({
    required this.imageUrl,
  });

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    if (hasImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl!,
          width: 54,
          height: 54,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(),
        ),
      );
    }

    return _fallback();
  }

  Widget _fallback() {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F0F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.shopping_bag_outlined,
        color: Colors.black26,
      ),
    );
  }
}




