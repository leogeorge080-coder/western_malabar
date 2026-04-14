import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:western_malabar/features/orders/models/order_history_model.dart';
import 'package:western_malabar/features/orders/providers/orders_provider.dart';
import 'package:western_malabar/features/orders/screens/order_detail_screen.dart';
import 'package:western_malabar/shared/theme/theme.dart';
import 'package:western_malabar/shared/theme/wm_gradients.dart';

class MyOrdersScreen extends ConsumerWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(myOrdersProvider);

    Future<void> refresh() async {
      ref.invalidate(myOrdersProvider);
      await ref.read(myOrdersProvider.future);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: WMGradients.pageBackground,
        ),
        child: SafeArea(
          child: Column(
            children: [
              const _OrdersHeader(),
              Expanded(
                child: ordersAsync.when(
                  loading: () => RefreshIndicator(
                    color: WMTheme.royalPurple,
                    onRefresh: refresh,
                    child: const _OrdersLoadingView(),
                  ),
                  error: (error, _) => RefreshIndicator(
                    color: WMTheme.royalPurple,
                    onRefresh: refresh,
                    child: _OrdersErrorView(
                      message: error.toString(),
                      onRetry: () => ref.invalidate(myOrdersProvider),
                    ),
                  ),
                  data: (orders) {
                    return RefreshIndicator(
                      color: WMTheme.royalPurple,
                      onRefresh: refresh,
                      child: orders.isEmpty
                          ? const _OrdersEmptyView()
                          : ListView(
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              children: [
                                _OrdersOverviewCard(orders: orders),
                                const SizedBox(height: 14),
                                ...List.generate(orders.length, (index) {
                                  final order = orders[index];
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom:
                                          index == orders.length - 1 ? 0 : 14,
                                    ),
                                    child: _OrderHistoryCard(
                                      order: order,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) => OrderDetailScreen(
                                              orderId: order.id,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                }),
                              ],
                            ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrdersHeader extends StatelessWidget {
  const _OrdersHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(
        children: [
          Material(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => Navigator.maybePop(context),
              child: Container(
                width: 48,
                height: 48,
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
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: WMTheme.royalPurple,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Orders',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Track current and previous purchases',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersOverviewCard extends StatelessWidget {
  final List<OrderHistoryModel> orders;

  const _OrdersOverviewCard({
    required this.orders,
  });

  @override
  Widget build(BuildContext context) {
    final totalOrders = orders.length;
    final deliveredCount = orders.where((o) {
      final status = o.normalizedDisplayStatus.trim().toLowerCase();
      return status == 'delivered' || status == 'collected';
    }).length;

    final activeCount = orders.where((o) {
      final status = o.normalizedDisplayStatus.trim().toLowerCase();
      return status == 'confirmed' ||
          status == 'preparing' ||
          status == 'packing' ||
          status == 'out for delivery' ||
          status == 'ready for pickup';
    }).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            WMTheme.royalPurple,
            Color(0xFF8753C4),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
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
                  Icons.receipt_long_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order History',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'All your purchases in one place',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _OverviewPill(
                  label: 'Total',
                  value: '$totalOrders',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OverviewPill(
                  label: 'Active',
                  value: '$activeCount',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OverviewPill(
                  label: 'Completed',
                  value: '$deliveredCount',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewPill extends StatelessWidget {
  final String label;
  final String value;

  const _OverviewPill({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderHistoryCard extends StatelessWidget {
  final OrderHistoryModel order;
  final VoidCallback onTap;

  const _OrderHistoryCard({
    required this.order,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.normalizedDisplayStatus);
    final statusBg = statusColor.withValues(alpha: 0.10);
    final orderNumber =
        order.orderNumber.trim().isEmpty ? 'Order' : order.orderNumber.trim();

    return Material(
      color: Colors.white.withValues(alpha: 0.97),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4EDFB),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      color: WMTheme.royalPurple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          orderNumber,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _dateText(order.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.20),
                      ),
                    ),
                    child: Text(
                      order.normalizedDisplayStatus,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetaPill(
                    icon: Icons.shopping_bag_outlined,
                    label: order.itemCountLabel,
                  ),
                  _MetaPill(
                    icon: order.deliveryType == 'local_pickup'
                        ? Icons.storefront_outlined
                        : Icons.local_shipping_outlined,
                    label: order.deliveryTypeLabel,
                  ),
                  _MetaPill(
                    icon: Icons.payments_outlined,
                    label: order.paymentMethodLabel,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBF9FE),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFECE5F6)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Order Total',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        Text(
                          order.totalFormatted,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: WMTheme.royalPurple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFECE5F6)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          _statusIcon(order.normalizedDisplayStatus),
                          size: 18,
                          color: statusColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _statusMessage(order),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onTap,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: WMTheme.royalPurple,
                        side: const BorderSide(color: WMTheme.royalPurple),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'View details',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
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

  static String _dateText(DateTime? dt) {
    if (dt == null) return 'Recently placed';

    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final month = months[dt.month - 1];
    final hour = dt.hour == 0
        ? 12
        : dt.hour > 12
            ? dt.hour - 12
            : dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final suffix = dt.hour >= 12 ? 'PM' : 'AM';

    return 'Placed on ${dt.day} $month ${dt.year} • $hour:$minute $suffix';
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'Delivered':
      case 'Collected':
        return const Color(0xFF1E8E3E);
      case 'Out for Delivery':
      case 'Ready for Pickup':
        return const Color(0xFF1565C0);
      case 'Packing':
      case 'Preparing':
      case 'Confirmed':
        return const Color(0xFF8A6700);
      case 'Cancelled':
        return Colors.redAccent;
      default:
        return WMTheme.royalPurple;
    }
  }

  static IconData _statusIcon(String status) {
    switch (status) {
      case 'Delivered':
      case 'Collected':
        return Icons.check_circle_rounded;
      case 'Out for Delivery':
        return Icons.local_shipping_rounded;
      case 'Ready for Pickup':
        return Icons.store_mall_directory_rounded;
      case 'Packing':
      case 'Preparing':
      case 'Confirmed':
        return Icons.inventory_2_rounded;
      case 'Cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  static String _statusMessage(OrderHistoryModel order) {
    switch (order.normalizedDisplayStatus) {
      case 'Delivered':
        return 'This order has been delivered successfully.';
      case 'Collected':
        return 'This order was collected successfully.';
      case 'Out for Delivery':
        return 'Your order is on the way.';
      case 'Ready for Pickup':
        return 'Your order is ready to collect.';
      case 'Packing':
        return 'Your items are being packed for dispatch.';
      case 'Preparing':
        return 'Your order is being prepared.';
      case 'Confirmed':
        return 'Your order has been confirmed and will move soon.';
      case 'Cancelled':
        return 'This order was cancelled.';
      default:
        return 'Tap to view full order details and updates.';
    }
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F0FB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: WMTheme.royalPurple,
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersLoadingView extends StatelessWidget {
  const _OrdersLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: const [
        _OrdersOverviewSkeleton(),
        SizedBox(height: 14),
        _OrderCardSkeleton(),
        SizedBox(height: 14),
        _OrderCardSkeleton(),
        SizedBox(height: 14),
        _OrderCardSkeleton(),
      ],
    );
  }
}

class _OrdersOverviewSkeleton extends StatelessWidget {
  const _OrdersOverviewSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 162,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(26),
      ),
    );
  }
}

class _OrderCardSkeleton extends StatelessWidget {
  const _OrderCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 228,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }
}

class _OrdersEmptyView extends StatelessWidget {
  const _OrdersEmptyView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(26),
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
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4EDFB),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  size: 44,
                  color: WMTheme.royalPurple,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'No orders yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your recent orders and delivery updates will appear here once you complete your first purchase.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.maybePop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WMTheme.royalPurple,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.storefront_outlined),
                  label: const Text(
                    'Start Shopping',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrdersErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _OrdersErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
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
              const Icon(
                Icons.error_outline_rounded,
                size: 42,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 12),
              const Text(
                'Unable to load orders',
                style: TextStyle(
                  fontSize: 18,
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
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WMTheme.royalPurple,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
