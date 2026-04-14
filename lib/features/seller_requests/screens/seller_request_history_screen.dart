import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/seller_product_requests_provider.dart';
import '../widgets/seller_request_history_card.dart';

class SellerRequestHistoryScreen extends ConsumerStatefulWidget {
  const SellerRequestHistoryScreen({super.key});

  @override
  ConsumerState<SellerRequestHistoryScreen> createState() =>
      _SellerRequestHistoryScreenState();
}

class _SellerRequestHistoryScreenState
    extends ConsumerState<SellerRequestHistoryScreen> {
  SellerRequestStatusFilter _activeFilter = SellerRequestStatusFilter.all;

  Future<void> _refresh() async {
    ref.invalidate(sellerProductRequestsProvider);
    await ref.read(sellerProductRequestsProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(sellerProductRequestsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FB),
      body: SafeArea(
        bottom: false,
        child: requestsAsync.when(
          loading: () => const _HistoryLoadingView(),
          error: (error, _) => _HistoryStateMessage(
            icon: Icons.rule_folder_outlined,
            title: 'Unable to load requests',
            message: '$error',
            actionLabel: 'Retry',
            onAction: _refresh,
          ),
          data: (requests) {
            final filtered = requests.where((r) {
              switch (_activeFilter) {
                case SellerRequestStatusFilter.all:
                  return true;
                case SellerRequestStatusFilter.pending:
                  return r.status == 'pending';
                case SellerRequestStatusFilter.approved:
                  return r.status == 'approved' ||
                      r.status == 'approved_merged';
                case SellerRequestStatusFilter.rejected:
                  return r.status == 'rejected';
              }
            }).toList();

            return RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HistoryTopBar(
                            onBack: () => Navigator.of(context).maybePop(),
                          ),
                          const SizedBox(height: 14),
                          _HistoryHeroCard(
                            total: requests.length,
                            pending: requests
                                .where((e) => e.status == 'pending')
                                .length,
                            approved: requests
                                .where((e) =>
                                    e.status == 'approved' ||
                                    e.status == 'approved_merged')
                                .length,
                            rejected: requests
                                .where((e) => e.status == 'rejected')
                                .length,
                          ),
                          const SizedBox(height: 14),
                          _HistoryFilterRow(
                            activeFilter: _activeFilter,
                            total: requests.length,
                            pending: requests
                                .where((e) => e.status == 'pending')
                                .length,
                            approved: requests
                                .where((e) =>
                                    e.status == 'approved' ||
                                    e.status == 'approved_merged')
                                .length,
                            rejected: requests
                                .where((e) => e.status == 'rejected')
                                .length,
                            onChanged: (value) {
                              setState(() {
                                _activeFilter = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Request History',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              Text(
                                '${filtered.length} item(s)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                  if (requests.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _HistoryStateMessage(
                        icon: Icons.inbox_outlined,
                        title: 'No requests yet',
                        message:
                            'When you submit new product requests, they will appear here.',
                      ),
                    )
                  else if (filtered.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _HistoryStateMessage(
                        icon: Icons.filter_alt_off_outlined,
                        title: 'No requests in this filter',
                        message:
                            'Try switching the filter to view other request statuses.',
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverList.separated(
                        itemCount: filtered.length,
                        itemBuilder: (_, index) {
                          return SellerRequestHistoryCard(
                            request: filtered[index],
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

enum SellerRequestStatusFilter {
  all,
  pending,
  approved,
  rejected,
}

class _HistoryTopBar extends StatelessWidget {
  const _HistoryTopBar({
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundIconButton(
          icon: Icons.arrow_back_rounded,
          onTap: onBack,
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Seller Requests',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF5A2D82),
              letterSpacing: -0.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF5A2D82),
          ),
        ),
      ),
    );
  }
}

class _HistoryHeroCard extends StatelessWidget {
  const _HistoryHeroCard({
    required this.total,
    required this.pending,
    required this.approved,
    required this.rejected,
  });

  final int total;
  final int pending;
  final int approved;
  final int rejected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF5A2D82),
            Color(0xFF8B57C8),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Request Control Center',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Track moderation, duplicate checks, approvals and rejections',
            style: TextStyle(
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
              _HeroPill(icon: Icons.inbox_outlined, label: '$total total'),
              _HeroPill(
                icon: Icons.hourglass_top_rounded,
                label: '$pending pending',
              ),
              _HeroPill(
                icon: Icons.check_circle_outline_rounded,
                label: '$approved approved',
              ),
              _HeroPill(
                icon: Icons.cancel_outlined,
                label: '$rejected rejected',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
        ),
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

class _HistoryFilterRow extends StatelessWidget {
  const _HistoryFilterRow({
    required this.activeFilter,
    required this.total,
    required this.pending,
    required this.approved,
    required this.rejected,
    required this.onChanged,
  });

  final SellerRequestStatusFilter activeFilter;
  final int total;
  final int pending;
  final int approved;
  final int rejected;
  final ValueChanged<SellerRequestStatusFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _FilterChipButton(
          selected: activeFilter == SellerRequestStatusFilter.all,
          label: 'All ($total)',
          onTap: () => onChanged(SellerRequestStatusFilter.all),
        ),
        _FilterChipButton(
          selected: activeFilter == SellerRequestStatusFilter.pending,
          label: 'Pending ($pending)',
          onTap: () => onChanged(SellerRequestStatusFilter.pending),
        ),
        _FilterChipButton(
          selected: activeFilter == SellerRequestStatusFilter.approved,
          label: 'Approved ($approved)',
          onTap: () => onChanged(SellerRequestStatusFilter.approved),
        ),
        _FilterChipButton(
          selected: activeFilter == SellerRequestStatusFilter.rejected,
          label: 'Rejected ($rejected)',
          onTap: () => onChanged(SellerRequestStatusFilter.rejected),
        ),
      ],
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? const Color(0xFF5A2D82) : Colors.white;
    final fg = selected ? Colors.white : Colors.black87;
    final border = selected ? const Color(0xFF5A2D82) : const Color(0xFFE7DFF1);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryStateMessage extends StatelessWidget {
  const _HistoryStateMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 14,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4EDFB),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF5A2D82),
                  size: 30,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryLoadingView extends StatelessWidget {
  const _HistoryLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        strokeWidth: 2.4,
        color: Color(0xFF5A2D82),
      ),
    );
  }
}
