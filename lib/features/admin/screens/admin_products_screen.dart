import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:western_malabar/features/admin/models/admin_product_edit_model.dart';
import 'package:western_malabar/features/admin/providers/admin_products_provider.dart';
import 'package:western_malabar/features/admin/screens/edit_product_screen.dart'
    show EditProductScreen;
import 'package:western_malabar/shared/theme/theme.dart';
import 'package:western_malabar/shared/theme/wm_gradients.dart';
import 'package:western_malabar/shared/widgets/wm_product_image.dart';

enum AdminProductFilter {
  all,
  missingImage,
  missingBarcode,
  incomplete,
}

class AdminProductsScreen extends ConsumerStatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  ConsumerState<AdminProductsScreen> createState() =>
      _AdminProductsScreenState();
}

class _AdminProductsScreenState extends ConsumerState<AdminProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  AdminProductFilter _filter = AdminProductFilter.incomplete;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AdminProductEditModel> _applyFilter(
    List<AdminProductEditModel> products,
  ) {
    final query = _searchController.text.trim().toLowerCase();

    final filtered = products.where((product) {
      final matchesSearch = query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.slug.toLowerCase().contains(query) ||
          (product.barcode ?? '').toLowerCase().contains(query);

      if (!matchesSearch) return false;

      switch (_filter) {
        case AdminProductFilter.all:
          return true;
        case AdminProductFilter.missingImage:
          return !product.hasImage;
        case AdminProductFilter.missingBarcode:
          return !product.hasBarcode;
        case AdminProductFilter.incomplete:
          return !product.hasImage || !product.hasBarcode;
      }
    }).toList();

    filtered.sort((a, b) {
      final completenessCompare =
          a.completenessScore.compareTo(b.completenessScore);
      if (completenessCompare != 0) return completenessCompare;

      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(adminProductsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: WMGradients.pageBackground,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    const Expanded(
                      child: Text(
                        'Admin Products',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => ref.invalidate(adminProductsProvider),
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search products, slug or barcode',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'Incomplete',
                        selected: _filter == AdminProductFilter.incomplete,
                        onTap: () {
                          setState(() {
                            _filter = AdminProductFilter.incomplete;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Missing Image',
                        selected: _filter == AdminProductFilter.missingImage,
                        onTap: () {
                          setState(() {
                            _filter = AdminProductFilter.missingImage;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Missing Barcode',
                        selected: _filter == AdminProductFilter.missingBarcode,
                        onTap: () {
                          setState(() {
                            _filter = AdminProductFilter.missingBarcode;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'All',
                        selected: _filter == AdminProductFilter.all,
                        onTap: () {
                          setState(() {
                            _filter = AdminProductFilter.all;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: productsAsync.when(
                  data: (products) {
                    final filtered = _applyFilter(products);

                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text(
                          'No products found',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.black54,
                          ),
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(adminProductsProvider);
                        await ref.read(adminProductsProvider.future);
                      },
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final product = filtered[index];
                          return _ProductCard(product: product);
                        },
                      ),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Failed to load products\n$e',
                        textAlign: TextAlign.center,
                      ),
                    ),
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

class _ProductCard extends ConsumerWidget {
  final AdminProductEditModel product;

  const _ProductCard({
    required this.product,
  });

  String _money(int? cents) {
    if (cents == null || cents <= 0) return '—';
    return '£${(cents / 100).toStringAsFixed(2)}';
  }

  Future<void> _toggleActive(BuildContext context, WidgetRef ref) async {
    final shouldEnable = !product.isActive;

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              shouldEnable ? 'Enable product?' : 'Disable product?',
            ),
            content: Text(
              shouldEnable
                  ? 'This product will become visible to customers again.'
                  : 'This product will be hidden from customer app, search, and categories.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(shouldEnable ? 'Enable' : 'Disable'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      final service = ref.read(adminProductsServiceProvider);
      await service.setProductActiveStatus(
        productId: product.id,
        isActive: shouldEnable,
      );

      ref.invalidate(adminProductsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              shouldEnable
                  ? '${product.name} enabled'
                  : '${product.name} disabled',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update product status: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageUrl = product.images.isNotEmpty ? product.images.first : null;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => EditProductScreen(productId: product.id),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 10,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F0FB),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: WmProductImage(
                  imageUrl: imageUrl,
                  width: 76,
                  height: 76,
                  borderRadius: 18,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      product.slug,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MiniBadge(
                          label: product.isActive ? 'Active' : 'Disabled',
                          background: product.isActive
                              ? const Color(0xFFEAF8EE)
                              : const Color(0xFFFFF1F1),
                          foreground: product.isActive
                              ? const Color(0xFF1B8E3E)
                              : const Color(0xFFC62828),
                        ),
                        if (product.originalPriceCents != null)
                          _MiniBadge(
                            label: 'Base ${_money(product.originalPriceCents)}',
                            background: const Color(0xFFF5F1FB),
                            foreground: WMTheme.royalPurple,
                          ),
                        if (product.salePriceCents != null &&
                            product.salePriceCents! > 0)
                          _MiniBadge(
                            label: 'Sale ${_money(product.salePriceCents)}',
                            background: const Color(0xFFEAF8EE),
                            foreground: const Color(0xFF1B8E3E),
                          ),
                        if (product.isWeeklyDeal)
                          _MiniBadge(
                            label: product.dealPriceCents != null
                                ? 'Deal ${_money(product.dealPriceCents)}'
                                : 'Weekly Deal',
                            background: const Color(0xFFFFF4D9),
                            foreground: const Color(0xFF8A6700),
                          ),
                        if (!product.hasImage)
                          const _MiniBadge(
                            label: 'Missing Image',
                            background: Color(0xFFFFF4F4),
                            foreground: Colors.red,
                          ),
                        if (!product.hasBarcode)
                          const _MiniBadge(
                            label: 'Missing Barcode',
                            background: Color(0xFFFFF8E7),
                            foreground: Color(0xFF8A6700),
                          ),
                        if (product.hasBarcode)
                          _MiniBadge(
                            label: product.barcode!,
                            background: const Color(0xFFF5F1FB),
                            foreground: WMTheme.royalPurple,
                          ),
                        if (product.isFrozen)
                          const _MiniBadge(
                            label: 'Frozen',
                            background: Color(0xFFEAF5FF),
                            foreground: Color(0xFF1565C0),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _toggleActive(context, ref),
                          icon: Icon(
                            product.isActive
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 18,
                          ),
                          label: Text(
                            product.isActive ? 'Disable' : 'Enable',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: product.isActive
                                ? Colors.redAccent
                                : const Color(0xFF1B8E3E),
                            side: BorderSide(
                              color: product.isActive
                                  ? const Color(0xFFFFD6D6)
                                  : const Color(0xFFCDEFD6),
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    EditProductScreen(productId: product.id),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          label: const Text('Edit'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: WMTheme.royalPurple,
                            side: const BorderSide(color: Color(0xFFE3DAEF)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.black38,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? WMTheme.royalPurple : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? WMTheme.royalPurple : const Color(0xFFE3DAEF),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : WMTheme.royalPurple,
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _MiniBadge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: foreground,
        ),
      ),
    );
  }
}
