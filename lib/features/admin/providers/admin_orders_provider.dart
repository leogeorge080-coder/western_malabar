import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:western_malabar/features/admin/models/admin_order_model.dart';
import 'package:western_malabar/features/admin/services/admin_orders_service.dart';

final adminOrdersProvider = FutureProvider<List<AdminOrderModel>>((ref) async {
  return ref.read(adminOrdersServiceProvider).fetchRecentOrders();
});
