import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:western_malabar/features/auth/services/auth_service.dart';
import 'package:western_malabar/features/profile/providers/profile_provider.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(Supabase.instance.client);
});

final authUserProvider = Provider<User?>((ref) {
  return ref.watch(currentUserProvider);
});
