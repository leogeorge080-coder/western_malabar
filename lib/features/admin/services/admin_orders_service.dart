import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:western_malabar/features/admin/models/admin_order_item_model.dart';
import 'package:western_malabar/features/admin/models/admin_order_model.dart';

class BarcodePickResult {
  final bool success;
  final String message;
  final String? matchedItemId;
  final bool? isFrozen;

  const BarcodePickResult({
    required this.success,
    required this.message,
    this.matchedItemId,
    this.isFrozen,
  });
}

class AdminOrdersService {
  final SupabaseClient supabase;

  AdminOrdersService(this.supabase);

  Future<List<AdminOrderModel>> fetchRecentOrders() async {
    final rows = await supabase.from('orders').select('''
        id,
        order_number,
        customer_name,
        customer_email,
        phone,
        address_line1,
        address_line2,
        city,
        postcode,
        latitude,
        longitude,
        delivery_slot,
        payment_method,
        payment_status,
        status,
        admin_status,
        delivery_status,
        total_cents,
        has_frozen_items,
        printed_label_count,
        freezer_status,
        created_at,
        out_for_delivery_at,
        delivered_at
      ''').order('created_at', ascending: false).limit(50);

    return (rows as List)
        .map((e) => AdminOrderModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<AdminOrderModel> fetchOrder(String orderId) async {
    final row = await supabase.from('orders').select('''
        id,
        order_number,
        customer_name,
        customer_email,
        phone,
        address_line1,
        address_line2,
        city,
        postcode,
        latitude,
        longitude,
        delivery_slot,
        payment_method,
        payment_status,
        status,
        admin_status,
        delivery_status,
        total_cents,
        has_frozen_items,
        printed_label_count,
        freezer_status,
        created_at,
        out_for_delivery_at,
        delivered_at
      ''').eq('id', orderId).single();

    return AdminOrderModel.fromMap(row);
  }

  Future<void> _sendOrderStatusEmail({
    required String email,
    required String customerName,
    required String orderNumber,
    required String statusTitle,
    required String statusMessage,
  }) async {
    final response = await supabase.functions.invoke(
      'send-order-status-email',
      body: {
        'email': email,
        'customerName': customerName,
        'orderNumber': orderNumber,
        'statusTitle': statusTitle,
        'statusMessage': statusMessage,
      },
    );

    if (response.status != 200) {
      throw Exception(
        'Status email failed: ${response.status} ${response.data}',
      );
    }
  }

  Future<List<AdminOrderItemModel>> fetchOrderItems(String orderId) async {
    final rows = await supabase
        .from('order_items')
        .select('''
          id,
          order_id,
          product_id,
          product_name,
          brand_name,
          image,
          qty,
          unit_price_cents,
          line_total_cents,
          is_frozen,
          picking_status,
          picked_qty,
          packed_qty,
          picked_at,
          packed_at
        ''')
        .eq('order_id', orderId)
        .order('is_frozen', ascending: true)
        .order('product_name', ascending: true);

    return (rows as List)
        .map((e) => AdminOrderItemModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> startPicking(String orderId) async {
    await supabase.from('orders').update({
      'admin_status': 'picking',
    }).eq('id', orderId);
  }

  Future<BarcodePickResult> verifyManualBarcodeForOrder({
    required String orderId,
    required String barcode,
  }) async {
    final cleanBarcode = barcode.trim();

    if (cleanBarcode.isEmpty) {
      return const BarcodePickResult(
        success: false,
        message: 'Please enter a barcode',
      );
    }

    final itemRows = await supabase.from('order_items').select('''
          id,
          order_id,
          product_id,
          product_name,
          qty,
          is_frozen,
          picked_qty,
          packed_qty,
          barcode
        ''').eq('order_id', orderId).eq('barcode', cleanBarcode).limit(1);

    if ((itemRows as List).isEmpty) {
      return const BarcodePickResult(
        success: false,
        message: 'This barcode does not match any item in this order',
      );
    }

    final item = itemRows.first;
    final itemId = item['id'].toString();
    final qty = (item['qty'] as num?)?.toInt() ?? 0;
    final pickedQty = (item['picked_qty'] as num?)?.toInt() ?? 0;
    final isFrozen = item['is_frozen'] as bool? ?? false;
    final productName = (item['product_name'] as String?) ?? 'Unknown item';

    if (pickedQty >= qty) {
      return BarcodePickResult(
        success: false,
        message: 'Required quantity already completed for $productName',
        matchedItemId: itemId,
        isFrozen: isFrozen,
      );
    }

    final nextPickedQty = pickedQty + 1;
    final isComplete = nextPickedQty >= qty;

    await supabase.from('order_items').update({
      'picked_qty': nextPickedQty,
      'picked_at': DateTime.now().toIso8601String(),
      'picking_status': isComplete ? 'picked' : 'partial',
    }).eq('id', itemId);

    final allItems = await supabase
        .from('order_items')
        .select('qty, picked_qty')
        .eq('order_id', orderId);

    final allPicked = (allItems as List).every((row) {
      final map = row as Map<String, dynamic>;
      final qty = (map['qty'] as num?)?.toInt() ?? 0;
      final picked = (map['picked_qty'] as num?)?.toInt() ?? 0;
      return picked >= qty;
    });

    await supabase.from('orders').update({
      'status': allPicked ? 'picked' : 'picking',
      'admin_status': allPicked ? 'picked' : 'picking',
    }).eq('id', orderId);

    return BarcodePickResult(
      success: true,
      message: isFrozen
          ? '$productName verified and moved to freezer staging ($nextPickedQty / $qty)'
          : '$productName verified and picked ($nextPickedQty / $qty)',
      matchedItemId: itemId,
      isFrozen: isFrozen,
    );
  }

  Future<void> markOrderPacked({
    required String orderId,
    required bool hasFrozenItems,
  }) async {
    final now = DateTime.now().toIso8601String();

    await supabase.from('orders').update({
      'admin_status': hasFrozenItems ? 'frozen_staged' : 'packed',
      'status': 'packed',
      'packed_at': now,
      'freezer_status':
          hasFrozenItems ? 'moved_to_order_freezer' : 'not_required',
    }).eq('id', orderId);

    final itemRows = await supabase
        .from('order_items')
        .select('id, qty')
        .eq('order_id', orderId);

    for (final row in (itemRows as List)) {
      final map = row as Map<String, dynamic>;
      final itemId = map['id'] as String;
      final qty = (map['qty'] as num?)?.toInt() ?? 0;

      await supabase.from('order_items').update({
        'picking_status': 'packed',
        'packed_qty': qty,
        'packed_at': now,
      }).eq('id', itemId);
    }
  }

  Future<void> markOrderOutForDelivery({
    required String orderId,
  }) async {
    final order = await supabase
        .from('orders')
        .select('order_number, customer_name, customer_email')
        .eq('id', orderId)
        .single();

    final now = DateTime.now().toIso8601String();

    await supabase.from('orders').update({
      'delivery_status': 'out_for_delivery',
      'status': 'out_for_delivery',
      'out_for_delivery_at': now,
    }).eq('id', orderId);

    final email = (order['customer_email'] as String?)?.trim();
    final customerName =
        ((order['customer_name'] as String?) ?? '').trim().isEmpty
            ? 'Customer'
            : (order['customer_name'] as String).trim();
    final orderNumber =
        ((order['order_number'] as String?) ?? '').trim().isEmpty
            ? orderId
            : (order['order_number'] as String).trim();

    if (email != null && email.isNotEmpty) {
      try {
        await _sendOrderStatusEmail(
          email: email,
          customerName: customerName,
          orderNumber: orderNumber,
          statusTitle: 'Out for delivery',
          statusMessage:
              'Your order is now out for delivery and should reach you soon.',
        );
      } catch (e) {
        // Do not block delivery flow if email fails.
      }
    }
  }

  Future<void> markOrderDelivered({
    required String orderId,
  }) async {
    final order = await supabase
        .from('orders')
        .select('order_number, customer_name, customer_email')
        .eq('id', orderId)
        .single();

    final now = DateTime.now().toIso8601String();

    await supabase.from('orders').update({
      'delivery_status': 'delivered',
      'status': 'delivered',
      'admin_status': 'delivered',
      'delivered_at': now,
    }).eq('id', orderId);

    final email = (order['customer_email'] as String?)?.trim();
    final customerName =
        ((order['customer_name'] as String?) ?? '').trim().isEmpty
            ? 'Customer'
            : (order['customer_name'] as String).trim();
    final orderNumber =
        ((order['order_number'] as String?) ?? '').trim().isEmpty
            ? orderId
            : (order['order_number'] as String).trim();

    if (email != null && email.isNotEmpty) {
      try {
        await _sendOrderStatusEmail(
          email: email,
          customerName: customerName,
          orderNumber: orderNumber,
          statusTitle: 'Order delivered',
          statusMessage:
              'Your order has been delivered successfully. Thank you for shopping with Malabar Hub.',
        );
      } catch (e) {
        // Do not block delivery flow if email fails.
      }
    }
  }
}

final adminOrdersServiceProvider = Provider<AdminOrdersService>((ref) {
  return AdminOrdersService(Supabase.instance.client);
});
