import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:western_malabar/features/cart/providers/cart_provider.dart';
import 'package:western_malabar/features/cart/screens/cart_screen.dart';
import 'package:western_malabar/features/profile/providers/profile_provider.dart';
import 'package:western_malabar/features/search/screens/global_product_search_screen.dart';

const _wmRewardsBg = Color(0xFFF7F7F7);
const _wmRewardsSurface = Colors.white;
const _wmRewardsBorder = Color(0xFFE5E7EB);

const _wmRewardsTextStrong = Color(0xFF111827);
const _wmRewardsTextSoft = Color(0xFF6B7280);
const _wmRewardsTextMuted = Color(0xFF9CA3AF);

const _wmRewardsPrimary = Color(0xFF2A2F3A);
const _wmRewardsPrimaryDark = Color(0xFF171A20);

const _wmRewardsAmber = Color(0xFFF59E0B);
const _wmRewardsAmberDark = Color(0xFFD97706);
const _wmRewardsAmberSoft = Color(0xFFFFF7ED);

const _wmRewardsSuccess = Color(0xFF15803D);
const _wmRewardsSuccessSoft = Color(0xFFECFDF5);

const _wmRewardsDanger = Color(0xFFDC2626);

String _formatRewardMoney(int pence) => '£${(pence / 100).toStringAsFixed(2)}';

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  static const int _pointsPerRewardBlock = 200;
  static const int _rewardBlockValuePence = 200;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final cartItems = ref.watch(cartProvider);
    final cartCount = cartItems.fold<int>(0, (sum, item) => sum + item.qty);

    return Scaffold(
      backgroundColor: _wmRewardsBg,
      body: SafeArea(
        child: Column(
          children: [
            const _RewardsTopBar(),
            const SizedBox(height: 10),
            Expanded(
              child: profileAsync.when(
                loading: () => const _RewardsLoadingView(),
                error: (error, _) => _RewardsErrorView(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(profileProvider),
                ),
                data: (profile) {
                  if (profile == null) {
                    return _RewardsErrorView(
                      message: 'Profile not found for this account.',
                      onRetry: () => ref.invalidate(profileProvider),
                    );
                  }

                  final summary = _RewardsViewData.fromProfile(
                    profile: profile,
                    pointsPerRewardBlock: _pointsPerRewardBlock,
                    rewardBlockValuePence: _rewardBlockValuePence,
                  );

                  return RefreshIndicator(
                    color: _wmRewardsPrimary,
                    onRefresh: () async {
                      ref.invalidate(profileProvider);
                      await ref.read(profileProvider.future);
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                      children: [
                        _RewardsHeroCard(
                          data: summary,
                          primaryCtaLabel: summary.availableRewardPence > 0
                              ? (cartCount > 0
                                  ? 'Use at checkout'
                                  : 'Build basket')
                              : (cartCount > 0
                                  ? 'Add more items'
                                  : 'Start shopping'),
                          onRedeemTap: () {
                            if (cartCount > 0) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CartScreen(),
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const GlobalProductSearchScreen(),
                                ),
                              );
                            }
                          },
                          onHistoryTap: () {
                            showModalBottomSheet<void>(
                              context: context,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                              ),
                              builder: (_) => _RewardsHistorySheet(
                                items: _demoRewardActivity(summary),
                              ),
                            );
                          },
                          onHowItWorksTap: () {
                            showModalBottomSheet<void>(
                              context: context,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                              ),
                              builder: (_) => const _RewardsHowItWorksModal(),
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        _RewardsActivityCard(
                          items: _demoRewardActivity(summary),
                        ),
                        const SizedBox(height: 14),
                        const _HowToEarnCard(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_RewardActivityItem> _demoRewardActivity(_RewardsViewData data) {
    final items = <_RewardActivityItem>[
      _RewardActivityItem(
        title: 'Current points balance',
        subtitle: 'Points tracked from delivered or collected orders',
        pointsDelta: data.availablePoints,
        type: _RewardActivityType.earned,
      ),
    ];

    if (data.availableRewardPence > 0) {
      items.add(
        _RewardActivityItem(
          title: 'Reward ready to apply',
          subtitle:
              '${_formatRewardMoney(data.availableRewardPence)} can be used on your next checkout',
          pointsDelta: data.pointsPerRewardBlock,
          type: _RewardActivityType.bonus,
        ),
      );
    }

    items.add(
      _RewardActivityItem(
        title: 'Next unlock target',
        subtitle: data.pointsToNextReward == 0
            ? 'Your next reward is unlocked'
            : '${data.pointsToNextReward} points to unlock ${_formatRewardMoney(data.rewardBlockValuePence)}',
        pointsDelta: 0,
        type: _RewardActivityType.info,
      ),
    );

    return items;
  }
}

class _RewardsViewData {
  final int totalPoints;
  final int availablePoints;
  final int availableRewardPence;
  final int unlockedRewardBlocks;
  final int rewardBlockValuePence;
  final int pointsPerRewardBlock;
  final int pointsIntoNext;
  final int pointsToNextReward;
  final double nextRewardProgress;
  final String availableRewardFormatted;
  final String nextRewardFormatted;
  final String progressLabel;
  final String heroTitle;
  final String heroSubtitle;
  final String progressHeadline;
  final String trustLine;

  const _RewardsViewData({
    required this.totalPoints,
    required this.availablePoints,
    required this.availableRewardPence,
    required this.unlockedRewardBlocks,
    required this.rewardBlockValuePence,
    required this.pointsPerRewardBlock,
    required this.pointsIntoNext,
    required this.pointsToNextReward,
    required this.nextRewardProgress,
    required this.availableRewardFormatted,
    required this.nextRewardFormatted,
    required this.progressLabel,
    required this.heroTitle,
    required this.heroSubtitle,
    required this.progressHeadline,
    required this.trustLine,
  });

  factory _RewardsViewData.fromProfile({
    required dynamic profile,
    required int pointsPerRewardBlock,
    required int rewardBlockValuePence,
  }) {
    final totalPoints = (profile.rewardPoints as int?) ?? 0;
    final unlockedRewardBlocks = totalPoints ~/ pointsPerRewardBlock;
    final availableRewardPence = unlockedRewardBlocks * rewardBlockValuePence;
    final pointsIntoNext = totalPoints % pointsPerRewardBlock;
    final pointsToNextReward = totalPoints == 0
        ? pointsPerRewardBlock
        : (pointsPerRewardBlock - pointsIntoNext);
    final progress = pointsIntoNext / pointsPerRewardBlock;

    final availableRewardFormatted =
        '£${(availableRewardPence / 100).toStringAsFixed(2)}';
    final nextRewardFormatted =
        '£${(rewardBlockValuePence / 100).toStringAsFixed(2)}';

    final heroTitle = availableRewardPence > 0
        ? '$availableRewardFormatted ready to use'
        : 'You’re building your first reward';

    final heroSubtitle = availableRewardPence > 0
        ? 'Use your rewards at checkout on your next order.'
        : 'Keep shopping to unlock your first reward voucher.';

    final progressHeadline = pointsToNextReward == 0
        ? 'Your next reward is unlocked'
        : '$pointsToNextReward points to unlock $nextRewardFormatted';

    final progressLabel =
        '$pointsIntoNext / $pointsPerRewardBlock points toward your next reward';

    const trustLine =
        'Points are added after delivered or collected orders only.';

    return _RewardsViewData(
      totalPoints: totalPoints,
      availablePoints: totalPoints,
      availableRewardPence: availableRewardPence,
      unlockedRewardBlocks: unlockedRewardBlocks,
      rewardBlockValuePence: rewardBlockValuePence,
      pointsPerRewardBlock: pointsPerRewardBlock,
      pointsIntoNext: pointsIntoNext,
      pointsToNextReward:
          pointsToNextReward == pointsPerRewardBlock && totalPoints == 0
              ? pointsPerRewardBlock
              : pointsToNextReward,
      nextRewardProgress: progress.clamp(0.0, 1.0),
      availableRewardFormatted: availableRewardFormatted,
      nextRewardFormatted: nextRewardFormatted,
      progressLabel: progressLabel,
      heroTitle: heroTitle,
      heroSubtitle: heroSubtitle,
      progressHeadline: progressHeadline,
      trustLine: trustLine,
    );
  }
}

class _RewardsTopBar extends StatelessWidget {
  const _RewardsTopBar();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Rewards',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: _wmRewardsTextStrong,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardsHeroCard extends StatelessWidget {
  final _RewardsViewData data;
  final String primaryCtaLabel;
  final VoidCallback onRedeemTap;
  final VoidCallback onHistoryTap;
  final VoidCallback onHowItWorksTap;

  const _RewardsHeroCard({
    required this.data,
    required this.primaryCtaLabel,
    required this.onRedeemTap,
    required this.onHistoryTap,
    required this.onHowItWorksTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasReadyReward = data.availableRewardPence > 0;
    final rewardValue = _formatRewardMoney(data.availableRewardPence);
    final nextRewardValue = _formatRewardMoney(data.rewardBlockValuePence);
    final heroTitle = hasReadyReward
        ? '$rewardValue ready to use'
        : 'You\'re building your first reward';
    final heroSubtitle = hasReadyReward
        ? 'Your next checkout can use this reward immediately.'
        : 'Keep shopping to unlock your first reward and make the next order feel cheaper.';
    final progressHeadline = data.pointsToNextReward == 0
        ? 'Your next reward is unlocked'
        : '${data.pointsToNextReward} points to unlock $nextRewardValue';
    final progressLabel =
        '${data.pointsIntoNext} / ${data.pointsPerRewardBlock} points toward your next reward';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _wmRewardsSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _wmRewardsBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 14,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      _wmRewardsAmber,
                      Color(0xFFFBBF24),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Malabar Rewards',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _wmRewardsTextStrong,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.trustLine,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: _wmRewardsTextSoft,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onHowItWorksTap,
                style: TextButton.styleFrom(
                  foregroundColor: _wmRewardsPrimary,
                ),
                child: const Text(
                  'How it works',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  _wmRewardsPrimaryDark,
                  _wmRewardsPrimary,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  heroTitle,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  heroSubtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE5E7EB),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _HeroStat(
                        label: 'Available points',
                        value: '${data.availablePoints}',
                        light: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HeroStat(
                        label: 'Unlocked rewards',
                        value: '${data.unlockedRewardBlocks}',
                        light: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _wmRewardsAmberSoft,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Next reward',
                  style: TextStyle(
                    fontSize: 12,
                    color: _wmRewardsTextSoft,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  progressHeadline,
                  style: const TextStyle(
                    fontSize: 17,
                    color: _wmRewardsTextStrong,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  progressLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _wmRewardsTextSoft,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: data.nextRewardProgress,
                    minHeight: 10,
                    backgroundColor: const Color(0xFFFDE7C7),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      _wmRewardsAmber,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${data.pointsIntoNext} pts',
                      style: const TextStyle(
                        fontSize: 12,
                        color: _wmRewardsTextStrong,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${data.pointsPerRewardBlock} pts',
                      style: const TextStyle(
                        fontSize: 12,
                        color: _wmRewardsTextSoft,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onHistoryTap,
                  icon: const Icon(Icons.receipt_long_rounded, size: 18),
                  label: const Text(
                    'Reward history',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _wmRewardsPrimary,
                    side: const BorderSide(color: _wmRewardsBorder),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onRedeemTap,
                  icon: const Icon(Icons.local_offer_outlined, size: 18),
                  label: Text(
                    primaryCtaLabel,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _wmRewardsPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  final bool light;

  const _HeroStat({
    required this.label,
    required this.value,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: light ? const Color(0x14FFFFFF) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: light ? const Color(0x24FFFFFF) : _wmRewardsBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              color: light ? const Color(0xFFE5E7EB) : _wmRewardsTextSoft,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              color: light ? Colors.white : _wmRewardsPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardsActivityCard extends StatelessWidget {
  final List<_RewardActivityItem> items;

  const _RewardsActivityCard({
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _wmRewardsSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _wmRewardsBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your rewards status',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: _wmRewardsTextStrong,
            ),
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _wmRewardsBorder),
              ),
              child: const Text(
                'No rewards activity yet. Complete your first order to start earning points.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _wmRewardsTextSoft,
                  height: 1.4,
                ),
              ),
            )
          else
            ...List.generate(items.length, (index) {
              final item = items[index];
              return Padding(
                padding:
                    EdgeInsets.only(bottom: index == items.length - 1 ? 0 : 10),
                child: _RewardActivityRow(item: item),
              );
            }),
        ],
      ),
    );
  }
}

class _RewardActivityRow extends StatelessWidget {
  final _RewardActivityItem item;

  const _RewardActivityRow({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (item.type) {
      _RewardActivityType.earned => _wmRewardsSuccess,
      _RewardActivityType.redeemed => _wmRewardsPrimary,
      _RewardActivityType.bonus => _wmRewardsAmber,
      _RewardActivityType.info => _wmRewardsPrimary,
    };

    final bgColor = switch (item.type) {
      _RewardActivityType.earned => _wmRewardsSuccessSoft,
      _RewardActivityType.redeemed => const Color(0xFFF3F4F6),
      _RewardActivityType.bonus => _wmRewardsAmberSoft,
      _RewardActivityType.info => const Color(0xFFF3F4F6),
    };

    final icon = switch (item.type) {
      _RewardActivityType.earned => Icons.add_circle_outline_rounded,
      _RewardActivityType.redeemed => Icons.local_offer_outlined,
      _RewardActivityType.bonus => Icons.local_fire_department_rounded,
      _RewardActivityType.info => Icons.info_outline_rounded,
    };

    final pointsText = item.pointsDelta > 0
        ? '+${item.pointsDelta} pts'
        : item.pointsDelta < 0
            ? '${item.pointsDelta} pts'
            : 'Info';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _wmRewardsBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _wmRewardsTextStrong,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _wmRewardsTextSoft,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            pointsText,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _HowToEarnCard extends StatelessWidget {
  const _HowToEarnCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _wmRewardsSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _wmRewardsBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How to earn more',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: _wmRewardsTextStrong,
            ),
          ),
          SizedBox(height: 14),
          _RewardTipRow(
            icon: Icons.shopping_basket_outlined,
            title: 'Complete more orders',
            subtitle: 'Points are added after delivered or collected orders.',
          ),
          SizedBox(height: 10),
          _RewardTipRow(
            icon: Icons.local_mall_outlined,
            title: 'Build bigger baskets',
            subtitle: 'Higher eligible spend helps you unlock rewards faster.',
          ),
          SizedBox(height: 10),
          _RewardTipRow(
            icon: Icons.local_fire_department_rounded,
            title: 'Watch for bonus events',
            subtitle:
                'Special promotions can give extra points on selected weekends.',
          ),
        ],
      ),
    );
  }
}

class _RewardTipRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _RewardTipRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isFire = icon == Icons.local_fire_department_rounded;
    final bg = isFire ? _wmRewardsAmberSoft : const Color(0xFFF3F4F6);
    final iconColor = isFire ? _wmRewardsAmber : _wmRewardsPrimary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _wmRewardsBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _wmRewardsTextStrong,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _wmRewardsTextSoft,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardsHowItWorksSheet extends StatelessWidget {
  const _RewardsHowItWorksSheet();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 18, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How rewards work',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: _wmRewardsTextStrong,
            ),
          ),
          SizedBox(height: 14),
          Text(
            '• Earn points after delivered or collected orders\n'
            '• Every 200 points unlocks £2 reward value\n'
            '• Rewards can be applied at checkout\n'
            '• Delivery fees and refunded items do not earn points\n'
            '• Bonus campaigns may give extra points on selected days',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _wmRewardsTextSoft,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardsHowItWorksModal extends StatelessWidget {
  const _RewardsHowItWorksModal();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 18, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How rewards work',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: _wmRewardsTextStrong,
            ),
          ),
          SizedBox(height: 14),
          Text(
            '• Earn points after delivered or collected orders\n'
            '• Every 200 points unlocks £2 reward value\n'
            '• Rewards can be applied at checkout\n'
            '• Delivery fees and refunded items do not earn points\n'
            '• Bonus campaigns may give extra points on selected days',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _wmRewardsTextSoft,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardsHistorySheet extends StatelessWidget {
  final List<_RewardActivityItem> items;

  const _RewardsHistorySheet({
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Reward history',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: _wmRewardsTextStrong,
                ),
              ),
            ),
            const SizedBox(height: 14),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RewardActivityRow(item: item),
                )),
          ],
        ),
      ),
    );
  }
}

enum _RewardActivityType {
  earned,
  redeemed,
  bonus,
  info,
}

class _RewardActivityItem {
  final String title;
  final String subtitle;
  final int pointsDelta;
  final _RewardActivityType type;

  const _RewardActivityItem({
    required this.title,
    required this.subtitle,
    required this.pointsDelta,
    required this.type,
  });
}

class _RewardsLoadingView extends StatelessWidget {
  const _RewardsLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
      children: const [
        _RewardsSkeleton(height: 390),
        SizedBox(height: 14),
        _RewardsSkeleton(height: 220),
        SizedBox(height: 14),
        _RewardsSkeleton(height: 220),
      ],
    );
  }
}

class _RewardsSkeleton extends StatelessWidget {
  final double height;

  const _RewardsSkeleton({
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _wmRewardsBorder),
      ),
    );
  }
}

class _RewardsErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _RewardsErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _wmRewardsSurface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _wmRewardsBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 42,
                color: _wmRewardsDanger,
              ),
              const SizedBox(height: 12),
              const Text(
                'Unable to load rewards',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: _wmRewardsTextStrong,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: _wmRewardsTextSoft,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _wmRewardsPrimary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
