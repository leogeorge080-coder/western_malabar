import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:western_malabar/features/auth/screens/checkout_login_gate_sheet.dart';

Future<bool> requireCheckoutLogin(BuildContext context) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user != null) return true;

  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const CheckoutLoginGateSheet(),
  );

  return result == true;
}
