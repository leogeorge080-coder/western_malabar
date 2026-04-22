import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:western_malabar/app/env.dart';
import 'package:western_malabar/features/cart/providers/cart_provider.dart';
import 'package:western_malabar/features/checkout/models/checkout_address.dart';

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

  void _logDebug(String message) {
    if (kDebugMode) debugPrint(message);
  }

  Future<PlacedOrderResult> placeOrder({
    required CheckoutAddress address,
    required String checkoutEmail,
    String? addressId,
    required String deliveryType,
    required String deliverySlot,
    required String paymentMethod,
    required List<CartItem> cartItems,
    required bool useRewards,
    String? paymentStatus,
    String? stripePaymentIntentId,
    double? latitude,
    double? longitude,
  }) async {
    try {
      _logDebug('--- PLACE ORDER ATOMIC START ---');

      if (cartItems.isEmpty) {
        throw Exception('Cannot place order with empty cart');
      }

      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User session lost before order placement');
      }

      final effectivePaymentStatus =
          paymentStatus ?? _defaultPaymentStatus(paymentMethod);

      final safeAddressId = await _resolveValidAddressId(
        userId: user.id,
        addressId: addressId,
      );

      final cartPayload = _buildCartPayload(cartItems);

      final addressPayload = <String, dynamic>{
        'full_name': address.fullName,
        'phone': address.phone,
        'email': (checkoutEmail.isNotEmpty
            ? checkoutEmail
            : (supabase.auth.currentUser?.email ?? '')),
        'postcode': address.postcode,
        'address_line1': address.addressLine1,
        'address_line2': address.addressLine2,
        'city': address.city,
      };

      _logDebug('CHECKOUT USER ID: ${supabase.auth.currentUser?.id}');
      _logDebug(
        'CHECKOUT SESSION EXISTS: ${supabase.auth.currentSession != null}',
      );
      _logDebug('paymentMethod=$paymentMethod');
      _logDebug('paymentStatus=$effectivePaymentStatus');
      _logDebug('stripePaymentIntentId=$stripePaymentIntentId');
      _logDebug('latitude=$latitude');
      _logDebug('longitude=$longitude');
      _logDebug('incoming addressId=$addressId');
      _logDebug('safeAddressId=$safeAddressId');
      _logDebug('useRewards=$useRewards');
      _logDebug('cartItems=${cartPayload.length}');

      final raw = await supabase.rpc(
        'place_order_atomic',
        params: {
          'p_address': addressPayload,
          'p_address_id': safeAddressId,
          'p_delivery_type': deliveryType,
          'p_delivery_slot': deliverySlot,
          'p_payment_method': paymentMethod,
          'p_payment_status': effectivePaymentStatus,
          'p_stripe_payment_intent_id': stripePaymentIntentId,
          'p_use_rewards': useRewards,
          'p_cart_items': cartPayload,
        },
      );

      if (raw == null || raw is! Map) {
        throw Exception('Invalid response from place_order_atomic');
      }

      final result = Map<String, dynamic>.from(raw as Map);

      final orderId = (result['order_id'] ?? '').toString();
      final orderNumber = (result['order_number'] ?? '').toString();
      final qrCodeValue = (result['qr_code_value'] ?? '').toString();

      if (orderId.isEmpty || orderNumber.isEmpty || qrCodeValue.isEmpty) {
        throw Exception('Incomplete order response from backend');
      }

      _logDebug('ATOMIC ORDER SUCCESS orderId=$orderId');
      _logDebug('ATOMIC ORDER SUCCESS orderNumber=$orderNumber');
      _logDebug(
        'reward_discount_cents=${result['reward_discount_cents']} '
        'points_redeemed=${result['points_redeemed']} '
        'total_cents=${result['total_cents']}',
      );

      return PlacedOrderResult(
        orderId: orderId,
        orderNumber: orderNumber,
        qrCodeValue: qrCodeValue,
      );
    } catch (e, st) {
      _logDebug('PLACE ORDER ATOMIC FAILED: $e');
      _logDebug('$st');
      rethrow;
    }
  }

  Future<PlacedOrderResult> placeOrderAfterPayment({
    required String paymentIntentId,
    required CheckoutAddress address,
    required String checkoutEmail,
    String? addressId,
    required String deliveryType,
    required String deliverySlot,
    required String paymentMethod,
    required bool useRewards,
    required List<CartItem> cartItems,
  }) async {
    try {
      _logDebug('--- PLACE ORDER AFTER PAYMENT START ---');

      if (cartItems.isEmpty) {
        throw Exception('Cannot place order with empty cart');
      }

      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User session lost before order placement');
      }

      final safeAddressId = await _resolveValidAddressId(
        userId: user.id,
        addressId: addressId,
      );

      final cartPayload = _buildCartPayload(cartItems);

      final addressPayload = <String, dynamic>{
        'full_name': address.fullName,
        'phone': address.phone,
        'email': (checkoutEmail.isNotEmpty
            ? checkoutEmail
            : (supabase.auth.currentUser?.email ?? '')),
        'postcode': address.postcode,
        'address_line1': address.addressLine1,
        'address_line2': address.addressLine2,
        'city': address.city,
      };

      final session = supabase.auth.currentSession;
      final accessToken = session?.accessToken;

      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('User session not available for order finalization');
      }

      final functionUrl =
          '${Env.supabaseUrl}/functions/v1/place-order-after-payment';

      final response = await http.post(
        Uri.parse(functionUrl),
        headers: {
          'Content-Type': 'application/json',
          'apikey': Env.supabaseAnonKey,
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'payment_intent_id': paymentIntentId,
          'address': addressPayload,
          'address_id': safeAddressId,
          'delivery_type': deliveryType,
          'delivery_slot': deliverySlot,
          'payment_method': paymentMethod,
          'use_rewards': useRewards,
          'cart_items': cartPayload,
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'place-order-after-payment failed: ${response.body}',
        );
      }

      final raw = jsonDecode(response.body);
      if (raw == null || raw is! Map) {
        throw Exception('Invalid response from place-order-after-payment');
      }

      final result = Map<String, dynamic>.from(raw as Map);

      final orderId = (result['order_id'] ?? '').toString();
      final orderNumber = (result['order_number'] ?? '').toString();
      final qrCodeValue = (result['qr_code_value'] ?? '').toString();

      if (orderId.isEmpty || orderNumber.isEmpty || qrCodeValue.isEmpty) {
        throw Exception('Incomplete order response from backend');
      }

      _logDebug('PLACE ORDER AFTER PAYMENT SUCCESS orderId=$orderId');
      _logDebug('PLACE ORDER AFTER PAYMENT SUCCESS orderNumber=$orderNumber');
      _logDebug(
        'reward_discount_cents=${result['reward_discount_cents']} '
        'points_redeemed=${result['points_redeemed']} '
        'total_cents=${result['total_cents']}',
      );

      return PlacedOrderResult(
        orderId: orderId,
        orderNumber: orderNumber,
        qrCodeValue: qrCodeValue,
      );
    } catch (e, st) {
      _logDebug('PLACE ORDER AFTER PAYMENT FAILED: $e');
      _logDebug('$st');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCheckoutSummary({
    required String deliveryType,
    required bool useRewards,
    required List<CartItem> cartItems,
    String? postcode,
  }) async {
    final cartPayload = _buildCartPayload(cartItems);

    final raw = await supabase.rpc(
      'get_checkout_summary_atomic',
      params: {
        'p_delivery_type': deliveryType,
        'p_use_rewards': useRewards,
        'p_cart_items': cartPayload,
        'p_postcode':
            postcode?.trim().isEmpty ?? true ? null : postcode?.trim(),
      },
    );

    if (raw == null || raw is! Map) {
      throw Exception('Invalid response from get_checkout_summary_atomic');
    }

    return Map<String, dynamic>.from(raw as Map);
  }

  List<Map<String, dynamic>> _buildCartPayload(List<CartItem> cartItems) {
    return cartItems.map((item) {
      final productId = item.product.id.trim();

      if (productId.isEmpty) {
        throw Exception('Missing product_id in cart');
      }

      if (item.qty <= 0) {
        throw Exception('Invalid quantity for product ${item.product.name}');
      }

      return <String, dynamic>{
        'product_id': productId,
        'qty': item.qty,
      };
    }).toList();
  }

  Future<String?> _resolveValidAddressId({
    required String userId,
    required String? addressId,
  }) async {
    final trimmed = addressId?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    final existing = await supabase
        .from('addresses')
        .select('id')
        .eq('id', trimmed)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing == null) {
      _logDebug(
        'Address id $trimmed not found in addresses for user $userId. Falling back to null.',
      );
      return null;
    }

    final resolvedId = existing['id'] as String?;
    if (resolvedId == null || resolvedId.isEmpty) {
      return null;
    }

    return resolvedId;
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
}

Future<void> ensureSupabaseUser() async {
  final supabase = Supabase.instance.client;

  // Already signed in or already anonymous.
  if (supabase.auth.currentUser != null) {
    return;
  }

  // Create anonymous guest session for checkout.
  final authResponse = await supabase.auth.signInAnonymously();

  if (authResponse.user != null) {
    return;
  }

  // Small fallback wait in case auth state is still propagating.
  int attempts = 0;
  while (supabase.auth.currentUser == null && attempts < 10) {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    attempts++;
  }

  if (supabase.auth.currentUser == null) {
    throw Exception('Could not create guest checkout session');
  }
}

final checkoutServiceProvider = Provider<CheckoutService>((ref) {
  return CheckoutService(Supabase.instance.client);
});
