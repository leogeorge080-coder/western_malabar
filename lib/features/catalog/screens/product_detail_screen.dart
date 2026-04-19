import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:western_malabar/shared/navigation/product_navigation.dart';
import 'package:western_malabar/shared/utils/haptic.dart';
import 'package:western_malabar/features/catalog/models/product_model.dart';
import 'package:western_malabar/features/catalog/providers/related_products_provider.dart';
import 'package:western_malabar/features/catalog/services/product_service.dart';
import 'package:western_malabar/features/cart/providers/cart_provider.dart';

const _bg = Color(0xFFF7F7F7);
const _surface = Colors.white;
const _border = Color(0xFFE5E7EB);

const _textStrong = Color(0xFF111827);
const _textSoft = Color(0xFF6B7280);

const _primary = Color(0xFF2A2F3A);

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  final ProductModel? initialProduct;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.initialProduct,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  final ProductService _productService = ProductService();

  ProductModel? _product;
  bool _loading = true;
  bool _loadingMore = false;
  int qty = 1;

  @override
  void initState() {
    super.initState();
    _product = widget.initialProduct;
    _loading = _product == null;
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    if (_product != null) {
      setState(() => _loading = false);

      // Optional silent refresh if you want fresher data.
      _refreshInBackground();
      return;
    }

    final full = await _productService.fetchProductModelById(widget.productId);

    if (!mounted) return;

    setState(() {
      _product = full;
      _loading = false;
    });
  }

  Future<void> _refreshInBackground() async {
    final full = await _productService.fetchProductModelById(widget.productId);

    if (!mounted || full == null) return;

    setState(() {
      _product = full;
    });
  }

  Future<void> _openRelatedProduct(ProductModel p) async {
    if (_loadingMore) return;

    setState(() => _loadingMore = true);

    try {
      await openProductDetail(
        context,
        productId: p.id,
        initialProduct: p,
      );
    } finally {
      if (mounted) {
        setState(() => _loadingMore = false);
      }
    }
  }

  Future<void> _addToCart(ProductModel product) async {
    Haptic.heavy(context);

    final cart = ref.read(cartProvider.notifier);

    for (int i = 0; i < qty; i++) {
      cart.add(product);
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Center(
            child: CircularProgressIndicator(
              color: _primary,
            ),
          ),
        ),
      );
    }

    final product = _product;

    if (product == null) {
      return Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _surface,
          elevation: 0,
          foregroundColor: _textStrong,
        ),
        body: const Center(
          child: Text(
            'Unable to load product',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _textStrong,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                backgroundColor: _surface,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    color: _surface,
                    child: Hero(
                      tag: 'product-${product.id}',
                      child: product.hasImage
                          ? Image.network(
                              product.image!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.image, size: 80),
                            )
                          : const Icon(Icons.image, size: 80),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: _textStrong,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (product.effectiveBrandName.isNotEmpty)
                        Text(
                          product.effectiveBrandName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _textSoft,
                          ),
                        ),
                      if (product.categoryName != null)
                        Text(
                          product.categoryName!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _textSoft,
                          ),
                        ),
                      const SizedBox(height: 10),
                      if (product.hasRatings)
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${product.avgRating} (${product.ratingCount})',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 12),
                      Builder(
                        builder: (context) {
                          final price =
                              (product.displayPriceCents / 100).toStringAsFixed(
                            2,
                          );
                          final original = product.originalPriceCents != null
                              ? (product.originalPriceCents! / 100)
                                  .toStringAsFixed(2)
                              : null;

                          return Row(
                            children: [
                              Text(
                                '£$price',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: _primary,
                                ),
                              ),
                              if (original != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '£$original',
                                  style: const TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: _textSoft,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              if (product.discountPercent != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '-${product.discountPercent}%',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          if (product.isFrozen) _badge('❄️ Frozen'),
                          if (product.isWeeklyDeal)
                            _badge(product.dealBadgeText ?? 'Deal'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: _textStrong,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product.barcode != null
                            ? 'Barcode: ${product.barcode}'
                            : 'No barcode information',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _textSoft,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _border),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.local_shipping_outlined),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Same day / next day delivery available',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'You may also like',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: _textStrong,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Consumer(
                        builder: (context, ref, _) {
                          final async =
                              ref.watch(relatedProductsProvider(product));

                          return async.when(
                            loading: () => const SizedBox(
                              height: 140,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: _primary,
                                ),
                              ),
                            ),
                            error: (_, __) => const SizedBox(),
                            data: (items) {
                              if (items.isEmpty) return const SizedBox();

                              return SizedBox(
                                height: 180,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: items.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 10),
                                  itemBuilder: (context, i) {
                                    final p = items[i];

                                    return GestureDetector(
                                      onTap: () => _openRelatedProduct(p),
                                      child: Container(
                                        width: 130,
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: _surface,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(color: _border),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: p.hasImage
                                                  ? Image.network(
                                                      p.image!,
                                                      fit: BoxFit.contain,
                                                      errorBuilder:
                                                          (_, __, ___) =>
                                                              const Icon(
                                                        Icons.image,
                                                        size: 40,
                                                      ),
                                                    )
                                                  : const Icon(
                                                      Icons.image,
                                                      size: 40,
                                                    ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              p.name,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '£${(p.displayPriceCents / 100).toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: const BoxDecoration(
                color: _surface,
                border: Border(top: BorderSide(color: _border)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.isLowStock)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        '⚠️ Only ${product.stockQty} left',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _border),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed:
                                  qty > 1 ? () => setState(() => qty--) : null,
                            ),
                            Text(
                              '$qty',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => setState(() => qty++),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: product.inStock
                              ? () => _addToCart(product)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            product.inStock ? 'Add to Cart' : 'Out of Stock',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_loadingMore)
            const Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: Color(0x22000000),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: _primary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
