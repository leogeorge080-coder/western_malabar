import 'package:flutter_test/flutter_test.dart';
import 'package:western_malabar/features/admin/models/admin_order_item_model.dart';
import 'package:western_malabar/features/admin/models/admin_order_model.dart';

void main() {
  group('AdminOrderModel', () {
    AdminOrderModel buildOrder({
      String? status,
      String? adminStatus,
      String? deliveryStatus,
      DateTime? outForDeliveryAt,
      DateTime? deliveredAt,
    }) {
      return AdminOrderModel(
        id: 'order-1',
        status: status,
        adminStatus: adminStatus,
        deliveryStatus: deliveryStatus,
        outForDeliveryAt: outForDeliveryAt,
        deliveredAt: deliveredAt,
      );
    }

    test('derives pending status when nothing else is set', () {
      final order = buildOrder();

      expect(order.isPending, isTrue);
      expect(order.displayStatusLabel, 'PENDING');
      expect(order.operationalBucket, 'pending');
      expect(order.statusPriority, 6);
    });

    test('derives picking states from backend admin status', () {
      final picking = buildOrder(adminStatus: 'picking');
      final partial = buildOrder(adminStatus: 'partially_picked');
      final full = buildOrder(adminStatus: 'picked');

      expect(picking.isPicking, isTrue);
      expect(picking.displayStatusLabel, 'PICKING');

      expect(partial.isPartiallyPicked, isTrue);
      expect(partial.displayStatusLabel, 'PARTIALLY PICKED');
      expect(partial.operationalBucket, 'partially_picked');

      expect(full.isPicked, isTrue);
      expect(full.displayStatusLabel, 'FULLY PICKED');
    });

    test('packed outranks picked when backend says packed', () {
      final order = buildOrder(status: 'picked', adminStatus: 'packed');

      expect(order.isPacked, isTrue);
      expect(order.isPicked, isFalse);
      expect(order.displayStatusLabel, 'PACKED');
    });

    test('delivery states outrank admin picking states', () {
      final outForDelivery = buildOrder(
        adminStatus: 'picked',
        deliveryStatus: 'out_for_delivery',
      );
      final delivered = buildOrder(
        adminStatus: 'packed',
        deliveredAt: DateTime(2026, 1, 1),
      );

      expect(outForDelivery.isOutForDelivery, isTrue);
      expect(outForDelivery.displayStatusLabel, 'OUT FOR DELIVERY');

      expect(delivered.isDelivered, isTrue);
      expect(delivered.displayStatusLabel, 'DELIVERED');
    });

    test('builds full address without blank parts', () {
      final order = AdminOrderModel(
        id: 'order-1',
        addressLine1: '221B Baker Street',
        addressLine2: '',
        city: 'London',
        postcode: 'NW1',
      );

      expect(order.fullAddress, '221B Baker Street, London, NW1');
    });
  });

  group('AdminOrderItemModel', () {
    test('resolved quantity combines picked and short-picked amounts', () {
      const item = AdminOrderItemModel(
        id: 'item-1',
        orderId: 'order-1',
        productName: 'Parotta',
        qty: 5,
        pickedQty: 3,
        shortPickQty: 2,
      );

      expect(item.resolvedQty, 5);
      expect(item.isResolved, isTrue);
      expect(item.isFullyPicked, isFalse);
      expect(item.isShortPicked, isTrue);
    });

    test('partial pick only reflects scanned quantity progress', () {
      const item = AdminOrderItemModel(
        id: 'item-1',
        orderId: 'order-1',
        productName: 'Appam',
        qty: 4,
        pickedQty: 2,
        shortPickQty: 0,
      );

      expect(item.isPartiallyPicked, isTrue);
      expect(item.isResolved, isFalse);
    });
  });
}
