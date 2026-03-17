import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:western_malabar/core/feedback/scan_feedback.dart';
import 'package:western_malabar/features/admin/models/admin_order_model.dart';
import 'package:western_malabar/features/admin/screens/order_qr_scan_screen.dart';
import 'package:western_malabar/features/admin/services/admin_orders_service.dart';
import 'package:western_malabar/theme.dart';
import 'package:western_malabar/theme/wm_gradients.dart';

String buildFullAddress(AdminOrderModel order) {
  final parts = [
    order.addressLine1,
    order.addressLine2,
    order.city,
    order.postcode,
  ].where((e) => e != null && e.trim().isNotEmpty).toList();

  return parts.join(', ');
}

Future<void> openGoogleMaps(AdminOrderModel order) async {
  Uri uri;

  if (order.latitude != null && order.longitude != null) {
    uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${order.latitude},${order.longitude}',
    );
  } else {
    final address = buildFullAddress(order);
    final encoded = Uri.encodeComponent(address);
    uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$encoded',
    );
  }

  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

final deliveryOrdersProvider =
    FutureProvider<List<AdminOrderModel>>((ref) async {
  final service = ref.read(adminOrdersServiceProvider);
  final all = await service.fetchRecentOrders();

  final filtered = all.where((order) => order.isActiveDeliveryOrder).toList();

  filtered.sort((a, b) {
    final aPriority = a.canDeliver ? 0 : 1;
    final bPriority = b.canDeliver ? 0 : 1;

    if (aPriority != bPriority) {
      return aPriority.compareTo(bPriority);
    }

    final aCreated = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bCreated = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return aCreated.compareTo(bCreated);
  });

  return filtered;
});

class DeliveryOrdersScreen extends ConsumerWidget {
  const DeliveryOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncOrders = ref.watch(deliveryOrdersProvider);

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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Driver Mode',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => ref.invalidate(deliveryOrdersProvider),
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: WMTheme.royalPurple,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: asyncOrders.when(
                  data: (orders) {
                    if (orders.isEmpty) {
                      return const Center(
                        child: Text(
                          'No delivery orders right now',
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
                        ref.invalidate(deliveryOrdersProvider);
                      },
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          return _DeliveryOrderCard(order: order);
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemCount: orders.length,
                      ),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: WMTheme.royalPurple,
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Text(
                      'Failed to load delivery orders\n$e',
                      textAlign: TextAlign.center,
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

class _DeliveryOrderCard extends ConsumerStatefulWidget {
  final AdminOrderModel order;

  const _DeliveryOrderCard({
    required this.order,
  });

  @override
  ConsumerState<_DeliveryOrderCard> createState() => _DeliveryOrderCardState();
}

class _DeliveryOrderCardState extends ConsumerState<_DeliveryOrderCard> {
  bool _loading = false;
  Color? _flashColor;

  AdminOrderModel get order => widget.order;

  void _setFlash(Color color) {
    if (!mounted) return;
    setState(() => _flashColor = color);
    Future<void>.delayed(const Duration(milliseconds: 420), () {
      if (!mounted) return;
      setState(() => _flashColor = null);
    });
  }

  String _fullAddress() {
    final parts = [
      order.addressLine1,
      order.addressLine2,
      order.city,
      order.postcode,
    ].where((e) => (e ?? '').trim().isNotEmpty).cast<String>().toList();

    return parts.join(', ');
  }

  Future<void> _openMaps() async {
    await openGoogleMaps(order);
  }

  Future<void> _scanAndUpdate() async {
    if (_loading || order.isDelivered) return;

    setState(() => _loading = true);

    try {
      final scannedValue = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => const OrderQrScanScreen(),
        ),
      );

      if (scannedValue == null || scannedValue.trim().isEmpty) {
        return;
      }

      final expectedQr = 'WM|ORDER|${order.id}|${order.orderNumber}';

      if (scannedValue.trim() != expectedQr) {
        _setFlash(Colors.red);
        await ScanFeedback.error();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scanned QR does not match this order'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (order.canDispatch) {
        await ref.read(adminOrdersServiceProvider).markOrderOutForDelivery(
              orderId: order.id,
            );

        _setFlash(Colors.green);
        await ScanFeedback.success();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order marked as out for delivery'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (order.canDeliver) {
        await ref.read(adminOrdersServiceProvider).markOrderDelivered(
              orderId: order.id,
            );

        _setFlash(Colors.green);
        await ScanFeedback.success();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order marked as delivered'),
            backgroundColor: Colors.green,
          ),
        );
      }

      ref.invalidate(deliveryOrdersProvider);
    } catch (e) {
      _setFlash(Colors.red);
      await ScanFeedback.error();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delivery scan failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderNo = order.orderNumber ?? order.id;
    final customerName = order.customerName ?? 'Unknown customer';
    final phone = order.phone ?? '';
    final slot = order.deliverySlot ?? 'No slot';
    final address = _fullAddress();
    final hasLocation = order.latitude != null && order.longitude != null;

    final statusLabel = order.displayStatusLabel;

    final nextAction = order.isDelivered
        ? 'Delivered'
        : order.isOutForDelivery
            ? 'Scan QR to Deliver'
            : 'Scan QR to Dispatch';

    return Stack(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: _flashColor == null
              ? null
              : BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: _flashColor!.withOpacity(0.12),
                ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
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
                    Expanded(
                      child: Text(
                        orderNo,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: WMTheme.royalPurple,
                        ),
                      ),
                    ),
                    _StatusChip(label: statusLabel),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  customerName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (phone.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    phone,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black54,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.schedule_rounded,
                  text: slot,
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.location_on_rounded,
                  text: address.isEmpty ? 'No address available' : address,
                ),
                if (hasLocation) ...[
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.my_location_rounded,
                    text:
                        'Pinned location: ${order.latitude}, ${order.longitude}',
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _openMaps,
                        icon: const Icon(Icons.navigation_rounded),
                        label: Text(hasLocation ? 'Navigate' : 'Open Map'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: (_loading ||
                                (!order.canDispatch && !order.canDeliver))
                            ? null
                            : _scanAndUpdate,
                        icon: _loading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                order.isDelivered
                                    ? Icons.check_circle_rounded
                                    : Icons.qr_code_scanner_rounded,
                              ),
                        label: Text(
                          nextAction,
                          textAlign: TextAlign.center,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: order.isDelivered
                              ? Colors.green
                              : WMTheme.royalPurple,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
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
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;

  const _StatusChip({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (label) {
      case 'DELIVERED':
        bg = const Color(0xFFE8F5E9);
        fg = Colors.green;
        break;
      case 'OUT FOR DELIVERY':
        bg = const Color(0xFFEAF5FF);
        fg = const Color(0xFF1565C0);
        break;
      default:
        bg = const Color(0xFFF6F0FB);
        fg = WMTheme.royalPurple;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: fg,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: WMTheme.royalPurple,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
