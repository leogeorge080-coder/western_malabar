import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:western_malabar/features/auth/providers/auth_provider.dart';
import 'package:western_malabar/features/orders/models/order_detail_model.dart';
import 'package:western_malabar/features/orders/models/order_history_model.dart';
import 'package:western_malabar/features/orders/models/order_item_model.dart';
import 'package:western_malabar/features/orders/services/orders_service.dart';

final ordersServiceProvider = Provider<OrdersService>((ref) {
  return OrdersService(Supabase.instance.client);
});

/// ✅ AUTH-AWARE (important fix)
final myOrdersProvider =
    FutureProvider.autoDispose<List<OrderHistoryModel>>((ref) async {
  final user = ref.watch(authUserProvider);

  if (user == null || user.isAnonymous) {
    return const <OrderHistoryModel>[];
  }

  final service = ref.read(ordersServiceProvider);
  return service.fetchMyOrders();
});

final orderDetailProvider = FutureProvider.autoDispose
    .family<OrderDetailModel, String>((ref, orderId) async {
  final user = ref.watch(authUserProvider);

  if (user == null || user.isAnonymous) {
    throw Exception('User not signed in');
  }

  final service = ref.read(ordersServiceProvider);
  return service.fetchOrderDetail(orderId);
});

final orderItemsProvider = FutureProvider.autoDispose
    .family<List<OrderItemModel>, String>((ref, orderId) async {
  final user = ref.watch(authUserProvider);

  if (user == null || user.isAnonymous) {
    return const <OrderItemModel>[];
  }

  final service = ref.read(ordersServiceProvider);
  return service.fetchOrderItems(orderId);
});
