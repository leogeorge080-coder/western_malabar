import 'package:western_malabar/features/profile/models/profile_model.dart';

class AccessState {
  final AppRole role;
  final Set<String> roles;
  final bool isFallbackAdmin;
  final bool isProfileLoaded;
  final bool isSignedIn;

  const AccessState({
    required this.role,
    required this.roles,
    required this.isFallbackAdmin,
    required this.isProfileLoaded,
    required this.isSignedIn,
  });

  bool get isAdmin => roles.contains('admin') || isFallbackAdmin;

  bool get isDelivery => roles.contains('driver');

  bool get isSeller => roles.contains('seller');

  bool get canAccessAdmin => isAdmin;

  bool get canAccessDelivery => roles.contains('driver');

  bool get canAccessSeller => roles.contains('seller');

  String get effectiveRoleLabel {
    if (isAdmin) return 'Admin';
    if (isDelivery) return 'Driver';
    if (isSeller) return 'Seller';
    return 'Customer';
  }

  AppRole get effectiveRole {
    if (isAdmin) return AppRole.admin;
    if (isDelivery) return AppRole.delivery;
    if (isSeller) return AppRole.seller;
    return AppRole.customer;
  }
}
