import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:western_malabar/features/orders/models/order_detail_model.dart';
import 'package:western_malabar/features/orders/models/order_item_model.dart';
import 'package:western_malabar/features/orders/providers/orders_provider.dart';
import 'package:western_malabar/shared/widgets/wm_product_image.dart';

const _wmOrderBg = Color(0xFFF7F7F7);
const _wmOrderSurface = Colors.white;
const _wmOrderSurfaceSoft = Color(0xFFF9FAFB);
const _wmOrderBorder = Color(0xFFE5E7EB);

const _wmOrderTextStrong = Color(0xFF111827);
const _wmOrderTextSoft = Color(0xFF6B7280);
const _wmOrderTextMuted = Color(0xFF9CA3AF);

const _wmOrderPrimary = Color(0xFF2A2F3A);
const _wmOrderPrimaryDark = Color(0xFF171A20);

const _wmOrderSuccess = Color(0xFF15803D);
const _wmOrderSuccessSoft = Color(0xFFECFDF5);

const _wmOrderInfo = Color(0xFF2563EB);
const _wmOrderInfoSoft = Color(0xFFEFF6FF);

const _wmOrderWarning = Color(0xFFB45309);
const _wmOrderWarningSoft = Color(0xFFFFFBEB);

const _wmOrderDanger = Color(0xFFDC2626);
const _wmOrderDangerSoft = Color(0xFFFEF2F2);

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));
    final itemsAsync = ref.watch(orderItemsProvider(orderId));

    Future<void> refresh() async {
      ref.invalidate(orderDetailProvider(orderId));
      ref.invalidate(orderItemsProvider(orderId));
      await Future.wait([
        ref.read(orderDetailProvider(orderId).future),
        ref.read(orderItemsProvider(orderId).future),
      ]);
    }

    return Scaffold(
      backgroundColor: _wmOrderBg,
      body: SafeArea(
        child: Column(
          children: [
            const _OrderDetailHeader(),
            Expanded(
              child: orderAsync.when(
                loading: () => RefreshIndicator(
                  color: _wmOrderPrimary,
                  onRefresh: refresh,
                  child: const _LoadingView(),
                ),
                error: (error, _) => RefreshIndicator(
                  color: _wmOrderPrimary,
                  onRefresh: refresh,
                  child: _ErrorView(
                    message: error.toString(),
                    onRetry: () {
                      ref.invalidate(orderDetailProvider(orderId));
                      ref.invalidate(orderItemsProvider(orderId));
                    },
                  ),
                ),
                data: (order) {
                  return itemsAsync.when(
                    loading: () => RefreshIndicator(
                      color: _wmOrderPrimary,
                      onRefresh: refresh,
                      child: _OrderDetailLoadingScaffold(order: order),
                    ),
                    error: (error, _) => RefreshIndicator(
                      color: _wmOrderPrimary,
                      onRefresh: refresh,
                      child: _ErrorView(
                        message: error.toString(),
                        onRetry: () {
                          ref.invalidate(orderItemsProvider(orderId));
                        },
                      ),
                    ),
                    data: (items) {
                      return RefreshIndicator(
                        color: _wmOrderPrimary,
                        onRefresh: refresh,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          child: Column(
                            children: [
                              _OrderHeroCard(
                                  order: order, itemCount: items.length),
                              const SizedBox(height: 14),
                              _OrderTimelineCard(order: order),
                              const SizedBox(height: 14),
                              _DeliveryInfoCard(order: order),
                              const SizedBox(height: 14),
                              _OrderItemsCard(items: items),
                              const SizedBox(height: 14),
                              _OrderPricingCard(order: order),
                              const SizedBox(height: 14),
                              _SupportCard(order: order),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderDetailHeader extends StatelessWidget {
  const _OrderDetailHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(
        children: [
          Material(
            color: _wmOrderSurface,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => Navigator.maybePop(context),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _wmOrderBorder),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0C000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: _wmOrderPrimary,
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
                  'Order Details',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    color: _wmOrderTextStrong,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Track status, items and pricing',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _wmOrderTextSoft,
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

class _OrderHeroCard extends StatelessWidget {
  final OrderDetailModel order;
  final int itemCount;

  const _OrderHeroCard({
    required this.order,
    required this.itemCount,
  });

  @override
  Widget build(BuildContext context) {
    final status = order.displayStatus;
    final statusTone = _statusTone(status);
    final isPickup = _isPickup(order);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _wmOrderPrimaryDark,
            _wmOrderPrimary,
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
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
                  color: Colors.white.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.12),
                  ),
                ),
                child: Icon(
                  isPickup
                      ? Icons.storefront_outlined
                      : Icons.local_shipping_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderNumber.trim().isEmpty
                          ? 'Order'
                          : order.orderNumber.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFD1D5DB),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.10),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _HeroStat(
                    label: 'Status',
                    value: status,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HeroStat(
                    label: 'Items',
                    value: itemCount == 1 ? '1 item' : '$itemCount items',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HeroStat(
                    label: 'Total',
                    value: order.totalFormatted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  _formatDate(order.createdAt),
                  style: const TextStyle(
                    color: Color(0xFFD1D5DB),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: statusTone.bg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: statusTone.border),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusTone.fg,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static bool _isPickup(OrderDetailModel order) {
    final type = order.deliveryType.trim().toLowerCase();
    return type == 'local_pickup';
  }

  static _StatusTone _statusTone(String status) {
    switch (status) {
      case 'Delivered':
      case 'Collected':
        return const _StatusTone(
          fg: _wmOrderSuccess,
          bg: _wmOrderSuccessSoft,
          border: Color(0xFFA7F3D0),
        );
      case 'Out for Delivery':
      case 'Ready for Pickup':
        return const _StatusTone(
          fg: _wmOrderInfo,
          bg: _wmOrderInfoSoft,
          border: Color(0xFFBFDBFE),
        );
      case 'Packing':
      case 'Preparing':
      case 'Confirmed':
        return const _StatusTone(
          fg: _wmOrderWarning,
          bg: _wmOrderWarningSoft,
          border: Color(0xFFFDE68A),
        );
      case 'Cancelled':
        return const _StatusTone(
          fg: _wmOrderDanger,
          bg: _wmOrderDangerSoft,
          border: Color(0xFFFECACA),
        );
      case 'Payment Pending':
        return const _StatusTone(
          fg: Color(0xFF7C3AED),
          bg: Color(0xFFF5F3FF),
          border: Color(0xFFDDD6FE),
        );
      default:
        return const _StatusTone(
          fg: _wmOrderPrimary,
          bg: Color(0xFFF3F4F6),
          border: _wmOrderBorder,
        );
    }
  }

  static String _formatDate(DateTime? dt) {
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

    return '${dt.day} $month ${dt.year} • $hour:$minute $suffix';
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;

  const _HeroStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFCBD5E1),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _OrderTimelineCard extends StatelessWidget {
  final OrderDetailModel order;

  const _OrderTimelineCard({
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final isPickup = order.deliveryType.trim().toLowerCase() == 'local_pickup';

    final steps = <_TimelineStepData>[
      _TimelineStepData(
        label: 'Order Placed',
        icon: Icons.receipt_long_rounded,
        time: order.createdAt,
        isActive: true,
      ),
      _TimelineStepData(
        label: 'Packing',
        icon: Icons.inventory_2_rounded,
        time: order.packedAt,
        isActive: order.packedAt != null,
      ),
      _TimelineStepData(
        label: isPickup ? 'Ready for Pickup' : 'Out for Delivery',
        icon: isPickup
            ? Icons.store_mall_directory_rounded
            : Icons.local_shipping_rounded,
        time: order.outForDeliveryAt,
        isActive: order.outForDeliveryAt != null,
      ),
      _TimelineStepData(
        label: isPickup ? 'Collected' : 'Delivered',
        icon: Icons.check_circle_rounded,
        time: order.deliveredAt,
        isActive: order.deliveredAt != null,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _wmOrderSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _wmOrderBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.route_rounded,
                color: _wmOrderPrimary,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Tracking Timeline',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: _wmOrderTextStrong,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(steps.length, (index) {
            final step = steps[index];
            final isLast = index == steps.length - 1;

            return _TimelineRow(
              icon: step.icon,
              label: step.label,
              time: step.time,
              isActive: step.isActive,
              isLast: isLast,
            );
          }),
        ],
      ),
    );
  }
}

class _TimelineStepData {
  final String label;
  final IconData icon;
  final DateTime? time;
  final bool isActive;

  const _TimelineStepData({
    required this.label,
    required this.icon,
    required this.time,
    required this.isActive,
  });
}

class _TimelineRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final DateTime? time;
  final bool isActive;
  final bool isLast;

  const _TimelineRow({
    required this.icon,
    required this.label,
    required this.time,
    required this.isActive,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isActive ? _wmOrderSuccess : _wmOrderTextMuted;
    final lineColor = isActive ? const Color(0xFFA7F3D0) : _wmOrderBorder;
    final bubbleBg = isActive ? _wmOrderSuccessSoft : const Color(0xFFF3F4F6);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: bubbleBg,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          isActive ? const Color(0xFFBBF7D0) : _wmOrderBorder,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 15,
                    color: iconColor,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: lineColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color:
                            isActive ? _wmOrderTextStrong : _wmOrderTextMuted,
                      ),
                    ),
                  ),
                  if (time != null)
                    Text(
                      _formatTime(time),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _wmOrderTextSoft,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatTime(DateTime? dt) {
    if (dt == null) return '';

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
    return '${dt.day} $month';
  }
}

class _DeliveryInfoCard extends StatelessWidget {
  final OrderDetailModel order;

  const _DeliveryInfoCard({
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final isPickup = order.deliveryType.trim().toLowerCase() == 'local_pickup';
    final title = isPickup ? 'Pickup Details' : 'Delivery Details';
    final icon =
        isPickup ? Icons.storefront_outlined : Icons.location_on_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _wmOrderSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _wmOrderBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
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
              Icon(
                icon,
                color: _wmOrderPrimary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: _wmOrderTextStrong,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _InfoRow(
            label: isPickup ? 'Method' : 'Delivery Type',
            value: isPickup ? 'Store Pickup' : 'Home Delivery',
          ),
          const SizedBox(height: 12),
          _InfoRow(
            label: 'Slot',
            value: order.deliverySlot.trim().isEmpty
                ? 'Not specified'
                : order.deliverySlot,
          ),
          const SizedBox(height: 12),
          _InfoRow(
            label: isPickup ? 'Contact' : 'Phone',
            value: order.phone.trim().isEmpty ? 'Not available' : order.phone,
          ),
          if (!isPickup && order.fullAddress.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Address',
              value: order.fullAddress,
              multiline: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool multiline;

  const _InfoRow({
    required this.label,
    required this.value,
    this.multiline = false,
  });

  @override
  Widget build(BuildContext context) {
    if (multiline) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _wmOrderTextSoft,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _wmOrderTextStrong,
              height: 1.5,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _wmOrderTextSoft,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: _wmOrderTextStrong,
            ),
          ),
        ),
      ],
    );
  }
}

class _OrderItemsCard extends StatelessWidget {
  final List<OrderItemModel> items;

  const _OrderItemsCard({
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _wmOrderSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _wmOrderBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Items (${items.length})',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: _wmOrderTextStrong,
            ),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _wmOrderSurfaceSoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _wmOrderBorder),
              ),
              child: const Text(
                'No items found for this order.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _wmOrderTextSoft,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                return _OrderItemTile(item: item);
              },
            ),
        ],
      ),
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  final OrderItemModel item;

  const _OrderItemTile({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _wmOrderSurfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _wmOrderBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _wmOrderBorder),
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _wmOrderTextStrong,
                    height: 1.35,
                  ),
                ),
                if ((item.brandName ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.brandName!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _wmOrderTextSoft,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _wmOrderBorder),
                  ),
                  child: Text(
                    'Qty: ${item.qty}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _wmOrderTextStrong,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.unitPriceFormatted,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _wmOrderTextSoft,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.lineTotalFormatted,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: _wmOrderPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderPricingCard extends StatelessWidget {
  final OrderDetailModel order;

  const _OrderPricingCard({
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _wmOrderSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _wmOrderBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Summary',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: _wmOrderTextStrong,
            ),
          ),
          const SizedBox(height: 14),
          _PricingRow(
            label: 'Subtotal',
            value: order.subtotalFormatted,
          ),
          const SizedBox(height: 10),
          _PricingRow(
            label: 'Delivery Fee',
            value: order.deliveryFeeFormatted,
          ),
          const SizedBox(height: 10),
          _PricingRow(
            label: 'Payment Method',
            value: order.paymentMethod,
          ),
          const SizedBox(height: 10),
          _PricingRow(
            label: 'Payment Status',
            value: order.paymentStatus,
          ),
          const SizedBox(height: 12),
          Container(
            height: 1,
            color: _wmOrderBorder,
          ),
          const SizedBox(height: 12),
          _PricingRow(
            label: 'Total',
            value: order.totalFormatted,
            isTotal: true,
          ),
        ],
      ),
    );
  }
}

class _PricingRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _PricingRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 15 : 13,
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700,
              color: isTotal ? _wmOrderTextStrong : _wmOrderTextSoft,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: isTotal ? 16 : 13,
              fontWeight: FontWeight.w900,
              color: isTotal ? _wmOrderPrimary : _wmOrderTextStrong,
            ),
          ),
        ),
      ],
    );
  }
}

class _SupportCard extends StatelessWidget {
  final OrderDetailModel order;

  const _SupportCard({
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final isPickup = order.deliveryType.trim().toLowerCase() == 'local_pickup';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _wmOrderSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _wmOrderBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Need Help?',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: _wmOrderTextStrong,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isPickup
                ? 'For pickup timing or collection support, contact the store using your registered phone number.'
                : 'For delivery updates or address issues, contact support and mention your order number.',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _wmOrderTextSoft,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _wmOrderSurfaceSoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _wmOrderBorder),
            ),
            child: Text(
              order.orderNumber.trim().isEmpty
                  ? 'Reference: Order'
                  : 'Reference: ${order.orderNumber}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: _wmOrderPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderDetailLoadingScaffold extends StatelessWidget {
  final OrderDetailModel order;

  const _OrderDetailLoadingScaffold({
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          _OrderHeroCard(order: order, itemCount: 0),
          const SizedBox(height: 14),
          const _SkeletonCard(height: 220),
          const SizedBox(height: 14),
          const _SkeletonCard(height: 190),
          const SizedBox(height: 14),
          const _SkeletonCard(height: 240),
          const SizedBox(height: 14),
          const _SkeletonCard(height: 210),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: const [
        _SkeletonCard(height: 180),
        SizedBox(height: 14),
        _SkeletonCard(height: 220),
        SizedBox(height: 14),
        _SkeletonCard(height: 190),
        SizedBox(height: 14),
        _SkeletonCard(height: 240),
        SizedBox(height: 14),
        _SkeletonCard(height: 210),
      ],
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final double height;

  const _SkeletonCard({
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _wmOrderBorder),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _wmOrderSurface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _wmOrderBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 42,
                color: _wmOrderDanger,
              ),
              const SizedBox(height: 12),
              const Text(
                'Unable to load order',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: _wmOrderTextStrong,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: _wmOrderTextSoft,
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
                    backgroundColor: _wmOrderPrimary,
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

class _StatusTone {
  final Color fg;
  final Color bg;
  final Color border;

  const _StatusTone({
    required this.fg,
    required this.bg,
    required this.border,
  });
}
