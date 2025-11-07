class ProfileModel {
  final String id;
  final String email;
  final String? fullName;
  final bool isAdmin;
  final int rewardPoints;

  ProfileModel({
    required this.id,
    required this.email,
    this.fullName,
    required this.isAdmin,
    required this.rewardPoints,
  });

  factory ProfileModel.fromMap(Map<String, dynamic> m) => ProfileModel(
        id: m['id'],
        email: m['email'] ?? '',
        fullName: m['full_name'],
        isAdmin: m['is_admin'] ?? false,
        rewardPoints: m['reward_points'] ?? 0,
      );
}
