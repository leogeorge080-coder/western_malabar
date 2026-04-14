import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:western_malabar/app/env.dart';
import 'package:western_malabar/features/cart/providers/cart_provider.dart';
import 'package:western_malabar/features/checkout/models/checkout_address.dart';

class StripePaymentResult {
  final String paymentIntentId;
  final String clientSecret;
  final int subtotalCents;
  final int deliveryFeeCents;
  final int rewardDiscountCents;
  final int totalCents;

  const StripePaymentResult({
    required this.paymentIntentId,
    required this.clientSecret,
    required this.subtotalCents,
    required this.deliveryFeeCents,
    required this.rewardDiscountCents,
    required this.totalCents,
  });
}

class StripePaymentService {
  const StripePaymentService();

  Future<StripePaymentResult> createCheckoutPaymentIntent({
    required CheckoutAddress address,
    String? addressId,
    required String deliveryType,
    required String deliverySlot,
    required String paymentMethod,
    required bool useRewards,
    required List<CartItem> cartItems,
  }) async {
    final session = Supabase.instance.client.auth.currentSession;
    final accessToken = session?.accessToken;

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('User session not available for payment');
    }

    final uri = Uri.parse(
      '${Env.supabaseUrl}/functions/v1/create-checkout-payment-intent',
    );

    final cartPayload = cartItems.map((item) {
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

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'apikey': Env.supabaseAnonKey,
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'address': {
          'full_name': address.fullName,
          'phone': address.phone,
          'postcode': address.postcode,
          'address_line1': address.addressLine1,
          'address_line2': address.addressLine2,
          'city': address.city,
        },
        'address_id': addressId,
        'delivery_type': deliveryType,
        'delivery_slot': deliverySlot,
        'payment_method': paymentMethod,
        'use_rewards': useRewards,
        'cart_items': cartPayload,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Payment init failed: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    final clientSecret = (data['clientSecret'] ?? '').toString();
    final paymentIntentId = (data['paymentIntentId'] ?? '').toString();

    if (clientSecret.isEmpty || paymentIntentId.isEmpty) {
      throw Exception('Invalid payment intent response');
    }

    final subtotalCents = (data['subtotal_cents'] as num?)?.toInt() ?? 0;
    final deliveryFeeCents = (data['delivery_fee_cents'] as num?)?.toInt() ?? 0;
    final rewardDiscountCents =
        (data['reward_discount_cents'] as num?)?.toInt() ?? 0;
    final totalCents = (data['total_cents'] as num?)?.toInt() ?? 0;

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        merchantDisplayName: 'Malabar Hub',
        paymentIntentClientSecret: clientSecret,
        style: ThemeMode.light,
        appearance: const PaymentSheetAppearance(
          colors: PaymentSheetAppearanceColors(
            primary: Color(0xFF5A2D82),
          ),
        ),
        googlePay: PaymentSheetGooglePay(
          merchantCountryCode: 'GB',
          currencyCode: 'GBP',
          testEnv: kDebugMode,
        ),
        billingDetails: BillingDetails(
          name: address.fullName,
          phone: address.phone,
        ),
      ),
    );

    await Stripe.instance.presentPaymentSheet();

    return StripePaymentResult(
      paymentIntentId: paymentIntentId,
      clientSecret: clientSecret,
      subtotalCents: subtotalCents,
      deliveryFeeCents: deliveryFeeCents,
      rewardDiscountCents: rewardDiscountCents,
      totalCents: totalCents,
    );
  }
}
