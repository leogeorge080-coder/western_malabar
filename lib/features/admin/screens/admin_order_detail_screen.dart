import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:western_malabar/core/feedback/scan_feedback.dart';
import 'package:western_malabar/features/admin/models/admin_order_item_model.dart';
import 'package:western_malabar/features/admin/models/admin_order_model.dart';
import 'package:western_malabar/features/admin/providers/admin_order_detail_provider.dart';
import 'package:western_malabar/features/admin/providers/admin_orders_provider.dart';
import 'package:western_malabar/features/admin/screens/order_qr_scan_screen.dart';
import 'package:western_malabar/features/admin/services/admin_orders_service.dart';
import 'package:western_malabar/theme.dart';
import 'package:western_malabar/theme/wm_gradients.dart';

class AdminOrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;

  const AdminOrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<AdminOrderDetailScreen> createState() =>
      _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState
    extends ConsumerState<AdminOrderDetailScreen> {
  bool _bagQrVerified = false;
  Color? _flashColor;

  String get orderId => widget.orderId;

  void _setFlash(Color color) {
    if (!mounted) return;
    setState(() => _flashColor = color);
    Future<void>.delayed(const Duration(milliseconds: 420), () {
      if (!mounted) return;
      setState(() => _flashColor = null);
    });
  }

  void _resetQrVerification() {
    if (!mounted) return;
    setState(() {
      _bagQrVerified = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(adminOrderProvider(orderId));
    final itemsAsync = ref.watch(adminOrderItemsProvider(orderId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
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
                          onPressed: _bagQrVerified
                              ? null
                              : () => Navigator.maybePop(context),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        ),
                        const Expanded(
                          child: Text(
                            'Order Detail',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _bagQrVerified
                              ? null
                              : () => _showManualBarcodeDialog(context, ref),
                          icon: const Icon(Icons.qr_code_2_rounded),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: orderAsync.when(
                      data: (order) {
                        return itemsAsync.when(
                          data: (items) {
                            final nonFrozen =
                                items.where((e) => !e.isFrozen).toList();
                            final frozen =
                                items.where((e) => e.isFrozen).toList();

                            final totalQty =
                                items.fold<int>(0, (sum, e) => sum + e.qty);
                            final pickedQty = items.fold<int>(
                              0,
                              (sum, e) => sum + e.pickedQty,
                            );

                            final canPack = items.isNotEmpty &&
                                items.every((e) => e.pickedQty >= e.qty);

                            final isAlreadyPacked =
                                (order.status ?? '').toLowerCase() ==
                                        'packed' ||
                                    (order.adminStatus ?? '').toLowerCase() ==
                                        'packed' ||
                                    (order.adminStatus ?? '').toLowerCase() ==
                                        'frozen_staged';

                            final isDelivered =
                                order.deliveryStatus == 'delivered';

                            return Column(
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                  child: _TopSummary(
                                    orderNumber: order.orderNumber ?? order.id,
                                    customerName: order.customerName ??
                                        'Unknown customer',
                                    paymentStatus:
                                        order.paymentStatus ?? 'pending',
                                    adminStatus: order.adminStatus ?? 'pending',
                                    pickedCount: pickedQty,
                                    totalCount: totalQty,
                                    hasFrozenItems: order.hasFrozenItems,
                                  ),
                                ),
                                if (!_bagQrVerified && !isAlreadyPacked)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 0, 16, 12),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () =>
                                                    _showManualBarcodeDialog(
                                                        context, ref),
                                                icon: const Icon(
                                                    Icons.keyboard_rounded),
                                                label: const Text(
                                                    'Enter Item Barcode'),
                                                style: OutlinedButton.styleFrom(
                                                  minimumSize:
                                                      const Size.fromHeight(48),
                                                  side: const BorderSide(
                                                    color: WMTheme.royalPurple,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            14),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton.icon(
                                            onPressed: () =>
                                                _showManualOrderNumberDialog(
                                                    context, ref, order),
                                            icon:
                                                const Icon(Icons.pin_outlined),
                                            label: const Text(
                                              'Enter Order Number Instead',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (_bagQrVerified)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 0, 16, 12),
                                    child: _VerifiedFocusCard(
                                      orderNumber:
                                          order.orderNumber ?? order.id,
                                      hasFrozenItems: order.hasFrozenItems,
                                      onCancel: _resetQrVerification,
                                      onConfirm: () async {
                                        await ref
                                            .read(adminOrdersServiceProvider)
                                            .markOrderPacked(
                                              orderId: orderId,
                                              hasFrozenItems:
                                                  order.hasFrozenItems,
                                            );

                                        ref.invalidate(
                                            adminOrderProvider(orderId));
                                        ref.invalidate(
                                            adminOrderItemsProvider(orderId));
                                        ref.invalidate(adminOrdersProvider);

                                        await ScanFeedback.success();

                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Order packed successfully.',
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                          _resetQrVerification();
                                        }
                                      },
                                    ),
                                  ),
                                if (isAlreadyPacked)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 0, 16, 12),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1FAF3),
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                            color: const Color(0xFFBFE3C7)),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(
                                            Icons.check_circle_rounded,
                                            color: Colors.green,
                                          ),
                                          SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              'This order is already packed. QR verification is complete.',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                if (isAlreadyPacked)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 0, 16, 12),
                                    child: ElevatedButton(
                                      onPressed: isDelivered
                                          ? null
                                          : () => _scanAndMarkDelivered(
                                                context,
                                                ref,
                                                order,
                                              ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: WMTheme.royalPurple,
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size.fromHeight(52),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                      ),
                                      child: Text(
                                        isDelivered
                                            ? 'Delivered'
                                            : 'Scan & Deliver',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                Expanded(
                                  child: IgnorePointer(
                                    ignoring: _bagQrVerified,
                                    child: Opacity(
                                      opacity: _bagQrVerified ? 0.45 : 1,
                                      child: ListView(
                                        padding: const EdgeInsets.fromLTRB(
                                            16, 0, 16, 24),
                                        children: [
                                          if (nonFrozen.isNotEmpty) ...[
                                            const _SectionTitle('Non-Frozen'),
                                            const SizedBox(height: 10),
                                            ...nonFrozen.map(
                                              (item) => Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 10),
                                                child: _ItemTile(item: item),
                                              ),
                                            ),
                                          ],
                                          if (frozen.isNotEmpty) ...[
                                            const SizedBox(height: 10),
                                            const _SectionTitle('Frozen'),
                                            const SizedBox(height: 6),
                                            Container(
                                              margin: const EdgeInsets.only(
                                                  bottom: 10),
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEAF5FF),
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                border: Border.all(
                                                  color:
                                                      const Color(0xFFCFE6FF),
                                                ),
                                              ),
                                              child: const Text(
                                                'Frozen items are barcode-verified as picked and moved to freezer staging. They are packed only after final order bag verification.',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF1565C0),
                                                ),
                                              ),
                                            ),
                                            ...frozen.map(
                                              (item) => Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 10),
                                                child: _ItemTile(item: item),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                if (!_bagQrVerified && !isAlreadyPacked)
                                  _BottomActions(
                                    canPack: canPack,
                                    onStartPicking: () async {
                                      await ref
                                          .read(adminOrdersServiceProvider)
                                          .startPicking(orderId);
                                      ref.invalidate(
                                          adminOrderProvider(orderId));
                                      ref.invalidate(adminOrdersProvider);
                                    },
                                    onMarkPacked: () async {
                                      await _scanOrderQrAndPreparePack(
                                        context,
                                        ref,
                                        order,
                                      );
                                    },
                                  ),
                              ],
                            );
                          },
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Center(
                            child: Text(
                              'Failed to load items\n$e',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(
                        child: Text(
                          'Failed to load order\n$e',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_flashColor != null)
            IgnorePointer(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                color: _flashColor!.withValues(alpha: 0.18),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _scanOrderQrAndPreparePack(
    BuildContext context,
    WidgetRef ref,
    AdminOrderModel order,
  ) async {
    final isAlreadyPacked = (order.status ?? '').toLowerCase() == 'packed' ||
        (order.adminStatus ?? '').toLowerCase() == 'packed' ||
        (order.adminStatus ?? '').toLowerCase() == 'frozen_staged';

    if (isAlreadyPacked) {
      await ScanFeedback.error();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This order is already packed'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

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

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scanned QR does not match this order'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    _setFlash(Colors.green);
    await ScanFeedback.success();

    if (!mounted) return;

    setState(() {
      _bagQrVerified = true;
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bag QR verified. Confirm pack to continue.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _showManualOrderNumberDialog(
    BuildContext context,
    WidgetRef ref,
    AdminOrderModel order,
  ) async {
    final isAlreadyPacked = (order.status ?? '').toLowerCase() == 'packed' ||
        (order.adminStatus ?? '').toLowerCase() == 'packed' ||
        (order.adminStatus ?? '').toLowerCase() == 'frozen_staged';

    if (isAlreadyPacked) {
      await ScanFeedback.error();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This order is already packed'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final typedValue = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const _ManualCodeEntryScreen(
          title: 'Enter Order Number',
          hintText: 'e.g. MH-260316-C52907',
          keyboardType: TextInputType.text,
          uppercase: true,
        ),
      ),
    );

    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;
    if (typedValue == null || typedValue.trim().isEmpty) return;

    final typed = typedValue.trim().toUpperCase();
    final expected = (order.orderNumber ?? '').trim().toUpperCase();

    if (typed != expected) {
      _setFlash(Colors.red);
      await ScanFeedback.error();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entered order number does not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _setFlash(Colors.green);
    await ScanFeedback.success();

    if (!mounted) return;

    setState(() {
      _bagQrVerified = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order number verified. Confirm pack to continue.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _showManualBarcodeDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const _ManualCodeEntryScreen(
          title: 'Enter Item Barcode',
          hintText: 'e.g. 9000000000001',
          keyboardType: TextInputType.number,
        ),
      ),
    );

    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;
    if (barcode == null || barcode.trim().isEmpty) return;

    try {
      final result = await ref
          .read(adminOrdersServiceProvider)
          .verifyManualBarcodeForOrder(
            orderId: orderId,
            barcode: barcode.trim(),
          );

      if (!mounted) return;

      _setFlash(result.success ? Colors.green : Colors.red);

      if (result.success) {
        await ScanFeedback.success();
      } else {
        await ScanFeedback.error();
      }

      if (!mounted) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        ref.invalidate(adminOrderItemsProvider(orderId));
        ref.invalidate(adminOrderProvider(orderId));
        ref.invalidate(adminOrdersProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );
      });
    } catch (e) {
      _setFlash(Colors.red);
      await ScanFeedback.error();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Barcode verification failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _scanAndMarkDelivered(
    BuildContext context,
    WidgetRef ref,
    AdminOrderModel order,
  ) async {
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
      await ScanFeedback.error();

      if (!mounted) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QR does not match order'),
            backgroundColor: Colors.red,
          ),
        );
      });
      return;
    }

    await ref.read(adminOrdersServiceProvider).markOrderDelivered(
          orderId: order.id,
        );

    if (!mounted) return;

    await ScanFeedback.success();

    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.invalidate(adminOrderProvider(order.id));
      ref.invalidate(adminOrderItemsProvider(order.id));
      ref.invalidate(adminOrdersProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order marked as delivered'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }
}

class _TopSummary extends StatelessWidget {
  final String orderNumber;
  final String customerName;
  final String paymentStatus;
  final String adminStatus;
  final int pickedCount;
  final int totalCount;
  final bool hasFrozenItems;

  const _TopSummary({
    required this.orderNumber,
    required this.customerName,
    required this.paymentStatus,
    required this.adminStatus,
    required this.pickedCount,
    required this.totalCount,
    required this.hasFrozenItems,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalCount == 0 ? 0.0 : pickedCount / totalCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
          Text(
            orderNumber,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: WMTheme.royalPurple,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            customerName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(999),
            backgroundColor: const Color(0xFFEDE7F6),
            valueColor: const AlwaysStoppedAnimation(WMTheme.royalPurple),
          ),
          const SizedBox(height: 8),
          Text(
            '$pickedCount / $totalCount units verified',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(label: paymentStatus.toUpperCase()),
              _MetaChip(label: adminStatus.replaceAll('_', ' ').toUpperCase()),
              if (hasFrozenItems) const _MetaChip(label: 'FROZEN ITEMS'),
            ],
          ),
        ],
      ),
    );
  }
}

class _VerifiedFocusCard extends StatelessWidget {
  final String orderNumber;
  final bool hasFrozenItems;
  final VoidCallback onCancel;
  final Future<void> Function() onConfirm;

  const _VerifiedFocusCard({
    required this.orderNumber,
    required this.hasFrozenItems,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF1FAF3),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBFE3C7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 52,
            color: Colors.green,
          ),
          const SizedBox(height: 10),
          const Text(
            'Bag QR Verified',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'This bag matches order $orderNumber',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasFrozenItems
                ? 'Frozen items should already be staged. Confirm to mark this order as packed.'
                : 'All items are verified. Confirm to mark this order as packed.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Confirm Pack',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;

  const _MetaChip({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F1FB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: WMTheme.royalPurple,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final AdminOrderItemModel item;

  const _ItemTile({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final complete = item.pickedQty >= item.qty;
    final partial = item.pickedQty > 0 && item.pickedQty < item.qty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: complete
              ? const Color(0xFFBFE3C7)
              : partial
                  ? const Color(0xFFFFD8A8)
                  : const Color(0xFFE6DFF0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFF6F0FB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: item.image != null && item.image!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      item.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.inventory_2_rounded,
                        color: WMTheme.royalPurple,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.inventory_2_rounded,
                    color: WMTheme.royalPurple,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if ((item.brandName ?? '').isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    item.brandName!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.black54,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TinyBadge(label: 'Qty ${item.qty}'),
                    _TinyBadge(label: 'Picked ${item.pickedQty}/${item.qty}'),
                    _TinyBadge(
                      label: item.isFrozen ? 'Frozen' : 'Non-Frozen',
                      background: item.isFrozen
                          ? const Color(0xFFEAF5FF)
                          : const Color(0xFFF4F4F4),
                      foreground: item.isFrozen
                          ? const Color(0xFF1565C0)
                          : Colors.black87,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            complete
                ? Icons.check_circle_rounded
                : partial
                    ? Icons.timelapse_rounded
                    : Icons.radio_button_unchecked_rounded,
            color: complete
                ? Colors.green
                : partial
                    ? Colors.orange
                    : Colors.black38,
          ),
        ],
      ),
    );
  }
}

class _TinyBadge extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _TinyBadge({
    required this.label,
    this.background = const Color(0xFFF6F0FB),
    this.foreground = WMTheme.royalPurple,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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

class _BottomActions extends StatelessWidget {
  final bool canPack;
  final Future<void> Function() onStartPicking;
  final Future<void> Function() onMarkPacked;

  const _BottomActions({
    required this.canPack,
    required this.onStartPicking,
    required this.onMarkPacked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onStartPicking,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  side: const BorderSide(color: WMTheme.royalPurple),
                ),
                child: const Text(
                  'Start Picking',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: WMTheme.royalPurple,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: canPack ? onMarkPacked : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: WMTheme.royalPurple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Verify Bag QR & Pack',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManualCodeEntryScreen extends StatefulWidget {
  final String title;
  final String hintText;
  final TextInputType keyboardType;
  final bool uppercase;

  const _ManualCodeEntryScreen({
    required this.title,
    required this.hintText,
    required this.keyboardType,
    this.uppercase = false,
  });

  @override
  State<_ManualCodeEntryScreen> createState() => _ManualCodeEntryScreenState();
}

class _ManualCodeEntryScreenState extends State<_ManualCodeEntryScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = widget.uppercase
        ? _controller.text.trim().toUpperCase()
        : _controller.text.trim();

    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3FB),
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
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
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _controller,
                      autofocus: true,
                      keyboardType: widget.keyboardType,
                      textCapitalization: widget.uppercase
                          ? TextCapitalization.characters
                          : TextCapitalization.none,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFD7CCE7),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _submit,
                      child: Container(
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: WMTheme.royalPurple,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'Confirm',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
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
    );
  }
}
