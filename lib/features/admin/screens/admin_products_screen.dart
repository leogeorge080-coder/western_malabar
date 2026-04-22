import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:western_malabar/features/admin/models/admin_product_edit_model.dart';
import 'package:western_malabar/features/admin/providers/admin_products_provider.dart';
import 'package:western_malabar/features/admin/screens/barcode_scan_screen.dart';
import 'package:western_malabar/features/admin/screens/edit_product_screen.dart'
    show EditProductScreen;
import 'package:western_malabar/shared/theme/theme.dart';
import 'package:western_malabar/shared/theme/wm_gradients.dart';
import 'package:western_malabar/shared/widgets/wm_product_image.dart';

enum AdminProductFilter {
  overview,
  lowStock,
  outOfStock,
  hidden,
  incomplete,
  missingImage,
  missingBarcode,
  all,
}

class AdminProductsScreen extends ConsumerStatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  ConsumerState<AdminProductsScreen> createState() =>
      _AdminProductsScreenState();
}

class _AdminProductsScreenState extends ConsumerState<AdminProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  AdminProductFilter _filter = AdminProductFilter.overview;
  String? _lastScannedBarcode;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AdminProductEditModel> _applyFilter(
    List<AdminProductEditModel> products,
  ) {
    final query = _searchController.text.trim().toLowerCase();
    final queryTerms = query
        .split(RegExp(r'\s+'))
        .map((term) => term.trim())
        .where((term) => term.isNotEmpty)
        .toList();

    final filtered = products.where((product) {
      final matchesSearch =
          queryTerms.isEmpty || _matchesSearch(product, query, queryTerms);

      if (!matchesSearch) return false;

      switch (_filter) {
        case AdminProductFilter.overview:
          return true;
        case AdminProductFilter.lowStock:
          return _isLowStock(product);
        case AdminProductFilter.outOfStock:
          return _isOutOfStock(product);
        case AdminProductFilter.hidden:
          return !_isCustomerVisible(product);
        case AdminProductFilter.incomplete:
          return !product.hasImage || !product.hasBarcode;
        case AdminProductFilter.missingImage:
          return !product.hasImage;
        case AdminProductFilter.missingBarcode:
          return !product.hasBarcode;
        case AdminProductFilter.all:
          return true;
      }
    }).toList();

    filtered.sort((a, b) {
      final aSearchRank = _searchRank(a, query, queryTerms);
      final bSearchRank = _searchRank(b, query, queryTerms);
      if (aSearchRank != bSearchRank) {
        return aSearchRank.compareTo(bSearchRank);
      }

      final aRank = _sortRank(a);
      final bRank = _sortRank(b);
      if (aRank != bRank) return aRank.compareTo(bRank);

      final aStock = _effectiveInventoryQty(a);
      final bStock = _effectiveInventoryQty(b);
      if (aStock != bStock) return aStock.compareTo(bStock);

      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return filtered;
  }

  bool _matchesSearch(
    AdminProductEditModel product,
    String query,
    List<String> queryTerms,
  ) {
    final searchable = <String>[
      product.name,
      product.slug,
      product.barcode ?? '',
      if (_isOutOfStock(product)) 'out of stock zero stock unavailable',
      if (_isLowStock(product)) 'low stock only few left running low',
      if (!_isCustomerVisible(product)) 'hidden not visible customer hidden',
      if (!product.hasImage) 'missing image no image',
      if (!product.hasBarcode) 'missing barcode no barcode',
      if (product.isFrozen) 'frozen freezer chilled',
      if (product.isWeeklyDeal) 'deal weekly deal offer promo',
      if (product.isAvailable) 'visible available live',
    ].join(' ').toLowerCase();

    return queryTerms.every(searchable.contains);
  }

  int _searchRank(
    AdminProductEditModel product,
    String query,
    List<String> queryTerms,
  ) {
    if (queryTerms.isEmpty) return 99;

    final name = product.name.toLowerCase();
    final slug = product.slug.toLowerCase();
    final barcode = (product.barcode ?? '').toLowerCase();

    if (barcode.isNotEmpty && barcode == query) return 0;
    if (name == query) return 1;
    if (slug == query) return 2;
    if (barcode.startsWith(query)) return 3;
    if (name.startsWith(query)) return 4;
    if (slug.startsWith(query)) return 5;
    if (barcode.contains(query)) return 6;
    if (name.contains(query)) return 7;
    if (slug.contains(query)) return 8;

    return 9 + queryTerms.length;
  }

  int _sortRank(AdminProductEditModel product) {
    if (_isOutOfStock(product)) return 0;
    if (_isLowStock(product)) return 1;
    if (!product.hasImage || !product.hasBarcode) return 2;
    if (!_isCustomerVisible(product)) return 3;
    return 4;
  }

  bool _isCustomerVisible(AdminProductEditModel product) {
    return product.isActive && product.isAvailable;
  }

  int _effectiveInventoryQty(AdminProductEditModel product) {
    final values = <int>[];
    final stockQty = product.stockQty;
    final availableQty = product.availableQty;
    if (stockQty != null && stockQty >= 0) values.add(stockQty);
    if (availableQty != null && availableQty >= 0) values.add(availableQty);
    if (values.isEmpty) return 1 << 30;
    return values.reduce((a, b) => a < b ? a : b);
  }

  bool _isOutOfStock(AdminProductEditModel product) {
    final inventoryQty = _effectiveInventoryQty(product);
    if (inventoryQty == 1 << 30) return false;
    return inventoryQty <= 0;
  }

  bool _isLowStock(AdminProductEditModel product) {
    final inventoryQty = _effectiveInventoryQty(product);
    if (inventoryQty == 1 << 30) return false;
    return inventoryQty > 0 && inventoryQty <= 3;
  }

  Future<void> _scanAndOpenProduct(
    List<AdminProductEditModel> products,
  ) async {
    final scanned = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => const BarcodeScanScreen(),
      ),
    );

    if (!mounted || scanned == null || scanned.trim().isEmpty) return;

    final cleanBarcode = scanned.trim();
    _searchController.text = cleanBarcode;
    setState(() {
      _lastScannedBarcode = cleanBarcode;
    });

    final match = products.cast<AdminProductEditModel?>().firstWhere(
          (product) => (product?.barcode ?? '').trim() == cleanBarcode,
          orElse: () => null,
        );

    if (match == null) {
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(
          content: Text(
            'No product found for barcode $cleanBarcode. Search has been updated.',
          ),
        ),
      );
      return;
    }

    await Navigator.of(this.context).push(
      MaterialPageRoute<void>(
        builder: (_) => EditProductScreen(productId: match.id),
      ),
    );
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
                        'Admin Inventory',
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
              Expanded(
                child: productsAsync.when(
                  data: (products) {
                    final metrics = _InventoryMetrics.from(products, this);
                    final filtered = _applyFilter(products);

                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(adminProductsProvider);
                        await ref.read(adminProductsProvider.future);
                      },
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        children: [
                          _InventoryHeroCard(
                            metrics: metrics,
                            activeFilter: _filter,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x12000000),
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: (_) => setState(() {}),
                                    decoration: InputDecoration(
                                      hintText:
                                          'Search by name, slug, barcode, or inventory issue',
                                      prefixIcon:
                                          const Icon(Icons.search_rounded),
                                      suffixIcon: _searchController.text.isEmpty
                                          ? null
                                          : IconButton(
                                              onPressed: () {
                                                _searchController.clear();
                                                setState(() {
                                                  _lastScannedBarcode = null;
                                                });
                                              },
                                              icon: const Icon(
                                                Icons.close_rounded,
                                              ),
                                            ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(18),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                height: 56,
                                child: FilledButton.tonalIcon(
                                  onPressed: () => _scanAndOpenProduct(products),
                                  icon: const Icon(
                                    Icons.qr_code_scanner_rounded,
                                  ),
                                  label: const Text('Scan'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFF2ECFF),
                                    foregroundColor: WMTheme.royalPurple,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_lastScannedBarcode != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F1FB),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.qr_code_2_rounded,
                                    size: 18,
                                    color: WMTheme.royalPurple,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Scanned barcode: $_lastScannedBarcode',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: WMTheme.royalPurple,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _lastScannedBarcode = null;
                                      });
                                    },
                                    child: const Text('Clear'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _FilterChip(
                                  label: 'Overview',
                                  selected:
                                      _filter == AdminProductFilter.overview,
                                  onTap: () => setState(
                                    () => _filter = AdminProductFilter.overview,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: 'Low Stock',
                                  count: metrics.lowStock,
                                  selected:
                                      _filter == AdminProductFilter.lowStock,
                                  onTap: () => setState(
                                    () => _filter = AdminProductFilter.lowStock,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: 'Out of Stock',
                                  count: metrics.outOfStock,
                                  selected:
                                      _filter == AdminProductFilter.outOfStock,
                                  onTap: () => setState(
                                    () =>
                                        _filter = AdminProductFilter.outOfStock,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: 'Hidden',
                                  count: metrics.hidden,
                                  selected: _filter == AdminProductFilter.hidden,
                                  onTap: () => setState(
                                    () => _filter = AdminProductFilter.hidden,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: 'Incomplete',
                                  count: metrics.incomplete,
                                  selected:
                                      _filter == AdminProductFilter.incomplete,
                                  onTap: () => setState(
                                    () =>
                                        _filter = AdminProductFilter.incomplete,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: 'Missing Image',
                                  count: metrics.missingImage,
                                  selected: _filter ==
                                      AdminProductFilter.missingImage,
                                  onTap: () => setState(
                                    () => _filter =
                                        AdminProductFilter.missingImage,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: 'Missing Barcode',
                                  count: metrics.missingBarcode,
                                  selected: _filter ==
                                      AdminProductFilter.missingBarcode,
                                  onTap: () => setState(
                                    () => _filter =
                                        AdminProductFilter.missingBarcode,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: 'All',
                                  count: metrics.total,
                                  selected: _filter == AdminProductFilter.all,
                                  onTap: () => setState(
                                    () => _filter = AdminProductFilter.all,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _InventorySectionHeader(
                            title: _sectionTitle(filtered.length),
                            subtitle: _sectionSubtitle(filtered.length),
                          ),
                          const SizedBox(height: 12),
                          if (filtered.isEmpty)
                            const _InventoryEmptyState()
                          else
                            ...List.generate(filtered.length, (index) {
                              final product = filtered[index];
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: index == filtered.length - 1 ? 0 : 14,
                                ),
                                child: _ProductInventoryCard(
                                  product: product,
                                  isLowStock: _isLowStock(product),
                                  isOutOfStock: _isOutOfStock(product),
                                  isCustomerVisible:
                                      _isCustomerVisible(product),
                                ),
                              );
                            }),
                        ],
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
                        'Failed to load inventory\n$e',
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

  String _sectionTitle(int count) {
    switch (_filter) {
      case AdminProductFilter.lowStock:
        return 'Low stock attention';
      case AdminProductFilter.outOfStock:
        return 'Out of stock now';
      case AdminProductFilter.hidden:
        return 'Hidden from customers';
      case AdminProductFilter.incomplete:
        return 'Incomplete catalog items';
      case AdminProductFilter.missingImage:
        return 'Missing image items';
      case AdminProductFilter.missingBarcode:
        return 'Missing barcode items';
      case AdminProductFilter.all:
        return 'All inventory items';
      case AdminProductFilter.overview:
        return count == 0 ? 'Inventory results' : 'Priority inventory';
    }
  }

  String _sectionSubtitle(int count) {
    switch (_filter) {
      case AdminProductFilter.lowStock:
        return '$count item${count == 1 ? '' : 's'} running low';
      case AdminProductFilter.outOfStock:
        return '$count item${count == 1 ? '' : 's'} currently unavailable by quantity';
      case AdminProductFilter.hidden:
        return '$count item${count == 1 ? '' : 's'} not visible to customers';
      case AdminProductFilter.incomplete:
        return '$count item${count == 1 ? '' : 's'} missing catalog essentials';
      case AdminProductFilter.missingImage:
        return '$count item${count == 1 ? '' : 's'} need a product image';
      case AdminProductFilter.missingBarcode:
        return '$count item${count == 1 ? '' : 's'} need a barcode';
      case AdminProductFilter.all:
        return '$count item${count == 1 ? '' : 's'} in the current admin view';
      case AdminProductFilter.overview:
        return '$count item${count == 1 ? '' : 's'} sorted by stock risk and completeness';
    }
  }
}

class _InventoryMetrics {
  const _InventoryMetrics({
    required this.total,
    required this.live,
    required this.hidden,
    required this.lowStock,
    required this.outOfStock,
    required this.incomplete,
    required this.missingImage,
    required this.missingBarcode,
  });

  final int total;
  final int live;
  final int hidden;
  final int lowStock;
  final int outOfStock;
  final int incomplete;
  final int missingImage;
  final int missingBarcode;

  factory _InventoryMetrics.from(
    List<AdminProductEditModel> products,
    _AdminProductsScreenState state,
  ) {
    var live = 0;
    var hidden = 0;
    var lowStock = 0;
    var outOfStock = 0;
    var incomplete = 0;
    var missingImage = 0;
    var missingBarcode = 0;

    for (final product in products) {
      if (state._isCustomerVisible(product)) {
        live++;
      } else {
        hidden++;
      }

      if (state._isLowStock(product)) lowStock++;
      if (state._isOutOfStock(product)) outOfStock++;
      if (!product.hasImage || !product.hasBarcode) incomplete++;
      if (!product.hasImage) missingImage++;
      if (!product.hasBarcode) missingBarcode++;
    }

    return _InventoryMetrics(
      total: products.length,
      live: live,
      hidden: hidden,
      lowStock: lowStock,
      outOfStock: outOfStock,
      incomplete: incomplete,
      missingImage: missingImage,
      missingBarcode: missingBarcode,
    );
  }
}

class _InventoryHeroCard extends StatelessWidget {
  const _InventoryHeroCard({
    required this.metrics,
    required this.activeFilter,
  });

  final _InventoryMetrics metrics;
  final AdminProductFilter activeFilter;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E2340), Color(0xFF5A2D82)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Inventory Control',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Live visibility, stock truth, and catalog completeness in one place.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricTile(
                label: 'Total',
                value: '${metrics.total}',
                accent: Colors.white,
              ),
              _MetricTile(
                label: 'Live',
                value: '${metrics.live}',
                accent: const Color(0xFFB8F7C4),
              ),
              _MetricTile(
                label: 'Low Stock',
                value: '${metrics.lowStock}',
                accent: const Color(0xFFFFD08A),
              ),
              _MetricTile(
                label: 'Out',
                value: '${metrics.outOfStock}',
                accent: const Color(0xFFFFB1B1),
              ),
              _MetricTile(
                label: 'Hidden',
                value: '${metrics.hidden}',
                accent: const Color(0xFFD4C6EA),
              ),
              _MetricTile(
                label: 'Incomplete',
                value: '${metrics.incomplete}',
                accent: const Color(0xFFD9C2FF),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            activeFilter == AdminProductFilter.overview
                ? 'Overview mode prioritizes stock risk first, then catalog cleanup.'
                : 'Filtered mode narrows the list to the selected inventory issue.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 102,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InventorySectionHeader extends StatelessWidget {
  const _InventorySectionHeader({
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
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}

class _InventoryEmptyState extends StatelessWidget {
  const _InventoryEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: const Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 40,
            color: WMTheme.royalPurple,
          ),
          SizedBox(height: 12),
          Text(
            'No products match this inventory view',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Try another filter or broaden your search.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductInventoryCard extends ConsumerWidget {
  const _ProductInventoryCard({
    required this.product,
    required this.isLowStock,
    required this.isOutOfStock,
    required this.isCustomerVisible,
  });

  final AdminProductEditModel product;
  final bool isLowStock;
  final bool isOutOfStock;
  final bool isCustomerVisible;

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
    final stockQty = product.stockQty;
    final availableQty = product.availableQty;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => EditProductScreen(productId: product.id),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F0FB),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: WmProductImage(
                      imageUrl: imageUrl,
                      width: 88,
                      height: 88,
                      borderRadius: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16.5,
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
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.black38,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _MiniBadge(
                              label: product.isActive ? 'Catalog live' : 'Disabled',
                              background: product.isActive
                                  ? const Color(0xFFEAF8EE)
                                  : const Color(0xFFFFF1F1),
                              foreground: product.isActive
                                  ? const Color(0xFF1B8E3E)
                                  : const Color(0xFFC62828),
                            ),
                            _MiniBadge(
                              label: product.isAvailable
                                  ? 'Customer visible'
                                  : 'Customer hidden',
                              background: product.isAvailable
                                  ? const Color(0xFFF1EDFF)
                                  : const Color(0xFFF3F4F6),
                              foreground: product.isAvailable
                                  ? WMTheme.royalPurple
                                  : const Color(0xFF6B7280),
                            ),
                            if (product.isFrozen)
                              const _MiniBadge(
                                label: 'Frozen',
                                background: Color(0xFFEAF5FF),
                                foreground: Color(0xFF1565C0),
                              ),
                            if (product.isWeeklyDeal)
                              _MiniBadge(
                                label: product.dealPriceCents != null
                                    ? 'Deal ${_money(product.dealPriceCents)}'
                                    : 'Weekly Deal',
                                background: const Color(0xFFFFF4D9),
                                foreground: const Color(0xFF8A6700),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _InventoryValueCard(
                      label: 'Central Stock',
                      value: stockQty?.toString() ?? '—',
                      tone: isOutOfStock
                          ? _InventoryTone.danger
                          : isLowStock
                              ? _InventoryTone.warning
                              : _InventoryTone.neutral,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _InventoryValueCard(
                      label: 'Available Qty',
                      value: availableQty?.toString() ?? '—',
                      tone: isOutOfStock
                          ? _InventoryTone.danger
                          : isLowStock
                              ? _InventoryTone.warning
                              : _InventoryTone.neutral,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _InventoryValueCard(
                      label: 'Base Price',
                      value: _money(product.originalPriceCents),
                      tone: _InventoryTone.neutral,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (isOutOfStock)
                    const _MiniBadge(
                      label: 'Out of stock',
                      background: Color(0xFFFFF1F1),
                      foreground: Color(0xFFC62828),
                    ),
                  if (isLowStock)
                    const _MiniBadge(
                      label: 'Low stock attention',
                      background: Color(0xFFFFF8E7),
                      foreground: Color(0xFF8A6700),
                    ),
                  if (!product.hasImage)
                    const _MiniBadge(
                      label: 'Missing image',
                      background: Color(0xFFFFF4F4),
                      foreground: Colors.red,
                    ),
                  if (!product.hasBarcode)
                    const _MiniBadge(
                      label: 'Missing barcode',
                      background: Color(0xFFFFF8E7),
                      foreground: Color(0xFF8A6700),
                    ),
                  if (product.hasBarcode)
                    _MiniBadge(
                      label: product.barcode!,
                      background: const Color(0xFFF5F1FB),
                      foreground: WMTheme.royalPurple,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F7FC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCustomerVisible
                          ? Icons.storefront_rounded
                          : Icons.visibility_off_rounded,
                      size: 18,
                      color: isCustomerVisible
                          ? WMTheme.royalPurple
                          : const Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isCustomerVisible
                            ? 'Customers can currently buy this item if quantity is available.'
                            : 'This item is blocked from customer purchase until re-enabled.',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
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
                    label: const Text('Open Inventory'),
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
      ),
    );
  }
}

enum _InventoryTone { neutral, warning, danger }

class _InventoryValueCard extends StatelessWidget {
  const _InventoryValueCard({
    required this.label,
    required this.value,
    required this.tone,
  });

  final String label;
  final String value;
  final _InventoryTone tone;

  @override
  Widget build(BuildContext context) {
    late final Color background;
    late final Color foreground;

    switch (tone) {
      case _InventoryTone.neutral:
        background = const Color(0xFFF7F4FB);
        foreground = WMTheme.royalPurple;
        break;
      case _InventoryTone.warning:
        background = const Color(0xFFFFF8E7);
        foreground = const Color(0xFF8A6700);
        break;
      case _InventoryTone.danger:
        background = const Color(0xFFFFF1F1);
        foreground = const Color(0xFFC62828);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;

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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : WMTheme.royalPurple,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.14)
                        : const Color(0xFFF4F1FA),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: selected ? Colors.white : WMTheme.royalPurple,
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

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

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
