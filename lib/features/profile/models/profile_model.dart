enum AppRole {
  customer,
  delivery,
  admin,
  seller;

  static AppRole fromRaw(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'admin':
        return AppRole.admin;
      case 'delivery':
        return AppRole.delivery;
      case 'seller':
        return AppRole.seller;
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
  bool get isSeller => this == AppRole.seller;

  bool get canAccessDelivery => this == AppRole.delivery;

  bool get canAccessAdmin => this == AppRole.admin;

  bool get canAccessSeller => this == AppRole.seller;

  String get label {
    switch (this) {
      case AppRole.customer:
        return 'Customer';
      case AppRole.delivery:
        return 'Delivery';
      case AppRole.admin:
        return 'Admin';
      case AppRole.seller:
        return 'Seller';
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
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return 'U';

    final parts =
        trimmed.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
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
  bool get isSeller => role.isSeller;

  bool get canAccessDelivery => role.canAccessDelivery;
  bool get canAccessAdmin => role.canAccessAdmin;
  bool get canAccessSeller => role.canAccessSeller;

  static const int rewardBlockPoints = 200;
  static const int rewardBlockValuePence = 200;
  static const int pointsPerPoundEarned = 3;
  static const int nextUnlockSpendTargetPence = 2500;

  int get rewardWalletValuePence {
    return ((rewardPoints / rewardBlockPoints) * rewardBlockValuePence).floor();
  }

  String get rewardWalletFormatted {
    return _formatMoney(rewardWalletValuePence);
  }

  int get unlockedRewardBlocks {
    return rewardPoints ~/ rewardBlockPoints;
  }

  int get readyRewardValuePence {
    return unlockedRewardBlocks * rewardBlockValuePence;
  }

  String get readyRewardFormatted {
    return _formatMoney(readyRewardValuePence);
  }

  int get pointsNeededToUnlockNext {
    if (rewardPoints == 0) return rewardBlockPoints;
    final mod = rewardPoints % rewardBlockPoints;
    if (mod == 0) return 0;
    return rewardBlockPoints - mod;
  }

  int get estimatedProgressSpendPence {
    final estimatedPounds = rewardPoints / pointsPerPoundEarned;
    return (estimatedPounds * 100).round().clamp(0, nextUnlockSpendTargetPence);
  }

  int get remainingSpendToNextUnlockPence {
    final remaining = nextUnlockSpendTargetPence - estimatedProgressSpendPence;
    return remaining < 0 ? 0 : remaining;
  }

  double get nextUnlockSpendProgress {
    if (nextUnlockSpendTargetPence <= 0) return 0;
    return (estimatedProgressSpendPence / nextUnlockSpendTargetPence)
        .clamp(0.0, 1.0);
  }

  String get nextUnlockTargetFormatted {
    return _formatMoney(nextUnlockSpendTargetPence);
  }

  String get estimatedProgressSpendFormatted {
    return _formatMoney(estimatedProgressSpendPence);
  }

  String get remainingSpendToNextUnlockFormatted {
    return _formatMoney(remainingSpendToNextUnlockPence);
  }

  String get nextRewardValueFormatted {
    return _formatMoney(rewardBlockValuePence);
  }

  String get rewardHeadline {
    if (unlockedRewardBlocks > 0) {
      return 'You already have $readyRewardFormatted ready to use';
    }
    return 'Only $pointsNeededToUnlockNext more points to unlock $nextRewardValueFormatted';
  }

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

  static String _formatMoney(int pence) {
    return '£${(pence / 100).toStringAsFixed(2)}';
  }
}
