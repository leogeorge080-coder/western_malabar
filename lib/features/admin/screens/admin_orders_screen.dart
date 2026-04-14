import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:western_malabar/shared/theme/theme.dart';
import 'package:western_malabar/shared/theme/wm_gradients.dart';
import 'package:western_malabar/features/admin/models/admin_order_model.dart';
import 'package:western_malabar/features/admin/providers/admin_orders_provider.dart';
import 'package:western_malabar/features/admin/screens/admin_order_detail_screen.dart';

enum AdminOrdersViewMode {
  active,
  todayDelivered,
  allHistory,
}

final adminOrdersViewModeProvider = StateProvider<AdminOrdersViewMode>((ref) {
  return AdminOrdersViewMode.active;
});

List<AdminOrderModel> filterOrders(
  List<AdminOrderModel> orders,
  AdminOrdersViewMode mode,
) {
  final now = DateTime.now();

  bool isToday(DateTime? dt) {
    if (dt == null) return false;
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  final filtered = orders.where((order) {
    switch (mode) {
      case AdminOrdersViewMode.active:
        return !order.isDelivered;

      case AdminOrdersViewMode.todayDelivered:
        return order.isDelivered && isToday(order.deliveredAt);

      case AdminOrdersViewMode.allHistory:
        return order.isDelivered;
    }
  }).toList();

  filtered.sort((a, b) {
    switch (mode) {
      case AdminOrdersViewMode.active:
        final priorityCompare = a.statusPriority.compareTo(b.statusPriority);
        if (priorityCompare != 0) return priorityCompare;

        final aCreated = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bCreated = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bCreated.compareTo(aCreated);

      case AdminOrdersViewMode.todayDelivered:
      case AdminOrdersViewMode.allHistory:
        final aDelivered =
            a.deliveredAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDelivered =
            b.deliveredAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDelivered.compareTo(aDelivered);
    }
  });

  return filtered;
}

class AdminOrdersScreen extends ConsumerWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint(
      'CURRENT AUTH USER: ${Supabase.instance.client.auth.currentUser?.id}',
    );

    final ordersAsync = ref.watch(adminOrdersProvider);
    final mode = ref.watch(adminOrdersViewModeProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: WMGradients.pageBackground,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _Header(
                mode: mode,
                onModeChanged: (newMode) {
                  ref.read(adminOrdersViewModeProvider.notifier).state =
                      newMode;
                },
              ),
              Expanded(
                child: ordersAsync.when(
                  data: (orders) {
                    final filteredOrders = filterOrders(orders, mode);

                    if (filteredOrders.isEmpty) {
                      return Center(
                        child: Text(
                          switch (mode) {
                            AdminOrdersViewMode.active => 'No active orders',
                            AdminOrdersViewMode.todayDelivered =>
                              'No orders delivered today',
                            AdminOrdersViewMode.allHistory =>
                              'No delivery history yet',
                          },
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(adminOrdersProvider);
                        await ref.read(adminOrdersProvider.future);
                      },
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: filteredOrders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final order = filteredOrders[index];
                          return _OrderCard(order: order);
                        },
                      ),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: WMTheme.royalPurple,
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Failed to load orders\n$e',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
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

class _Header extends StatelessWidget {
  final AdminOrdersViewMode mode;
  final void Function(AdminOrdersViewMode) onModeChanged;

  const _Header({
    required this.mode,
    required this.onModeChanged,
  });

  String get _modeLabel {
    switch (mode) {
      case AdminOrdersViewMode.active:
        return 'Active Orders';
      case AdminOrdersViewMode.todayDelivered:
        return 'Today Delivered';
      case AdminOrdersViewMode.allHistory:
        return 'All History';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Admin Orders',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _modeLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<AdminOrdersViewMode>(
            icon: const Icon(Icons.menu_rounded),
            onSelected: (value) {
              onModeChanged(value);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: AdminOrdersViewMode.active,
                child: Text('Active Orders'),
              ),
              PopupMenuItem(
                value: AdminOrdersViewMode.todayDelivered,
                child: Text('Today Delivered'),
              ),
              PopupMenuItem(
                value: AdminOrdersViewMode.allHistory,
                child: Text('All History'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final AdminOrderModel order;

  const _OrderCard({
    required this.order,
  });

  static String _money(int? cents) =>
      '£${((cents ?? 0) / 100).toStringAsFixed(2)}';

  static String _formatDateTime(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final createdText = _formatDateTime(order.createdAt);
    final deliveredText = _formatDateTime(order.deliveredAt);
    final statusLabel = order.displayStatusLabel;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => AdminOrderDetailScreen(orderId: order.id),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 10,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.orderNumber ?? order.id,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: WMTheme.royalPurple,
                      ),
                    ),
                  ),
                  _StatusChip(
                    label: statusLabel,
                    color: statusFg(statusLabel),
                    backgroundColor: statusBg(statusLabel),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                order.customerName ?? 'Unknown customer',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (createdText.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Created: $createdText',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.black54,
                  ),
                ),
              ],
              if (order.isDelivered && deliveredText.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  'Delivered: $deliveredText',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.green,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MiniChip(
                    label: (order.paymentStatus ?? 'pending').toUpperCase(),
                    background: const Color(0xFFF5F1FB),
                    foreground: WMTheme.royalPurple,
                  ),
                  if (order.hasFrozenItems)
                    const _MiniChip(
                      label: 'FROZEN',
                      background: Color(0xFFEAF5FF),
                      foreground: Color(0xFF1565C0),
                    ),
                  if ((order.deliverySlot ?? '').isNotEmpty)
                    _MiniChip(
                      label: order.deliverySlot!,
                      background: const Color(0xFFFFF8E8),
                      foreground: const Color(0xFF8A6700),
                    ),
                  if (order.isOutForDelivery)
                    const _MiniChip(
                      label: 'DRIVER ACTIVE',
                      background: Color(0xFFEAF5FF),
                      foreground: Color(0xFF1565C0),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    _money(order.totalCents),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.black38,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color statusBg(String status) {
    switch (status) {
      case 'DELIVERED':
        return const Color(0xFFE8F5E9);
      case 'OUT FOR DELIVERY':
        return const Color(0xFFEAF5FF);
      case 'PACKED':
        return const Color(0xFFFFF8E1);
      case 'PICKED':
        return const Color(0xFFE8F5E9);
      case 'PICKING':
        return const Color(0xFFF3E5F5);
      default:
        return const Color(0xFFF1F1F1);
    }
  }

  static Color statusFg(String status) {
    switch (status) {
      case 'DELIVERED':
        return Colors.green;
      case 'OUT FOR DELIVERY':
        return const Color(0xFF1565C0);
      case 'PACKED':
        return const Color(0xFF9E7B00);
      case 'PICKED':
        return Colors.green;
      case 'PICKING':
        return WMTheme.royalPurple;
      default:
        return Colors.black54;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color backgroundColor;

  const _StatusChip({
    required this.label,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _MiniChip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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
