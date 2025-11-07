import 'package:supabase_flutter/supabase_flutter.dart';
import 'env.dart';

/// Centralized Supabase bootstrap used across the app.
/// Safe to call multiple times (hot reload, etc.) — it will no-op after the first init.
class AppSupabase {
  static bool _inited = false;

  /// Initialize Supabase once.
  static Future<void> init() async {
    if (_inited) return;
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,

      // If you later add sign-in, uncomment PKCE:
      // authFlowType: AuthFlowType.pkce,
    );
    _inited = true;
  }

  static SupabaseClient get client => Supabase.instance.client;
}
