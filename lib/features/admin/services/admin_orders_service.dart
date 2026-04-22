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

class UndoPickResult {
  final String message;
  final String? orderItemId;

  const UndoPickResult({
    required this.message,
    this.orderItemId,
  });
}

class AdminOrdersService {
  final SupabaseClient supabase;

  AdminOrdersService(this.supabase);

  String _normalizeBackendError(Object error) {
    final raw = error.toString().trim();
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length).trim();
    }
    return raw;
  }

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
          short_pick_qty,
          short_pick_reason,
          packed_qty,
          picked_at,
          short_picked_at,
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
    try {
      final raw = await supabase.rpc(
        'start_order_picking_atomic',
        params: {
          'p_order_id': orderId,
        },
      );

      if (raw == null || raw is! Map || raw['ok'] != true) {
        throw Exception('Could not start picking for this order');
      }
    } catch (e) {
      throw Exception(_normalizeBackendError(e));
    }
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

    try {
      final raw = await supabase.rpc(
        'scan_order_item_barcode_atomic',
        params: {
          'p_order_id': orderId,
          'p_barcode': cleanBarcode,
        },
      );

      if (raw == null || raw is! Map || raw['ok'] != true) {
        return const BarcodePickResult(
          success: false,
          message: 'Barcode verification failed',
        );
      }

      final itemId = raw['matched_item_id']?.toString();
      final productName = (raw['product_name'] as String?) ?? 'Unknown item';
      final qty = (raw['qty'] as num?)?.toInt() ?? 0;
      final pickedQty = (raw['picked_qty'] as num?)?.toInt() ?? 0;
      final isFrozen = raw['is_frozen'] as bool? ?? false;

      return BarcodePickResult(
        success: true,
        message: isFrozen
            ? '$productName verified and moved to freezer staging ($pickedQty / $qty)'
            : '$productName verified and picked ($pickedQty / $qty)',
        matchedItemId: itemId,
        isFrozen: isFrozen,
      );
    } catch (e) {
      return BarcodePickResult(
        success: false,
        message: _normalizeBackendError(e),
      );
    }
  }

  Future<void> markOrderPacked({
    required String orderId,
    required bool hasFrozenItems,
  }) async {
    final raw = await supabase.rpc(
      'mark_order_packed_atomic',
      params: {
        'p_order_id': orderId,
      },
    );

    if (raw == null || raw is! Map || raw['ok'] != true) {
      throw Exception('Could not mark this order as packed');
    }
  }

  Future<UndoPickResult> undoLastScan(String orderId) async {
    try {
      final raw = await supabase.rpc(
        'undo_last_order_item_scan_atomic',
        params: {
          'p_order_id': orderId,
        },
      );

      if (raw == null || raw is! Map || raw['ok'] != true) {
        throw Exception('Could not undo the last scan');
      }

      final productName = (raw['product_name'] as String?) ?? 'Item';
      final pickedQty = (raw['picked_qty'] as num?)?.toInt() ?? 0;
      final qty = (raw['qty'] as num?)?.toInt() ?? 0;

      return UndoPickResult(
        message: '$productName scan undone ($pickedQty / $qty)',
        orderItemId: raw['order_item_id']?.toString(),
      );
    } catch (e) {
      throw Exception(_normalizeBackendError(e));
    }
  }

  Future<void> shortPickOrderItem({
    required String orderId,
    required String orderItemId,
    required int shortPickQty,
    required String reason,
  }) async {
    try {
      final raw = await supabase.rpc(
        'short_pick_order_item_atomic',
        params: {
          'p_order_id': orderId,
          'p_order_item_id': orderItemId,
          'p_short_pick_qty': shortPickQty,
          'p_reason': reason,
        },
      );

      if (raw == null || raw is! Map || raw['ok'] != true) {
        throw Exception('Could not short-pick this item');
      }
    } catch (e) {
      throw Exception(_normalizeBackendError(e));
    }
  }

  Future<void> reopenPartiallyPickedOrder(String orderId) async {
    try {
      final raw = await supabase.rpc(
        'reopen_partially_picked_order_atomic',
        params: {
          'p_order_id': orderId,
        },
      );

      if (raw == null || raw is! Map || raw['ok'] != true) {
        throw Exception('Could not reopen this picking session');
      }
    } catch (e) {
      throw Exception(_normalizeBackendError(e));
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

    final raw = await supabase.rpc(
      'mark_order_out_for_delivery_atomic',
      params: {
        'p_order_id': orderId,
      },
    );

    if (raw == null || raw is! Map || raw['ok'] != true) {
      throw Exception('Could not mark this order as out for delivery');
    }

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

    final raw = await supabase.rpc(
      'mark_order_delivered_atomic',
      params: {
        'p_order_id': orderId,
      },
    );

    if (raw == null || raw is! Map || raw['ok'] != true) {
      throw Exception('Could not mark this order as delivered');
    }

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
