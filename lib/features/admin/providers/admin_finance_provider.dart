import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:western_malabar/features/admin/models/admin_finance_model.dart';
import 'package:western_malabar/features/admin/services/admin_finance_service.dart';

final adminFinanceServiceProvider = Provider<AdminFinanceService>((ref) {
  return AdminFinanceService(Supabase.instance.client);
});

final adminFinanceDateRangeProvider =
    StateProvider<AdminFinanceDateRange>((ref) {
  return AdminFinanceDateRange.thisWeek();
});

final adminFinanceDashboardProvider =
    FutureProvider<AdminFinanceDashboardData>((ref) async {
  final range = ref.watch(adminFinanceDateRangeProvider);
  return ref.read(adminFinanceServiceProvider).fetchDashboard(
        start: range.start,
        end: range.end,
      );
});

final adminSellerPayoutsProvider =
    FutureProvider<List<SellerPayoutModel>>((ref) async {
  final range = ref.watch(adminFinanceDateRangeProvider);
  return ref.read(adminFinanceServiceProvider).fetchPayouts(
        start: range.start,
        end: range.end,
      );
});
