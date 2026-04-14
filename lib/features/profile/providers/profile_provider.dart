import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:western_malabar/features/profile/models/profile_model.dart';
import 'package:western_malabar/features/profile/services/profile_service.dart';

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService();
});

final authStateProvider = StreamProvider.autoDispose<AuthState>((ref) {
  final supabase = Supabase.instance.client;
  final controller = StreamController<AuthState>();

  final sub = supabase.auth.onAuthStateChange.listen(controller.add);

  ref.onDispose(() async {
    await sub.cancel();
    await controller.close();
  });

  return controller.stream;
});

final currentUserProvider = Provider.autoDispose<User?>((ref) {
  ref.watch(authStateProvider);
  return Supabase.instance.client.auth.currentUser;
});

final profileProvider = FutureProvider.autoDispose<ProfileModel?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final service = ref.read(profileServiceProvider);
  return service.fetchProfile();
});

final currentUserRoleProvider = Provider.autoDispose<AppRole>((ref) {
  final profile = ref.watch(profileProvider).maybeWhen(
        data: (profile) => profile,
        orElse: () => null,
      );

  return profile?.role ?? AppRole.customer;
});

final canAccessDeliveryProvider = Provider.autoDispose<bool>((ref) {
  final role = ref.watch(currentUserRoleProvider);
  return role.canAccessDelivery;
});

final canAccessAdminProvider = Provider.autoDispose<bool>((ref) {
  final role = ref.watch(currentUserRoleProvider);
  return role.canAccessAdmin;
});
