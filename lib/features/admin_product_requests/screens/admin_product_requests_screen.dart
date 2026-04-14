import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/admin_product_requests_provider.dart';
import '../widgets/admin_product_request_card.dart';
import 'admin_product_request_detail_screen.dart';

class AdminProductRequestsScreen extends ConsumerStatefulWidget {
  const AdminProductRequestsScreen({super.key});

  @override
  ConsumerState<AdminProductRequestsScreen> createState() =>
      _AdminProductRequestsScreenState();
}

class _AdminProductRequestsScreenState
    extends ConsumerState<AdminProductRequestsScreen> {
  @override
  void initState() {
    super.initState();
    // Invalidate so the queue is always fresh when the screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(adminPendingProductRequestsProvider);
      final user = Supabase.instance.client.auth.currentUser;
      debugPrint(
          '[AdminProductRequestsScreen] signed-in user: ${user?.id} (${user?.email})');
    });
  }

  Future<void> _refresh() async {
    ref.invalidate(adminPendingProductRequestsProvider);
    await ref.read(adminPendingProductRequestsProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(adminPendingProductRequestsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FB),
      body: SafeArea(
        bottom: false,
        child: requestsAsync.when(
          loading: () => const _LoadingView(),
          error: (e, _) => _StateCard(
            icon: Icons.rule_folder_outlined,
            title: 'Unable to load moderation queue',
            message: '$e',
            actionLabel: 'Retry',
            onAction: _refresh,
          ),
          data: (requests) {
            if (requests.isEmpty) {
              return const _StateCard(
                icon: Icons.inbox_outlined,
                title: 'No pending product requests',
                message: 'New seller submissions will appear here for review.',
              );
            }

            final highRisk = requests
                .where((e) =>
                    e.duplicateConfidence >= 80 || e.issueFlags.isNotEmpty)
                .length;

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
                          const Text(
                            'Product Moderation',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF5A2D82),
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _QueueHeroCard(
                            total: requests.length,
                            highRisk: highRisk,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Pending Queue',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              Text(
                                '${requests.length} item(s)',
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
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList.separated(
                      itemCount: requests.length,
                      itemBuilder: (_, i) => AdminProductRequestCard(
                        request: requests[i],
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AdminProductRequestDetailScreen(
                                request: requests[i],
                              ),
                            ),
                          );
                        },
                      ),
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

class _QueueHeroCard extends StatelessWidget {
  const _QueueHeroCard({
    required this.total,
    required this.highRisk,
  });

  final int total;
  final int highRisk;

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
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _HeroPill(
            icon: Icons.inbox_outlined,
            label: '$total pending',
          ),
          _HeroPill(
            icon: Icons.warning_amber_rounded,
            label: '$highRisk high-risk',
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

class _StateCard extends StatelessWidget {
  const _StateCard({
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

class _LoadingView extends StatelessWidget {
  const _LoadingView();

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
