import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/seller_products_provider.dart';
import '../providers/seller_session_provider.dart';
import '../widgets/seller_product_card.dart';
import '../../seller_requests/screens/seller_new_product_request_screen.dart';
import '../../seller_requests/screens/seller_request_history_screen.dart';

enum SellerInventoryFilter {
  all,
  available,
  lowStock,
  outOfStock,
}

class SellerProductsScreen extends ConsumerStatefulWidget {
  const SellerProductsScreen({super.key});

  @override
  ConsumerState<SellerProductsScreen> createState() =>
      _SellerProductsScreenState();
}

class _SellerProductsScreenState extends ConsumerState<SellerProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  SellerInventoryFilter _activeFilter = SellerInventoryFilter.all;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openNewProductRequest() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SellerNewProductRequestScreen(),
      ),
    );

    ref.invalidate(sellerProductsProvider);
  }

  Future<void> _refreshProducts() async {
    ref.invalidate(sellerProductsProvider);
    await ref.read(sellerProductsProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final sellerSessionAsync = ref.watch(sellerSessionProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FB),
      body: sellerSessionAsync.when(
        loading: () => const _SellerLoadingView(),
        error: (error, _) => _ModernStateMessage(
          icon: Icons.storefront_outlined,
          title: 'Unable to open seller dashboard',
          message: '$error',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(sellerSessionProvider),
        ),
        data: (session) {
          if (!session.isLoggedIn) {
            return const _ModernStateMessage(
              icon: Icons.lock_outline_rounded,
              title: 'Sign in required',
              message: 'Please sign in to continue.',
            );
          }

          if (!session.isSeller) {
            return const _ModernStateMessage(
              icon: Icons.block_outlined,
              title: 'Seller access unavailable',
              message: 'This account does not have seller access.',
            );
          }

          if (!session.isActive) {
            return const _ModernStateMessage(
              icon: Icons.pause_circle_outline_rounded,
              title: 'Seller access disabled',
              message: 'Your seller access is currently inactive.',
            );
          }

          final productsAsync = ref.watch(sellerProductsProvider);

          return productsAsync.when(
            loading: () => const _SellerLoadingView(),
            error: (error, _) => _ModernStateMessage(
              icon: Icons.inventory_2_outlined,
              title: 'Unable to load products',
              message: '$error',
              actionLabel: 'Retry',
              onAction: _refreshProducts,
            ),
            data: (products) {
              final metrics = _SellerMetrics.fromProducts(products);

              final filteredProducts = products.where((product) {
                final matchesFilter = _matchesFilter(product, _activeFilter);
                final matchesSearch =
                    _matchesSearch(product, _searchController.text);
                return matchesFilter && matchesSearch;
              }).toList();

              return RefreshIndicator(
                onRefresh: _refreshProducts,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _DashboardTopBar(
                                onAddTap: _openNewProductRequest,
                              ),
                              const SizedBox(height: 14),
                              _SellerHeroCard(metrics: metrics),
                              const SizedBox(height: 14),
                              _QuickActionsRow(
                                onAddProductTap: _openNewProductRequest,
                                onScanTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Barcode-first add flow already started. Next step: wire direct scan entry here.',
                                      ),
                                    ),
                                  );
                                },
                                onUpdateStockTap: () {
                                  setState(() {
                                    _activeFilter =
                                        SellerInventoryFilter.lowStock;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Showing products needing stock attention.',
                                      ),
                                    ),
                                  );
                                },
                                onRequestsTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const SellerRequestHistoryScreen(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 14),
                              _SearchBar(
                                controller: _searchController,
                              ),
                              const SizedBox(height: 12),
                              _FilterChipsRow(
                                activeFilter: _activeFilter,
                                metrics: metrics,
                                onChanged: (filter) {
                                  setState(() {
                                    _activeFilter = filter;
                                  });
                                },
                              ),
                              const SizedBox(height: 14),
                              _SectionHeader(
                                title: 'Inventory',
                                subtitle:
                                    '${filteredProducts.length} item(s) visible',
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (products.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _ModernStateMessage(
                          icon: Icons.inventory_2_outlined,
                          title: 'No products assigned',
                          message:
                              'No products are currently linked to this seller account.',
                        ),
                      )
                    else if (filteredProducts.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _ModernStateMessage(
                          icon: Icons.search_off_rounded,
                          title: 'No matching products',
                          message:
                              'Try changing the search term or switching the filter.',
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        sliver: SliverList.separated(
                          itemCount: filteredProducts.length,
                          itemBuilder: (_, index) {
                            final product = filteredProducts[index];
                            return _InventoryCardShell(
                              availabilityLabel:
                                  _readBool(product, 'isAvailable')
                                      ? 'Available'
                                      : 'Hidden',
                              qtyLabel:
                                  'Qty ${_readInt(product, 'availableQty')}',
                              lowStock: _readInt(product, 'availableQty') > 0 &&
                                  _readInt(product, 'availableQty') <= 5,
                              child: SellerProductCard(product: product),
                            );
                          },
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  bool _matchesFilter(dynamic product, SellerInventoryFilter filter) {
    final isAvailable = _readBool(product, 'isAvailable');
    final qty = _readInt(product, 'availableQty');

    switch (filter) {
      case SellerInventoryFilter.all:
        return true;
      case SellerInventoryFilter.available:
        return isAvailable && qty > 0;
      case SellerInventoryFilter.lowStock:
        return isAvailable && qty > 0 && qty <= 5;
      case SellerInventoryFilter.outOfStock:
        return qty <= 0 || !isAvailable;
    }
  }

  bool _matchesSearch(dynamic product, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;

    final haystack = [
      _readString(product, 'name'),
      _readString(product, 'slug'),
      _readString(product, 'sellerNotes'),
      _readString(product, 'barcode'),
    ].join(' ').toLowerCase();

    return haystack.contains(q);
  }
}

class _DashboardTopBar extends StatelessWidget {
  const _DashboardTopBar({
    required this.onAddTap,
  });

  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundIconButton(
          icon: Icons.arrow_back_rounded,
          onTap: () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Seller Dashboard',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF5A2D82),
              letterSpacing: -0.4,
            ),
          ),
        ),
        _RoundIconButton(
          icon: Icons.add_box_outlined,
          onTap: onAddTap,
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: const Color(0xFF5A2D82),
          ),
        ),
      ),
    );
  }
}

class _SellerHeroCard extends StatelessWidget {
  const _SellerHeroCard({
    required this.metrics,
  });

  final _SellerMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF5A2D82),
            Color(0xFF8B57C8),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
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
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seller Operations',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Manage stock, visibility, and request-based catalog control',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricPill(
                icon: Icons.inventory_2_outlined,
                label: '${metrics.total} products',
              ),
              _MetricPill(
                icon: Icons.check_circle_outline_rounded,
                label: '${metrics.liveVisible} live',
              ),
              _MetricPill(
                icon: Icons.warning_amber_rounded,
                label: '${metrics.lowStock} low stock',
              ),
              _MetricPill(
                icon: Icons.remove_shopping_cart_outlined,
                label: '${metrics.hiddenOrOut} hidden/out',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({
    required this.onAddProductTap,
    required this.onScanTap,
    required this.onUpdateStockTap,
    required this.onRequestsTap,
  });

  final VoidCallback onAddProductTap;
  final VoidCallback onScanTap;
  final VoidCallback onUpdateStockTap;
  final VoidCallback onRequestsTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 118,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _QuickActionCard(
            icon: Icons.add_box_outlined,
            title: 'Add Product',
            subtitle: 'New request',
            onTap: onAddProductTap,
          ),
          const SizedBox(width: 12),
          _QuickActionCard(
            icon: Icons.qr_code_scanner_rounded,
            title: 'Scan',
            subtitle: 'Barcode flow',
            onTap: onScanTap,
          ),
          const SizedBox(width: 12),
          _QuickActionCard(
            icon: Icons.inventory_outlined,
            title: 'Stock',
            subtitle: 'Needs action',
            onTap: onUpdateStockTap,
          ),
          const SizedBox(width: 12),
          _QuickActionCard(
            icon: Icons.rule_folder_outlined,
            title: 'Requests',
            subtitle: 'Pending review',
            onTap: onRequestsTap,
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 148,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 12,
                offset: Offset(0, 6),
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
                  color: const Color(0xFFF4EDFB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: const Color(0xFF5A2D82)),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
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

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Search product, slug, notes, barcode',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Color(0xFFE9E1F3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Color(0xFFE9E1F3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Color(0xFF5A2D82),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class _FilterChipsRow extends StatelessWidget {
  const _FilterChipsRow({
    required this.activeFilter,
    required this.metrics,
    required this.onChanged,
  });

  final SellerInventoryFilter activeFilter;
  final _SellerMetrics metrics;
  final ValueChanged<SellerInventoryFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _FilterChipButton(
          selected: activeFilter == SellerInventoryFilter.all,
          label: 'All (${metrics.total})',
          onTap: () => onChanged(SellerInventoryFilter.all),
        ),
        _FilterChipButton(
          selected: activeFilter == SellerInventoryFilter.available,
          label: 'Available (${metrics.liveVisible})',
          onTap: () => onChanged(SellerInventoryFilter.available),
        ),
        _FilterChipButton(
          selected: activeFilter == SellerInventoryFilter.lowStock,
          label: 'Low stock (${metrics.lowStock})',
          onTap: () => onChanged(SellerInventoryFilter.lowStock),
        ),
        _FilterChipButton(
          selected: activeFilter == SellerInventoryFilter.outOfStock,
          label: 'Out (${metrics.hiddenOrOut})',
          onTap: () => onChanged(SellerInventoryFilter.outOfStock),
        ),
      ],
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? const Color(0xFF5A2D82) : Colors.white;
    final fg = selected ? Colors.white : Colors.black87;
    final border = selected ? const Color(0xFF5A2D82) : const Color(0xFFE7DFF1);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}

class _InventoryCardShell extends StatelessWidget {
  const _InventoryCardShell({
    required this.child,
    required this.availabilityLabel,
    required this.qtyLabel,
    required this.lowStock,
  });

  final Widget child;
  final String availabilityLabel;
  final String qtyLabel;
  final bool lowStock;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 14,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              children: [
                _MiniStatusChip(
                  label: availabilityLabel,
                  icon: Icons.check_circle_outline_rounded,
                  background: const Color(0xFFEFFAF2),
                  foreground: const Color(0xFF236B35),
                ),
                const SizedBox(width: 8),
                _MiniStatusChip(
                  label: qtyLabel,
                  icon: lowStock
                      ? Icons.warning_amber_rounded
                      : Icons.inventory_2_outlined,
                  background: lowStock
                      ? const Color(0xFFFFF4E5)
                      : const Color(0xFFF4EDFB),
                  foreground: lowStock
                      ? const Color(0xFF8A5200)
                      : const Color(0xFF5A2D82),
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _MiniStatusChip extends StatelessWidget {
  const _MiniStatusChip({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernStateMessage extends StatelessWidget {
  const _ModernStateMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 14,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4EDFB),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF5A2D82),
                    size: 30,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: onAction,
                    child: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SellerLoadingView extends StatelessWidget {
  const _SellerLoadingView();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.4,
          color: Color(0xFF5A2D82),
        ),
      ),
    );
  }
}

class _SellerMetrics {
  final int total;
  final int liveVisible;
  final int lowStock;
  final int hiddenOrOut;

  const _SellerMetrics({
    required this.total,
    required this.liveVisible,
    required this.lowStock,
    required this.hiddenOrOut,
  });

  factory _SellerMetrics.fromProducts(List<dynamic> products) {
    int liveVisible = 0;
    int lowStock = 0;
    int hiddenOrOut = 0;

    for (final product in products) {
      final isAvailable = _readBool(product, 'isAvailable');
      final qty = _readInt(product, 'availableQty');

      final isLive = isAvailable && qty > 0;
      final isLow = isAvailable && qty > 0 && qty <= 5;
      final isHiddenOrOut = !isAvailable || qty <= 0;

      if (isLive) liveVisible++;
      if (isLow) lowStock++;
      if (isHiddenOrOut) hiddenOrOut++;
    }

    return _SellerMetrics(
      total: products.length,
      liveVisible: liveVisible,
      lowStock: lowStock,
      hiddenOrOut: hiddenOrOut,
    );
  }
}

String _readString(dynamic object, String field) {
  try {
    final dynamic value = _readDynamic(object, field);
    if (value == null) return '';
    return value.toString();
  } catch (_) {
    return '';
  }
}

int _readInt(dynamic object, String field) {
  try {
    final dynamic value = _readDynamic(object, field);
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  } catch (_) {
    return 0;
  }
}

bool _readBool(dynamic object, String field) {
  try {
    final dynamic value = _readDynamic(object, field);
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  } catch (_) {
    return false;
  }
}

dynamic _readDynamic(dynamic object, String field) {
  switch (field) {
    case 'name':
      return object.name;
    case 'slug':
      return object.slug;
    case 'barcode':
      return object.barcode;
    case 'sellerNotes':
      return object.sellerNotes;
    case 'isAvailable':
      return object.isAvailable;
    case 'availableQty':
      return object.availableQty;
    default:
      return null;
  }
}
