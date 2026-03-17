import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:western_malabar/state/cart_provider.dart';
import '../models/checkout_address.dart';

class PlacedOrderResult {
  final String orderId;
  final String orderNumber;
  final String qrCodeValue;

  const PlacedOrderResult({
    required this.orderId,
    required this.orderNumber,
    required this.qrCodeValue,
  });
}

class CheckoutService {
  final SupabaseClient supabase;

  CheckoutService(this.supabase);

  Future<PlacedOrderResult> placeOrder({
    required CheckoutAddress address,
    required String deliveryType,
    required String deliverySlot,
    required String paymentMethod,
    required int subtotalCents,
    required int deliveryFeeCents,
    required int totalCents,
    required List<CartItem> cartItems,
    String? paymentStatus,
    String? stripePaymentIntentId,
    double? latitude,
    double? longitude,
  }) async {
    try {
      debugPrint('--- PLACE ORDER START ---');

      if (cartItems.isEmpty) {
        throw Exception('Cannot place order with empty cart');
      }

      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception('User session lost before order placement');
      }

      final hasFrozenItems = _detectFrozenItems(cartItems);
      final effectivePaymentStatus =
          paymentStatus ?? _defaultPaymentStatus(paymentMethod);

      debugPrint('CHECKOUT USER ID: ${supabase.auth.currentUser?.id}');
      debugPrint(
          'CHECKOUT SESSION EXISTS: ${supabase.auth.currentSession != null}');
      debugPrint('paymentMethod=$paymentMethod');
      debugPrint('paymentStatus=$paymentStatus');
      debugPrint('stripePaymentIntentId=$stripePaymentIntentId');
      debugPrint('latitude=$latitude');
      debugPrint('longitude=$longitude');

      final orderInsertPayload = <String, dynamic>{
        'user_id': user.id,
        ...address.toMap(),
        'status': 'placed',
        'admin_status': 'pending',
        'delivery_type': deliveryType,
        'delivery_slot': deliverySlot,
        'payment_method': paymentMethod,
        'payment_status': effectivePaymentStatus,
        'subtotal_cents': subtotalCents,
        'delivery_fee_cents': deliveryFeeCents,
        'total_cents': totalCents,
        'has_frozen_items': hasFrozenItems,
        'freezer_status':
            hasFrozenItems ? 'pending_freezer_pick' : 'not_required',
        if (stripePaymentIntentId != null)
          'stripe_payment_intent_id': stripePaymentIntentId,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };

      final orderRow = await supabase
          .from('orders')
          .insert(orderInsertPayload)
          .select('id, created_at')
          .single();

      final orderId = orderRow['id'] as String;
      final createdAtRaw = orderRow['created_at'];

      debugPrint('Order row inserted. orderId=$orderId');

      final orderNumber = _generateOrderNumber(
        orderId: orderId,
        createdAtRaw: createdAtRaw,
      );
      final qrCodeValue = 'WM|ORDER|$orderId|$orderNumber';

      await supabase.from('orders').update({
        'order_number': orderNumber,
        'qr_code_value': qrCodeValue,
      }).eq('id', orderId);

      debugPrint('Order number + QR saved. orderNumber=$orderNumber');

      final itemRows = cartItems.map((item) {
        final product = item.product;
        final unitPriceCents =
            product.salePriceCents ?? product.priceCents ?? 0;
        final isFrozen = product.isFrozen;

        return {
          'order_id': orderId,
          'product_id': product.id,
          'product_name': product.name,
          'brand_name': product.brandName,
          'image': product.image,
          'unit_price_cents': unitPriceCents,
          'qty': item.qty,
          'line_total_cents': unitPriceCents * item.qty,
          'picking_status': 'pending',
          'is_frozen': isFrozen,
        };
      }).toList();

      if (itemRows.isNotEmpty) {
        await supabase.from('order_items').insert(itemRows);
        debugPrint('Order items inserted. count=${itemRows.length}');
      }

      return PlacedOrderResult(
        orderId: orderId,
        orderNumber: orderNumber,
        qrCodeValue: qrCodeValue,
      );
    } catch (e, st) {
      debugPrint('PLACE ORDER FAILED: $e');
      debugPrint('$st');
      rethrow;
    }
  }

  String _defaultPaymentStatus(String paymentMethod) {
    switch (paymentMethod) {
      case 'card':
        return 'paid';
      case 'cod':
        return 'cod_pending';
      default:
        return 'pending';
    }
  }

  bool _detectFrozenItems(List<CartItem> cartItems) {
    for (final item in cartItems) {
      if (item.product.isFrozen) {
        return true;
      }
    }
    return false;
  }

  String _generateOrderNumber({
    required String orderId,
    required dynamic createdAtRaw,
  }) {
    final createdAt = createdAtRaw is String
        ? DateTime.tryParse(createdAtRaw)?.toLocal()
        : DateTime.now();

    final dt = createdAt ?? DateTime.now();
    final yy = (dt.year % 100).toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    final suffix = orderId.replaceAll('-', '').substring(0, 6).toUpperCase();

    return 'MH-$yy$mm$dd-$suffix';
  }
}

Future<void> ensureSupabaseUser() async {
  final supabase = Supabase.instance.client;

  int attempts = 0;

  while (supabase.auth.currentUser == null && attempts < 10) {
    await Future.delayed(const Duration(milliseconds: 200));
    attempts++;
  }

  if (supabase.auth.currentUser == null) {
    throw Exception('Supabase user session not restored');
  }
}

final checkoutServiceProvider = Provider<CheckoutService>((ref) {
  return CheckoutService(Supabase.instance.client);
});
