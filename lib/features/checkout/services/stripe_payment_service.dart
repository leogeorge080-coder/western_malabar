import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:western_malabar/env.dart';

class StripePaymentResult {
  final String paymentIntentId;
  final String clientSecret;

  const StripePaymentResult({
    required this.paymentIntentId,
    required this.clientSecret,
  });
}

class StripePaymentService {
  const StripePaymentService();

  Future<StripePaymentResult> pay({
    required int amountCents,
    required String currency,
    required String customerName,
    required String customerPhone,
    required String customerEmail,
    required String orderLabel,
  }) async {
    final uri =
        Uri.parse('${Env.supabaseUrl}/functions/v1/create-payment-intent');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'apikey': Env.supabaseAnonKey,
        'Authorization': 'Bearer ${Env.supabaseAnonKey}',
      },
      body: jsonEncode({
        'amount': amountCents,
        'currency': currency,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'customerEmail': customerEmail,
        'orderLabel': orderLabel,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Payment init failed: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final clientSecret = data['clientSecret'] as String;
    final paymentIntentId = data['paymentIntentId'] as String;

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

        // Apple Pay only works on iOS
        // remove for Android builds

        googlePay: const PaymentSheetGooglePay(
          merchantCountryCode: 'GB',
          currencyCode: 'GBP',
          testEnv: true,
        ),
        billingDetails: BillingDetails(
          name: customerName,
          phone: customerPhone,
        ),
      ),
    );

    await Stripe.instance.presentPaymentSheet();

    return StripePaymentResult(
      paymentIntentId: paymentIntentId,
      clientSecret: clientSecret,
    );
  }
}
