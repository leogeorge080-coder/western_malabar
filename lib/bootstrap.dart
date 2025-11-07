import 'package:supabase_flutter/supabase_flutter.dart';
import 'env.dart';

class AppSupabase {
  static Future<void> init() async {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
