enum AppRole {
  customer,
  delivery,
  admin;

  static AppRole fromRaw(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'admin':
        return AppRole.admin;
      case 'delivery':
        return AppRole.delivery;
      case 'customer':
      default:
        return AppRole.customer;
    }
  }
}

extension AppRoleX on AppRole {
  bool get isCustomer => this == AppRole.customer;
  bool get isDelivery => this == AppRole.delivery;
  bool get isAdmin => this == AppRole.admin;

  bool get canAccessDelivery =>
      this == AppRole.delivery || this == AppRole.admin;

  bool get canAccessAdmin => this == AppRole.admin;

  String get label {
    switch (this) {
      case AppRole.customer:
        return 'Customer';
      case AppRole.delivery:
        return 'Delivery';
      case AppRole.admin:
        return 'Admin';
    }
  }
}

class ProfileModel {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final int rewardPoints;
  final int nextRewardAt;
  final int totalOrders;
  final int savedAddresses;
  final bool isPremium;
  final AppRole role;

  const ProfileModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.rewardPoints,
    required this.nextRewardAt,
    required this.totalOrders,
    required this.savedAddresses,
    required this.isPremium,
    this.role = AppRole.customer,
  });

  double get rewardProgress {
    if (nextRewardAt <= 0) return 0;
    return (rewardPoints / nextRewardAt).clamp(0.0, 1.0);
  }

  int get remainingToNextReward {
    final remaining = nextRewardAt - rewardPoints;
    return remaining < 0 ? 0 : remaining;
  }

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  bool get isCustomer => role.isCustomer;
  bool get isDelivery => role.isDelivery;
  bool get isAdmin => role.isAdmin;
  bool get canAccessDelivery => role.canAccessDelivery;
  bool get canAccessAdmin => role.canAccessAdmin;

  ProfileModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    int? rewardPoints,
    int? nextRewardAt,
    int? totalOrders,
    int? savedAddresses,
    bool? isPremium,
    AppRole? role,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      nextRewardAt: nextRewardAt ?? this.nextRewardAt,
      totalOrders: totalOrders ?? this.totalOrders,
      savedAddresses: savedAddresses ?? this.savedAddresses,
      isPremium: isPremium ?? this.isPremium,
      role: role ?? this.role,
    );
  }
}
