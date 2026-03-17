import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:western_malabar/features/catalog/models/product_model.dart';
import 'package:western_malabar/shared/theme/wm_gradients.dart';
import 'package:western_malabar/shared/widgets/product_card.dart';
import 'package:western_malabar/features/cart/widgets/sticky_cart_bar.dart';

class SharedProductListingScreen extends ConsumerWidget {
  const SharedProductListingScreen({
    super.key,
    required this.title,
    required this.items,
    this.isLoading = false,
    this.onRefresh,
    this.emptyTitle = 'No products found',
    this.emptySubtitle = 'Try another filter or search term.',
  });

  final String title;
  final List<ProductModel> items;
  final bool isLoading;
  final Future<void> Function()? onRefresh;
  final String emptyTitle;
  final String emptySubtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const purple = Color(0xFF5A2D82);

    final body = isLoading
        ? const Center(child: CircularProgressIndicator())
        : items.isEmpty
            ? _ListingEmptyState(
                title: emptyTitle,
                subtitle: emptySubtitle,
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final p = items[i];
                  return ProductCard(
                    p: p,
                    compact: true,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Open "${p.name}"')),
                      );
                    },
                    onAdd: () {},
                  );
                },
              );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: WMGradients.pageBackground,
            ),
            child: SafeArea(
              child: RefreshIndicator(
                onRefresh: onRefresh ?? () async {},
                color: purple,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.maybePop(context),
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: purple,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              title,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: purple,
                              ),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                    Expanded(child: body),
                  ],
                ),
              ),
            ),
          ),
          const StickyCartBar(bottom: 16),
        ],
      ),
    );
  }
}

class _ListingEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _ListingEmptyState({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
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
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 40,
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
      ),
    );
  }
}




