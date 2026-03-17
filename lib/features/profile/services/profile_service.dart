import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:western_malabar/features/profile/models/profile_model.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<ProfileModel> fetchProfile() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User not signed in');
    }

    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) {
        return ProfileModel(
          id: user.id,
          fullName: user.userMetadata?['full_name'] as String? ?? 'User',
          email: user.email ?? '',
          phone: user.phone ?? '',
          rewardPoints: 0,
          nextRewardAt: 200,
          totalOrders: 0,
          savedAddresses: 0,
          isPremium: false,
          role: AppRole.customer,
        );
      }

      return ProfileModel(
        id: data['id'] as String? ?? user.id,
        fullName: data['full_name'] as String? ?? 'User',
        email: data['email'] as String? ?? user.email ?? '',
        phone: data['phone'] as String? ?? user.phone ?? '',
        rewardPoints: (data['reward_points'] as num?)?.toInt() ?? 0,
        nextRewardAt: (data['next_reward_at'] as num?)?.toInt() ?? 200,
        totalOrders: (data['total_orders'] as num?)?.toInt() ?? 0,
        savedAddresses: (data['saved_addresses'] as num?)?.toInt() ?? 0,
        isPremium: data['is_premium'] as bool? ?? false,
        role: AppRole.fromRaw(data['role'] as String?),
      );
    } catch (_) {
      return ProfileModel(
        id: user.id,
        fullName: user.userMetadata?['full_name'] as String? ?? 'User',
        email: user.email ?? '',
        phone: user.phone ?? '',
        rewardPoints: 0,
        nextRewardAt: 200,
        totalOrders: 0,
        savedAddresses: 0,
        isPremium: false,
        role: AppRole.customer,
      );
    }
  }
}
