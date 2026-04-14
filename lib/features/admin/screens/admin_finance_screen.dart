import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:western_malabar/features/admin/models/admin_finance_model.dart';
import 'package:western_malabar/features/admin/providers/admin_finance_provider.dart';
import 'package:western_malabar/shared/theme/theme.dart';
import 'package:western_malabar/shared/theme/wm_gradients.dart';

class AdminFinanceScreen extends ConsumerWidget {
  const AdminFinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final financeAsync = ref.watch(adminFinanceDashboardProvider);
    final payoutsAsync = ref.watch(adminSellerPayoutsProvider);
    final range = ref.watch(adminFinanceDateRangeProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: WMGradients.pageBackground,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    const Expanded(
                      child: Text(
                        'Admin Finance',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        ref.invalidate(adminFinanceDashboardProvider);
                        ref.invalidate(adminSellerPayoutsProvider);
                      },
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: _FinanceRangeBar(
                  range: range,
                  onWeekTap: () {
                    ref.read(adminFinanceDateRangeProvider.notifier).state =
                        AdminFinanceDateRange.thisWeek();
                  },
                  onMonthTap: () {
                    ref.read(adminFinanceDateRangeProvider.notifier).state =
                        AdminFinanceDateRange.thisMonth();
                  },
                  onCustomTap: () async {
                    final picked = await _pickRange(context, range);
                    if (picked == null) return;
                    ref.read(adminFinanceDateRangeProvider.notifier).state =
                        AdminFinanceDateRange(
                      start: picked.start,
                      end: picked.end,
                      type: AdminFinanceRangeType.custom,
                    );
                  },
                ),
              ),
              Expanded(
                child: financeAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: WMTheme.royalPurple,
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Failed to load finance\n$e',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  data: (data) {
                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(adminFinanceDashboardProvider);
                        ref.invalidate(adminSellerPayoutsProvider);
                        await ref.read(adminFinanceDashboardProvider.future);
                        await ref.read(adminSellerPayoutsProvider.future);
                      },
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        children: [
                          _SummaryHero(
                            summary: data.platformSummary,
                            range: range,
                          ),
                          const SizedBox(height: 16),
                          _SectionCard(
                            title: 'Key Metrics',
                            child: GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 1.6,
                              children: [
                                _MetricTile(
                                  label: 'Gross Sales',
                                  value: _money(
                                    data.platformSummary.grossSalesCents,
                                  ),
                                  valueColor: WMTheme.royalPurple,
                                ),
                                _MetricTile(
                                  label: 'Seller Payable',
                                  value: _money(
                                    data.platformSummary.sellerPayableCents,
                                  ),
                                  valueColor: const Color(0xFF1565C0),
                                ),
                                _MetricTile(
                                  label: 'Platform Profit',
                                  value: _money(
                                    data.platformSummary.platformMarginCents,
                                  ),
                                  valueColor: const Color(0xFF1B8E3E),
                                ),
                                _MetricTile(
                                  label: 'Units Sold',
                                  value:
                                      '${data.platformSummary.totalUnitsSold}',
                                  valueColor: const Color(0xFF8A6700),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SectionCard(
                            title: 'Seller Breakdown',
                            child: data.sellerSummaries.isEmpty
                                ? const _EmptyText('No seller finance data yet')
                                : Column(
                                    children: [
                                      for (int i = 0;
                                          i < data.sellerSummaries.length;
                                          i++) ...[
                                        _SellerFinanceCard(
                                          summary: data.sellerSummaries[i],
                                          range: range,
                                        ),
                                        if (i !=
                                            data.sellerSummaries.length - 1)
                                          const SizedBox(height: 10),
                                      ],
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 16),
                          _SectionCard(
                            title: 'Seller Payouts',
                            child: payoutsAsync.when(
                              loading: () => const Padding(
                                padding: EdgeInsets.all(12),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: WMTheme.royalPurple,
                                  ),
                                ),
                              ),
                              error: (e, _) =>
                                  Text('Failed to load payouts\n$e'),
                              data: (payouts) {
                                if (payouts.isEmpty) {
                                  return const _EmptyText(
                                    'No payouts in this range yet',
                                  );
                                }

                                return Column(
                                  children: [
                                    for (int i = 0;
                                        i < payouts.length;
                                        i++) ...[
                                      _PayoutCard(payout: payouts[i]),
                                      if (i != payouts.length - 1)
                                        const SizedBox(height: 10),
                                    ],
                                  ],
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SectionCard(
                            title: 'Recent Order Financials',
                            child: data.recentRows.isEmpty
                                ? const _EmptyText('No recent finance rows yet')
                                : Column(
                                    children: [
                                      for (int i = 0;
                                          i < data.recentRows.length;
                                          i++) ...[
                                        _RecentFinanceRowCard(
                                          row: data.recentRows[i],
                                        ),
                                        if (i != data.recentRows.length - 1)
                                          const SizedBox(height: 10),
                                      ],
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _money(int cents) => '£${(cents / 100).toStringAsFixed(2)}';

  static Future<DateTimeRange?> _pickRange(
    BuildContext context,
    AdminFinanceDateRange current,
  ) async {
    final now = DateTime.now();
    return showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      initialDateRange: DateTimeRange(
        start: current.start,
        end: current.end,
      ),
    );
  }
}

class _FinanceRangeBar extends StatelessWidget {
  final AdminFinanceDateRange range;
  final VoidCallback onWeekTap;
  final VoidCallback onMonthTap;
  final VoidCallback onCustomTap;

  const _FinanceRangeBar({
    required this.range,
    required this.onWeekTap,
    required this.onMonthTap,
    required this.onCustomTap,
  });

  @override
  Widget build(BuildContext context) {
    final customLabel = '${_d(range.start)} - ${_d(range.end)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _RangeChip(
                label: 'This Week',
                selected: range.type == AdminFinanceRangeType.thisWeek,
                onTap: onWeekTap,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _RangeChip(
                label: 'This Month',
                selected: range.type == AdminFinanceRangeType.thisMonth,
                onTap: onMonthTap,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _RangeChip(
                label: 'Custom',
                selected: range.type == AdminFinanceRangeType.custom,
                onTap: onCustomTap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          customLabel,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  static String _d(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

class _RangeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? WMTheme.royalPurple : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? WMTheme.royalPurple : const Color(0xFFE3DAEF),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : WMTheme.royalPurple,
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryHero extends StatelessWidget {
  final AdminPlatformFinanceSummary summary;
  final AdminFinanceDateRange range;

  const _SummaryHero({
    required this.summary,
    required this.range,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            WMTheme.royalPurple,
            Color(0xFF8A56C9),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Finance Overview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'From ${_d(range.start)} to ${_d(range.end)}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroPill(
                icon: Icons.receipt_long_rounded,
                label: '${summary.totalOrders} orders',
              ),
              _HeroPill(
                icon: Icons.list_alt_rounded,
                label: '${summary.totalOrderLines} lines',
              ),
              _HeroPill(
                icon: Icons.inventory_2_outlined,
                label: '${summary.totalUnitsSold} units',
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _d(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF9FE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAE2F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _SellerFinanceCard extends ConsumerWidget {
  final AdminSellerFinanceSummary summary;
  final AdminFinanceDateRange range;

  const _SellerFinanceCard({
    required this.summary,
    required this.range,
  });

  static String _money(int cents) => '£${(cents / 100).toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingNet = summary.sellerPayableCents -
        summary.paidCents -
        summary.pendingPayoutCents;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFBFE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFECE5F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (summary.sellerName ?? 'Seller').trim().isEmpty
                ? 'Seller'
                : summary.sellerName!,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            summary.sellerEmail ?? '',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniBadge(
                label: '${summary.totalOrders} orders',
                background: const Color(0xFFF5F1FB),
                foreground: WMTheme.royalPurple,
              ),
              _MiniBadge(
                label: '${summary.totalUnitsSold} units',
                background: const Color(0xFFFFF8E7),
                foreground: const Color(0xFF8A6700),
              ),
              _MiniBadge(
                label: 'Paid ${_money(summary.paidCents)}',
                background: const Color(0xFFEAF8EE),
                foreground: const Color(0xFF1B8E3E),
              ),
              _MiniBadge(
                label: 'Pending ${_money(summary.pendingPayoutCents)}',
                background: const Color(0xFFEAF5FF),
                foreground: const Color(0xFF1565C0),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  label: 'Gross',
                  value: _money(summary.grossSalesCents),
                  valueColor: WMTheme.royalPurple,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniMetric(
                  label: 'Payable',
                  value: _money(summary.sellerPayableCents),
                  valueColor: const Color(0xFF1565C0),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniMetric(
                  label: 'Profit',
                  value: _money(summary.platformMarginCents),
                  valueColor: const Color(0xFF1B8E3E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (pendingNet > 0)
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () async {
                  final controller = TextEditingController(
                    text: (pendingNet / 100).toStringAsFixed(2),
                  );
                  final noteController = TextEditingController();

                  final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Create payout'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Create payout for ${summary.sellerName ?? 'seller'}',
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: controller,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Amount (£)',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: noteController,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  labelText: 'Note (optional)',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Create'),
                            ),
                          ],
                        ),
                      ) ??
                      false;

                  if (!confirmed) return;

                  final amount =
                      ((double.tryParse(controller.text.trim()) ?? 0) * 100)
                          .round();
                  if (amount <= 0) return;

                  await ref
                      .read(adminFinanceServiceProvider)
                      .createSellerPayout(
                        sellerId: summary.sellerId,
                        periodStart: range.start,
                        periodEnd: range.end,
                        amountCents: amount,
                        note: noteController.text.trim().isEmpty
                            ? null
                            : noteController.text.trim(),
                      );

                  ref.invalidate(adminFinanceDashboardProvider);
                  ref.invalidate(adminSellerPayoutsProvider);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Payout created')),
                    );
                  }
                },
                icon: const Icon(Icons.payments_outlined),
                label: const Text('Create payout'),
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _MiniMetric({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEAE2F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black54,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentFinanceRowCard extends StatelessWidget {
  final AdminOrderItemFinanceRow row;

  const _RecentFinanceRowCard({
    required this.row,
  });

  static String _money(int? cents) =>
      '£${(((cents ?? 0)) / 100).toStringAsFixed(2)}';

  static String _date(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFBFE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFECE5F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            row.productName ?? 'Unknown product',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            row.orderNumber ?? row.orderId,
            style: const TextStyle(
              fontSize: 12,
              color: WMTheme.royalPurple,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _date(row.orderCreatedAt),
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniBadge(
                label: 'Qty ${row.qty}',
                background: const Color(0xFFF5F1FB),
                foreground: WMTheme.royalPurple,
              ),
              _MiniBadge(
                label: (row.paymentStatus ?? 'pending').toUpperCase(),
                background: const Color(0xFFFFF8E7),
                foreground: const Color(0xFF8A6700),
              ),
              if (row.isFrozen)
                const _MiniBadge(
                  label: 'Frozen',
                  background: Color(0xFFEAF5FF),
                  foreground: Color(0xFF1565C0),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  label: 'Customer',
                  value: _money(row.customerLineTotalCents),
                  valueColor: WMTheme.royalPurple,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniMetric(
                  label: 'Seller',
                  value: _money(row.sellerLineTotalCents),
                  valueColor: const Color(0xFF1565C0),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniMetric(
                  label: 'Profit',
                  value: _money(row.platformMarginLineCents),
                  valueColor: const Color(0xFF1B8E3E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PayoutCard extends ConsumerWidget {
  final SellerPayoutModel payout;

  const _PayoutCard({
    required this.payout,
  });

  static String _money(int cents) => '£${(cents / 100).toStringAsFixed(2)}';

  static String _date(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPaid = payout.status == 'paid';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFBFE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFECE5F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _money(payout.amountCents),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Period: ${_date(payout.periodStart)} - ${_date(payout.periodEnd)}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w700,
            ),
          ),
          if ((payout.note ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              payout.note!,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              _MiniBadge(
                label: isPaid ? 'PAID' : 'PENDING',
                background:
                    isPaid ? const Color(0xFFEAF8EE) : const Color(0xFFEAF5FF),
                foreground:
                    isPaid ? const Color(0xFF1B8E3E) : const Color(0xFF1565C0),
              ),
              const Spacer(),
              if (!isPaid)
                OutlinedButton.icon(
                  onPressed: () async {
                    await ref
                        .read(adminFinanceServiceProvider)
                        .markSellerPayoutPaid(payout.id);

                    ref.invalidate(adminFinanceDashboardProvider);
                    ref.invalidate(adminSellerPayoutsProvider);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Payout marked paid')),
                      );
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Mark paid'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _MiniBadge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: foreground,
        ),
      ),
    );
  }
}

class _EmptyText extends StatelessWidget {
  final String message;

  const _EmptyText(this.message);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.black54,
        ),
      ),
    );
  }
}
