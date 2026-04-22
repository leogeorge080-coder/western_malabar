import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:western_malabar/features/orders/models/order_detail_model.dart';
import 'package:western_malabar/features/orders/models/order_history_model.dart';
import 'package:western_malabar/features/orders/models/order_item_model.dart';

class OrdersService {
  final SupabaseClient supabase;

  OrdersService(this.supabase);

  /// ✅ Fetch all orders for current user
  Future<List<OrderHistoryModel>> fetchMyOrders() async {
    final user = supabase.auth.currentUser;

    if (user == null || user.isAnonymous) {
      return const <OrderHistoryModel>[];
    }

    final response = await supabase
        .from('v_order_history_with_counts')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    if (response == null) return const [];

    final list = (response as List)
        .map((e) => OrderHistoryModel.fromMap(
              Map<String, dynamic>.from(e as Map),
            ))
        .toList();

    return list;
  }

  /// ✅ Fetch single order detail (secure)
  Future<OrderDetailModel> fetchOrderDetail(String orderId) async {
    final user = supabase.auth.currentUser;

    if (user == null || user.isAnonymous) {
      throw Exception('User not signed in');
    }

    final data = await supabase
        .from('v_order_history')
        .select()
        .eq('id', orderId)
        .eq('user_id', user.id)
        .single();

    return OrderDetailModel.fromMap(
      Map<String, dynamic>.from(data),
    );
  }

  /// ✅ Fetch order items (secure + validated)
  Future<List<OrderItemModel>> fetchOrderItems(String orderId) async {
    final user = supabase.auth.currentUser;

    if (user == null || user.isAnonymous) {
      return const <OrderItemModel>[];
    }

    /// Verify ownership (important for security)
    final orderExists = await supabase
        .from('orders')
        .select('id')
        .eq('id', orderId)
        .eq('user_id', user.id)
        .maybeSingle();

    if (orderExists == null) {
      throw Exception('Order not found');
    }

    final response =
        await supabase.from('order_items').select().eq('order_id', orderId);

    if (response == null) return const [];

    final list = (response as List)
        .map((e) => OrderItemModel.fromMap(
              Map<String, dynamic>.from(e as Map),
            ))
        .toList();

    return list;
  }

  Future<void> cancelOrder(String orderId) async {
    final user = supabase.auth.currentUser;

    if (user == null || user.isAnonymous) {
      throw Exception('User not signed in');
    }

    await supabase.rpc(
      'cancel_order_atomic',
      params: {'p_order_id': orderId},
    );
  }
}
