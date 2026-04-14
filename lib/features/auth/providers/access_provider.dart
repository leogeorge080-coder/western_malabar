import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:western_malabar/features/auth/models/access_state.dart';
import 'package:western_malabar/features/auth/providers/auth_provider.dart';
import 'package:western_malabar/features/profile/models/profile_model.dart';
import 'package:western_malabar/features/profile/providers/profile_provider.dart';

final userRolesProvider = FutureProvider<Set<String>>((ref) async {
  final User? authUser = ref.watch(authUserProvider);

  if (authUser == null) {
    return <String>{};
  }

  final supabase = Supabase.instance.client;

  final rows = await supabase
      .from('user_roles')
      .select('role')
      .eq('user_id', authUser.id);

  return (rows as List)
      .map((e) => (e as Map<String, dynamic>)['role']?.toString() ?? '')
      .map((e) => e.trim().toLowerCase())
      .where((e) => e.isNotEmpty)
      .toSet();
});

final accessStateProvider = Provider<AccessState>((ref) {
  final User? authUser = ref.watch(authUserProvider);
  final profileAsync = ref.watch(profileProvider);
  final rolesAsync = ref.watch(userRolesProvider);

  final profile = profileAsync.maybeWhen(
    data: (profile) => profile,
    orElse: () => null,
  );

  final roles = rolesAsync.maybeWhen(
    data: (roles) => roles,
    orElse: () => <String>{},
  );

  final AppRole resolvedRole;
  if (roles.contains('admin')) {
    resolvedRole = AppRole.admin;
  } else if (roles.contains('driver')) {
    resolvedRole = AppRole.delivery;
  } else if (roles.contains('seller')) {
    resolvedRole = AppRole.seller;
  } else {
    resolvedRole = AppRole.customer;
  }

  return AccessState(
    role: resolvedRole,
    roles: roles,
    isFallbackAdmin: false,
    isProfileLoaded: profile != null,
    isSignedIn: authUser != null,
  );
});

final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(accessStateProvider).canAccessAdmin;
});

final canAccessDeliveryProvider = Provider<bool>((ref) {
  return ref.watch(accessStateProvider).canAccessDelivery;
});

final canAccessSellerProvider = Provider<bool>((ref) {
  return ref.watch(accessStateProvider).canAccessSeller;
});
