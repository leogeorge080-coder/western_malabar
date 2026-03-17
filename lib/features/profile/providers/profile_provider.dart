import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:western_malabar/features/profile/models/profile_model.dart';
import 'package:western_malabar/features/profile/services/profile_service.dart';

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService();
});

final profileProvider = FutureProvider<ProfileModel>((ref) async {
  final service = ref.read(profileServiceProvider);
  return service.fetchProfile();
});

final currentUserRoleProvider = Provider<AppRole>((ref) {
  final profile = ref.watch(profileProvider).maybeWhen(
        data: (profile) => profile,
        orElse: () => null,
      );

  return profile?.role ?? AppRole.customer;
});

final canAccessDeliveryProvider = Provider<bool>((ref) {
  final role = ref.watch(currentUserRoleProvider);
  return role.canAccessDelivery;
});

final canAccessAdminProvider = Provider<bool>((ref) {
  final role = ref.watch(currentUserRoleProvider);
  return role.canAccessAdmin;
});




