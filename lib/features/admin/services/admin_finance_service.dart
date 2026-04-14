import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:western_malabar/features/admin/models/admin_finance_model.dart';

class AdminFinanceService {
  final SupabaseClient supabase;

  AdminFinanceService(this.supabase);

  String _dateOnly(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<AdminPlatformFinanceSummary> fetchPlatformSummary({
    required DateTime start,
    required DateTime end,
  }) async {
    final rows = await supabase.rpc(
      'get_platform_financial_summary',
      params: {
        '_start_date': _dateOnly(start),
        '_end_date': _dateOnly(end),
      },
    );

    final row = (rows as List).isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(rows.first as Map);

    return AdminPlatformFinanceSummary.fromMap(row);
  }

  Future<List<AdminSellerFinanceSummary>> fetchSellerSummaries({
    required DateTime start,
    required DateTime end,
  }) async {
    final rows = await supabase.rpc(
      'get_seller_financial_summary',
      params: {
        '_start_date': _dateOnly(start),
        '_end_date': _dateOnly(end),
      },
    );

    return (rows as List)
        .map((e) => AdminSellerFinanceSummary.fromMap(
              Map<String, dynamic>.from(e as Map),
            ))
        .toList();
  }

  Future<List<AdminOrderItemFinanceRow>> fetchRecentOrderItemFinancials({
    required DateTime start,
    required DateTime end,
    int limit = 20,
  }) async {
    final rows = await supabase.rpc(
      'get_order_item_financials',
      params: {
        '_start_date': _dateOnly(start),
        '_end_date': _dateOnly(end),
        '_limit': limit,
      },
    );

    return (rows as List)
        .map((e) => AdminOrderItemFinanceRow.fromMap(
              Map<String, dynamic>.from(e as Map),
            ))
        .toList();
  }

  Future<List<SellerPayoutModel>> fetchPayouts({
    required DateTime start,
    required DateTime end,
  }) async {
    final rows = await supabase
        .from('seller_payouts')
        .select()
        .lte('period_start', _dateOnly(end))
        .gte('period_end', _dateOnly(start))
        .order('created_at', ascending: false);

    return (rows as List)
        .map((e) => SellerPayoutModel.fromMap(
              Map<String, dynamic>.from(e as Map),
            ))
        .toList();
  }

  Future<void> createSellerPayout({
    required String sellerId,
    required DateTime periodStart,
    required DateTime periodEnd,
    required int amountCents,
    String? note,
  }) async {
    await supabase.rpc(
      'create_seller_payout',
      params: {
        '_seller_id': sellerId,
        '_period_start': _dateOnly(periodStart),
        '_period_end': _dateOnly(periodEnd),
        '_amount_cents': amountCents,
        '_note': note,
      },
    );
  }

  Future<void> markSellerPayoutPaid(String payoutId) async {
    await supabase.rpc(
      'mark_seller_payout_paid',
      params: {
        '_payout_id': payoutId,
      },
    );
  }

  Future<AdminFinanceDashboardData> fetchDashboard({
    required DateTime start,
    required DateTime end,
    int recentLimit = 20,
  }) async {
    final results = await Future.wait([
      fetchPlatformSummary(start: start, end: end),
      fetchSellerSummaries(start: start, end: end),
      fetchRecentOrderItemFinancials(
        start: start,
        end: end,
        limit: recentLimit,
      ),
    ]);

    return AdminFinanceDashboardData(
      platformSummary: results[0] as AdminPlatformFinanceSummary,
      sellerSummaries: results[1] as List<AdminSellerFinanceSummary>,
      recentRows: results[2] as List<AdminOrderItemFinanceRow>,
    );
  }
}
