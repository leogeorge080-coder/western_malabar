import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:western_malabar/core/feedback/scan_feedback.dart';
import 'package:western_malabar/features/admin/models/admin_order_item_model.dart';
import 'package:western_malabar/features/admin/models/admin_order_model.dart';
import 'package:western_malabar/features/admin/providers/admin_order_detail_provider.dart';
import 'package:western_malabar/features/admin/providers/admin_orders_provider.dart';
import 'package:western_malabar/features/admin/screens/order_qr_scan_screen.dart';
import 'package:western_malabar/features/admin/services/admin_orders_service.dart';
import 'package:western_malabar/shared/theme/theme.dart';
import 'package:western_malabar/shared/widgets/wm_product_image.dart';

const _wmBg = Color(0xFFF4F5F7);
const _wmSurface = Colors.white;
const _wmSurfaceSoft = Color(0xFFF8F9FB);

const _wmTextStrong = Color(0xFF171A1F);
const _wmTextSoft = Color(0xFF5F6875);
const _wmTextMuted = Color(0xFF8A93A1);

const _wmBorder = Color(0xFFE6EAF0);
const _wmBorderStrong = Color(0xFFD7DDE6);

const _wmPrimary = Color(0xFF5A2D82);
const _wmPrimarySoft = Color(0xFFF4EDFB);

const _wmSuccess = Color(0xFF1E8E3E);
const _wmSuccessBg = Color(0xFFF1FAF3);
const _wmSuccessBorder = Color(0xFFBFE3C7);

const _wmWarning = Color(0xFFB26A00);
const _wmWarningBg = Color(0xFFFFF6E8);
const _wmWarningBorder = Color(0xFFFFD8A8);

const _wmInfo = Color(0xFF1565C0);
const _wmInfoBg = Color(0xFFEAF5FF);
const _wmInfoBorder = Color(0xFFCFE6FF);

const _wmDanger = Color(0xFFC62828);
const _wmDangerBg = Color(0xFFFFF4F4);
const _wmDangerBorder = Color(0xFFFFD1D1);

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

  void _refreshOrderViews(WidgetRef ref) {
    ref.invalidate(adminOrderItemsProvider(orderId));
    ref.invalidate(adminOrderProvider(orderId));
    ref.invalidate(adminOrdersProvider);
  }

  Future<void> _runBarcodeVerification({
    required BuildContext context,
    required WidgetRef ref,
    required String rawBarcode,
  }) async {
    final barcode = rawBarcode.trim();
    if (barcode.isEmpty) return;

    try {
      final result = await ref
          .read(adminOrdersServiceProvider)
          .verifyManualBarcodeForOrder(
            orderId: orderId,
            barcode: barcode,
          );

      if (!mounted) return;

      _setFlash(result.success ? _wmSuccess : _wmDanger);

      if (result.success) {
        await ScanFeedback.success();
      } else {
        await ScanFeedback.error();
      }

      if (!mounted) return;

      _refreshOrderViews(ref);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? _wmSuccess : _wmDanger,
        ),
      );
    } catch (e) {
      _setFlash(_wmDanger);
      await ScanFeedback.error();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Barcode verification failed: $e'),
          backgroundColor: _wmDanger,
        ),
      );
    }
  }

  Future<void> _undoLastScan(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      final result =
          await ref.read(adminOrdersServiceProvider).undoLastScan(orderId);

      if (!mounted) return;

      _setFlash(_wmWarning);
      await ScanFeedback.soft();

      _refreshOrderViews(ref);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: _wmWarning,
        ),
      );
    } catch (e) {
      _setFlash(_wmDanger);
      await ScanFeedback.error();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: _wmDanger,
        ),
      );
    }
  }

  Future<void> _showShortPickDialog(
    BuildContext context,
    WidgetRef ref,
    AdminOrderItemModel item,
  ) async {
    final qtyController = TextEditingController(text: '1');
    final reasonController = TextEditingController();

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Short Pick Item'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Missing quantity',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Reason',
                    hintText: 'Out of stock, damaged, not found...',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      );

      if (confirmed != true) return;

      final shortQty = int.tryParse(qtyController.text.trim()) ?? 0;
      final reason = reasonController.text.trim();

      await ref.read(adminOrdersServiceProvider).shortPickOrderItem(
            orderId: orderId,
            orderItemId: item.id,
            shortPickQty: shortQty,
            reason: reason,
          );

      if (!mounted) return;

      _setFlash(_wmWarning);
      await ScanFeedback.soft();
      _refreshOrderViews(ref);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.productName} marked as short-picked'),
          backgroundColor: _wmWarning,
        ),
      );
    } catch (e) {
      _setFlash(_wmDanger);
      await ScanFeedback.error();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: _wmDanger,
        ),
      );
    } finally {
      qtyController.dispose();
      reasonController.dispose();
    }
  }

  Future<void> _reopenPickingSession(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      await ref
          .read(adminOrdersServiceProvider)
          .reopenPartiallyPickedOrder(orderId);

      if (!mounted) return;

      _setFlash(_wmInfo);
      await ScanFeedback.soft();
      _refreshOrderViews(ref);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Picking session reset and reopened'),
          backgroundColor: _wmInfo,
        ),
      );
    } catch (e) {
      _setFlash(_wmDanger);
      await ScanFeedback.error();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: _wmDanger,
        ),
      );
    }
  }

  Future<void> _scanItemBarcode(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final scannedValue = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const _ItemBarcodeScanScreen(),
      ),
    );

    if (!mounted) return;
    if (scannedValue == null || scannedValue.trim().isEmpty) return;

    await _runBarcodeVerification(
      context: context,
      ref: ref,
      rawBarcode: scannedValue,
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

    await _runBarcodeVerification(
      context: context,
      ref: ref,
      rawBarcode: barcode,
    );
  }

  Future<void> _showHelpOptionsSheet(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _wmSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: SizedBox(
                    width: 42,
                    child: Divider(thickness: 4),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Item Picking Help',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _wmTextStrong,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Scan the barcode printed on the product pack. If scanning is not possible, enter the barcode manually.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _wmTextSoft,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _scanItemBarcode(context, ref);
                    },
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    label: const Text(
                      'Scan Barcode',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _wmPrimary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _showManualBarcodeDialog(context, ref);
                    },
                    icon: const Icon(Icons.keyboard_rounded),
                    label: const Text(
                      'Enter Barcode Manually',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _wmPrimary,
                      side: const BorderSide(color: _wmPrimary),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
            backgroundColor: _wmWarning,
          ),
        );
      }
      return;
    }

    final baseQr = 'WM|ORDER|${order.id}|${order.orderNumber}';
    final normalBagQr = '$baseQr-N';
    final frozenBagQr = '$baseQr-F';

    final scannedValue = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => OrderQrScanScreen(
          title: 'Verify Order Bag QR',
          instruction: 'Scan the order bag label for this order',
          validator: (rawValue) {
            final scanned = rawValue.trim();
            if (scanned == baseQr ||
                scanned == normalBagQr ||
                scanned == frozenBagQr) {
              return null;
            }
            return 'Scanned QR does not match this order';
          },
        ),
      ),
    );

    if (scannedValue == null || scannedValue.trim().isEmpty) {
      return;
    }

    _setFlash(_wmSuccess);
    await ScanFeedback.success();

    if (!mounted) return;

    setState(() {
      _bagQrVerified = true;
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bag QR verified. Confirm pack to continue.'),
          backgroundColor: _wmSuccess,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(adminOrderProvider(orderId));
    final itemsAsync = ref.watch(adminOrderItemsProvider(orderId));

    return Scaffold(
      backgroundColor: _wmBg,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: _wmBg,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: _wmSurface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _wmBorder),
                          ),
                          child: IconButton(
                            onPressed: _bagQrVerified
                                ? null
                                : () => Navigator.maybePop(context),
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: _wmTextStrong,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'Order Detail',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: _wmTextStrong,
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: _wmSurface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _wmBorder),
                          ),
                          child: IconButton(
                            onPressed: _bagQrVerified
                                ? null
                                : () => _showHelpOptionsSheet(context, ref),
                            icon: const Icon(
                              Icons.help_outline_rounded,
                              color: _wmTextStrong,
                            ),
                          ),
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
                            final resolvedQty = items.fold<int>(
                              0,
                              (sum, e) => sum + e.resolvedQty,
                            );

                            final canPack = items.isNotEmpty &&
                                items.every((e) => e.isResolved);

                            final safeStatus =
                                (order.status ?? '').toLowerCase();
                            final safeAdminStatus =
                                (order.adminStatus ?? '').toLowerCase();
                            final safeDeliveryStatus =
                                (order.deliveryStatus ?? '').toLowerCase();

                            final isAlreadyPacked = safeStatus == 'packed' ||
                                safeAdminStatus == 'packed' ||
                                safeAdminStatus == 'frozen_staged';

                            final isOutForDelivery =
                                safeDeliveryStatus == 'out_for_delivery' ||
                                    safeStatus == 'out_for_delivery';

                            final isDelivered =
                                safeDeliveryStatus == 'delivered' ||
                                    safeStatus == 'delivered' ||
                                    safeAdminStatus == 'delivered';

                            final isPickingActive = order.isPending ||
                                order.isPicking ||
                                order.isPartiallyPicked ||
                                order.isPicked;

                            final showItemScan = !_bagQrVerified &&
                                isPickingActive &&
                                !isAlreadyPacked &&
                                !isOutForDelivery &&
                                !isDelivered &&
                                !canPack;

                            final showPackActions = !_bagQrVerified &&
                                !isAlreadyPacked &&
                                !isOutForDelivery &&
                                !isDelivered;

                            final showPackedInfo = isAlreadyPacked &&
                                !isOutForDelivery &&
                                !isDelivered;

                            final showDriverModeInfo = isAlreadyPacked &&
                                !isOutForDelivery &&
                                !isDelivered;

                            final showOutForDeliveryInfo =
                                isOutForDelivery && !isDelivered;

                            final showDeliveredInfo = isDelivered;

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
                                    adminStatus: order.displayStatusLabel,
                                    pickedCount: resolvedQty,
                                    totalCount: totalQty,
                                    hasFrozenItems: order.hasFrozenItems,
                                  ),
                                ),
                                if (showItemScan)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 0, 16, 12),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () =>
                                            _scanItemBarcode(context, ref),
                                        icon: const Icon(
                                          Icons.qr_code_scanner_rounded,
                                        ),
                                        label: const Text(
                                          'Scan Item Barcode',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _wmPrimary,
                                          foregroundColor: Colors.white,
                                          minimumSize:
                                              const Size.fromHeight(52),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                        ),
                                      ),
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

                                        _refreshOrderViews(ref);

                                        await ScanFeedback.success();

                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Order packed successfully.',
                                              ),
                                              backgroundColor: _wmSuccess,
                                            ),
                                          );
                                          _resetQrVerification();
                                        }
                                      },
                                    ),
                                  ),
                                if (showPackedInfo)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 0, 16, 12),
                                    child: _StateInfoCard(
                                      icon: Icons.check_circle_rounded,
                                      iconColor: _wmSuccess,
                                      background: _wmSuccessBg,
                                      border: _wmSuccessBorder,
                                      text:
                                          'This order is already packed. QR verification is complete.',
                                    ),
                                  ),
                                if (showDriverModeInfo)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 0, 16, 12),
                                    child: _StateInfoCard(
                                      icon: Icons.local_shipping_rounded,
                                      iconColor: _wmInfo,
                                      background: _wmInfoBg,
                                      border: _wmInfoBorder,
                                      text:
                                          'Packed successfully. Use Driver Mode to dispatch and complete delivery scanning.',
                                    ),
                                  ),
                                if (showOutForDeliveryInfo)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 0, 16, 12),
                                    child: _StateInfoCard(
                                      icon: Icons.local_shipping_rounded,
                                      iconColor: _wmInfo,
                                      background: _wmInfoBg,
                                      border: _wmInfoBorder,
                                      text:
                                          'This order is out for delivery. Complete the final handoff in Driver Mode.',
                                    ),
                                  ),
                                if (showDeliveredInfo)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 0, 16, 12),
                                    child: _StateInfoCard(
                                      icon: Icons.task_alt_rounded,
                                      iconColor: _wmSuccess,
                                      background: _wmSuccessBg,
                                      border: _wmSuccessBorder,
                                      text:
                                          'This order has been delivered successfully.',
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
                                                  bottom: 10,
                                                ),
                                                child: _ItemTile(
                                                  item: item,
                                                  canShortPick:
                                                      !_bagQrVerified &&
                                                          !isAlreadyPacked &&
                                                          !isOutForDelivery &&
                                                          !isDelivered &&
                                                          !item.isResolved,
                                                  onShortPickTap: () =>
                                                      _showShortPickDialog(
                                                    context,
                                                    ref,
                                                    item,
                                                  ),
                                                ),
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
                                                color: _wmInfoBg,
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                border: Border.all(
                                                  color: _wmInfoBorder,
                                                ),
                                              ),
                                              child: const Text(
                                                'Frozen items are barcode-verified as picked and moved to freezer staging. They are packed only after final order bag verification.',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: _wmInfo,
                                                ),
                                              ),
                                            ),
                                            ...frozen.map(
                                              (item) => Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 10,
                                                ),
                                                child: _ItemTile(
                                                  item: item,
                                                  canShortPick:
                                                      !_bagQrVerified &&
                                                          !isAlreadyPacked &&
                                                          !isOutForDelivery &&
                                                          !isDelivered &&
                                                          !item.isResolved,
                                                  onShortPickTap: () =>
                                                      _showShortPickDialog(
                                                    context,
                                                    ref,
                                                    item,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                if (showPackActions)
                                  _BottomActions(
                                    canPack: canPack,
                                    pickingComplete: canPack,
                                    canUndo: !isAlreadyPacked &&
                                        !isOutForDelivery &&
                                        !isDelivered &&
                                        items.any((e) => e.pickedQty > 0),
                                    canReopen: order.isPartiallyPicked,
                                    onStartPicking: () async {
                                      await ref
                                          .read(adminOrdersServiceProvider)
                                          .startPicking(orderId);
                                      _refreshOrderViews(ref);
                                    },
                                    onUndoLastScan: () =>
                                        _undoLastScan(context, ref),
                                    onReopenPicking: () =>
                                        _reopenPickingSession(context, ref),
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
                          loading: () => const Center(
                            child: CircularProgressIndicator(
                              color: _wmPrimary,
                            ),
                          ),
                          error: (e, _) => Center(
                            child: Text(
                              'Failed to load items\n$e',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: _wmTextSoft),
                            ),
                          ),
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: _wmPrimary,
                        ),
                      ),
                      error: (e, _) => Center(
                        child: Text(
                          'Failed to load order\n$e',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: _wmTextSoft),
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
                color: _flashColor!.withValues(alpha: 0.14),
              ),
            ),
        ],
      ),
    );
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
        color: _wmSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _wmBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 5),
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
              color: _wmTextStrong,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            customerName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _wmTextStrong,
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(999),
            backgroundColor: Color(0xFFECEFF4),
            valueColor: AlwaysStoppedAnimation(_wmPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            '$pickedCount / $totalCount units resolved',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: _wmTextSoft,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(label: paymentStatus.toUpperCase()),
              _MetaChip(label: adminStatus.replaceAll('_', ' ').toUpperCase()),
              if (hasFrozenItems)
                const _MetaChip(
                  label: 'FROZEN ITEMS',
                  background: _wmInfoBg,
                  foreground: _wmInfo,
                  borderColor: _wmInfoBorder,
                ),
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
        color: _wmSuccessBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _wmSuccessBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 52,
            color: _wmSuccess,
          ),
          const SizedBox(height: 10),
          const Text(
            'Bag QR Verified',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: _wmTextStrong,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'This bag matches order $orderNumber',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _wmTextSoft,
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
              color: _wmTextSoft,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _wmTextStrong,
                    side: const BorderSide(color: _wmBorderStrong),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    backgroundColor: _wmSurface,
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _wmSuccess,
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

class _StateInfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color background;
  final Color border;
  final String text;

  const _StateInfoCard({
    required this.icon,
    required this.iconColor,
    required this.background,
    required this.border,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: _wmTextStrong,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final Color borderColor;

  const _MetaChip({
    required this.label,
    this.background = _wmSurfaceSoft,
    this.foreground = _wmTextSoft,
    this.borderColor = _wmBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: foreground,
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
        color: _wmTextStrong,
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final AdminOrderItemModel item;
  final bool canShortPick;
  final VoidCallback? onShortPickTap;

  const _ItemTile({
    required this.item,
    this.canShortPick = false,
    this.onShortPickTap,
  });

  @override
  Widget build(BuildContext context) {
    final complete = item.isResolved;
    final partial = item.isPartiallyPicked || item.isShortPicked;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _wmSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: complete
              ? _wmSuccessBorder
              : partial
                  ? _wmWarningBorder
                  : _wmBorder,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: _wmSurfaceSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: WmProductImage(
              imageUrl: item.image,
              width: 54,
              height: 54,
              borderRadius: 14,
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
                    color: _wmTextStrong,
                  ),
                ),
                if ((item.brandName ?? '').isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    item.brandName!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _wmTextSoft,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TinyBadge(label: 'Qty ${item.qty}'),
                    _TinyBadge(
                      label: 'Picked ${item.pickedQty}/${item.qty}',
                    ),
                    if (item.shortPickQty > 0)
                      _TinyBadge(
                        label: 'Short ${item.shortPickQty}/${item.qty}',
                        background: _wmWarningBg,
                        foreground: _wmWarning,
                      ),
                    _TinyBadge(
                      label: item.isFrozen ? 'Frozen' : 'Non-Frozen',
                      background:
                          item.isFrozen ? _wmInfoBg : const Color(0xFFF4F4F4),
                      foreground: item.isFrozen ? _wmInfo : _wmTextStrong,
                    ),
                  ],
                ),
                if ((item.shortPickReason ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Reason: ${item.shortPickReason}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _wmWarning,
                    ),
                  ),
                ],
                if (canShortPick && onShortPickTap != null) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: onShortPickTap,
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                      label: const Text(
                        'Short Pick / Missing',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: _wmWarning,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
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
                ? _wmSuccess
                : partial
                    ? _wmWarning
                    : _wmTextMuted,
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
    this.background = _wmSurfaceSoft,
    this.foreground = _wmTextSoft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _wmBorder),
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
  final bool pickingComplete;
  final bool canUndo;
  final bool canReopen;
  final Future<void> Function() onStartPicking;
  final Future<void> Function() onUndoLastScan;
  final Future<void> Function() onReopenPicking;
  final Future<void> Function() onMarkPacked;

  const _BottomActions({
    required this.canPack,
    required this.pickingComplete,
    required this.canUndo,
    required this.canReopen,
    required this.onStartPicking,
    required this.onUndoLastScan,
    required this.onReopenPicking,
    required this.onMarkPacked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        color: _wmSurface,
        border: Border(
          top: BorderSide(color: _wmBorder),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canUndo || canReopen) ...[
              Row(
                children: [
                  if (canUndo)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onUndoLastScan,
                        icon: const Icon(Icons.undo_rounded),
                        label: const Text(
                          'Undo Last Scan',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _wmWarning,
                          side: const BorderSide(color: _wmWarning),
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  if (canUndo && canReopen) const SizedBox(width: 12),
                  if (canReopen)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReopenPicking,
                        icon: const Icon(Icons.restart_alt_rounded),
                        label: const Text(
                          'Reopen Picking',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _wmInfo,
                          side: const BorderSide(color: _wmInfo),
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                if (!pickingComplete) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onStartPicking,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _wmPrimary,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: const BorderSide(color: _wmPrimary),
                      ),
                      child: const Text(
                        'Start Picking',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: canPack ? onMarkPacked : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _wmPrimary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFD6D9E0),
                      disabledForegroundColor: const Color(0xFF7E8591),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      canPack
                          ? 'Verify Bag QR & Pack'
                          : 'Resolve Items Before Packing',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
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
      backgroundColor: _wmBg,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: _wmTextStrong,
          ),
        ),
        backgroundColor: _wmSurface,
        foregroundColor: _wmTextStrong,
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
                  color: _wmSurface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _wmBorder),
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
                        color: _wmTextStrong,
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
                        filled: true,
                        fillColor: _wmSurfaceSoft,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _wmBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _wmBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: _wmPrimary, width: 1.4),
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
                          color: _wmSurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _wmBorderStrong,
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: _wmTextStrong,
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
                          color: _wmPrimary,
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

class _ItemBarcodeScanScreen extends StatefulWidget {
  const _ItemBarcodeScanScreen();

  @override
  State<_ItemBarcodeScanScreen> createState() => _ItemBarcodeScanScreenState();
}

class _ItemBarcodeScanScreenState extends State<_ItemBarcodeScanScreen> {
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Scan Item Barcode',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: MobileScanner(
        onDetect: (capture) async {
          if (_handled) return;

          final codes = capture.barcodes;
          if (codes.isEmpty) return;

          final raw = codes.first.rawValue?.trim();
          if (raw == null || raw.isEmpty) return;

          _handled = true;
          await ScanFeedback.soft();
          if (!mounted) return;
          Navigator.of(context).pop(raw);
        },
      ),
    );
  }
}
