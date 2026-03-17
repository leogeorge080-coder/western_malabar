import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:western_malabar/features/admin/models/admin_order_item_model.dart';
import 'package:western_malabar/features/admin/models/admin_order_model.dart';
import 'package:western_malabar/features/admin/services/admin_orders_service.dart';

final adminOrderProvider =
    FutureProvider.family<AdminOrderModel, String>((ref, orderId) async {
  return ref.read(adminOrdersServiceProvider).fetchOrder(orderId);
});

final adminOrderItemsProvider =
    FutureProvider.family<List<AdminOrderItemModel>, String>(
        (ref, orderId) async {
  return ref.read(adminOrdersServiceProvider).fetchOrderItems(orderId);
});




