import 'package:flutter/material.dart';
import 'package:western_malabar/shared/theme/theme.dart';

class DopamineRewardsCard extends StatelessWidget {
  final int rewardPoints;
  final int pointsPerRewardBlock;
  final int rewardBlockValuePence;
  final int nextUnlockSpendTargetPence;
  final int currentProgressSpendPence;
  final String? bonusBannerText;
  final VoidCallback? onRedeemTap;
  final VoidCallback? onRewardsHistoryTap;
  final VoidCallback? onHowItWorksTap;

  const DopamineRewardsCard({
    super.key,
    required this.rewardPoints,
    this.pointsPerRewardBlock = 200,
    this.rewardBlockValuePence = 200,
    this.nextUnlockSpendTargetPence = 2500,
    this.currentProgressSpendPence = 0,
    this.bonusBannerText,
    this.onRedeemTap,
    this.onRewardsHistoryTap,
    this.onHowItWorksTap,
  });

  @override
  Widget build(BuildContext context) {
    final walletValuePence =
        ((rewardPoints / pointsPerRewardBlock) * rewardBlockValuePence).floor();

    final readyRewardBlocks = rewardPoints ~/ pointsPerRewardBlock;
    final readyRewardValuePence = readyRewardBlocks * rewardBlockValuePence;

    final pointsIntoNext = rewardPoints % pointsPerRewardBlock;
    final pointsNeededForNext = rewardPoints == 0
        ? pointsPerRewardBlock
        : pointsPerRewardBlock - pointsIntoNext;

    final spendProgress = currentProgressSpendPence <= 0
        ? _estimatedSpendProgressFromPoints(rewardPoints)
        : currentProgressSpendPence;

    final progress =
        (spendProgress / nextUnlockSpendTargetPence).clamp(0.0, 1.0);
    final remainingToUnlockPence =
        (nextUnlockSpendTargetPence - spendProgress).clamp(0, 1 << 31);

    final headlineMoney = _formatMoney(walletValuePence);
    final readyRewardMoney = _formatMoney(readyRewardValuePence);
    final nextRewardMoney = _formatMoney(rewardBlockValuePence);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF2E4B2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 14,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFF0C53E),
                      Color(0xFFFFD96A),
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
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      readyRewardBlocks > 0
                          ? 'You already have $readyRewardMoney ready to use'
                          : 'You are building towards your next reward',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onHowItWorksTap,
                child: const Text(
                  'How it works',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          if ((bonusBannerText ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            _BonusBanner(text: bonusBannerText!.trim()),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MoneyStatCard(
                  label: 'Reward Wallet',
                  value: headlineMoney,
                  subtitle: '$rewardPoints pts available',
                  valueColor: WMTheme.royalPurple,
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MoneyStatCard(
                  label: 'Ready Now',
                  value: readyRewardBlocks > 0 ? readyRewardMoney : '£0.00',
                  subtitle: readyRewardBlocks > 0
                      ? '$readyRewardBlocks reward${readyRewardBlocks == 1 ? '' : 's'} unlocked'
                      : '$pointsNeededForNext pts to unlock',
                  valueColor: const Color(0xFF1E8E3E),
                  icon: Icons.redeem_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ReadyRewardPanel(
            rewardText: readyRewardBlocks > 0
                ? '$readyRewardMoney off your next order'
                : 'No reward unlocked yet',
            subtitle: readyRewardBlocks > 0
                ? 'Apply at checkout in one tap'
                : 'Only $pointsNeededForNext more points to unlock $nextRewardMoney',
            enabled: readyRewardBlocks > 0,
            onTap: onRedeemTap,
          ),
          const SizedBox(height: 16),
          _ProgressSection(
            title: 'Next unlock',
            headline: remainingToUnlockPence <= 0
                ? 'Reward unlocked 🎉'
                : 'Only ${_formatMoney(remainingToUnlockPence)} more to unlock',
            subtitle: remainingToUnlockPence <= 0
                ? 'You are ready for your next reward'
                : '$nextRewardMoney reward at ${_formatMoney(nextUnlockSpendTargetPence)} spend',
            progress: progress,
            leading: _formatMoney(spendProgress),
            trailing: _formatMoney(nextUnlockSpendTargetPence),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SmallActionButton(
                  label: 'Reward history',
                  icon: Icons.receipt_long_rounded,
                  onTap: onRewardsHistoryTap,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SmallActionButton(
                  label: 'Redeem now',
                  icon: Icons.local_offer_outlined,
                  onTap: readyRewardBlocks > 0 ? onRedeemTap : null,
                  filled: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Earn rewards after delivered or collected orders only.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static int _estimatedSpendProgressFromPoints(int points) {
    final pounds = points / 3.0;
    return (pounds * 100).round();
  }

  static String _formatMoney(int pence) {
    return '£${(pence / 100).toStringAsFixed(2)}';
  }
}

class _BonusBanner extends StatelessWidget {
  final String text;

  const _BonusBanner({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF5A2D82),
            Color(0xFF8753C4),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            color: Color(0xFFFFD96A),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoneyStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Color valueColor;
  final IconData icon;

  const _MoneyStatCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.valueColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF9FE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAE2F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: WMTheme.royalPurple, size: 18),
          const SizedBox(height: 10),
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
              fontSize: 24,
              color: valueColor,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadyRewardPanel extends StatelessWidget {
  final String rewardText;
  final String subtitle;
  final bool enabled;
  final VoidCallback? onTap;

  const _ReadyRewardPanel({
    required this.rewardText,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFFEFFAF1) : const Color(0xFFF6F0FB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: enabled ? const Color(0xFFCFE9D6) : const Color(0xFFEAE2F5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: enabled ? const Color(0xFF1E8E3E) : WMTheme.royalPurple,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.card_giftcard_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rewardText,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: enabled ? const Color(0xFF145A2B) : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: enabled ? onTap : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  enabled ? const Color(0xFF1E8E3E) : Colors.black26,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              enabled ? 'Redeem' : 'Locked',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  final String title;
  final String headline;
  final String subtitle;
  final double progress;
  final String leading;
  final String trailing;

  const _ProgressSection({
    required this.title,
    required this.headline,
    required this.subtitle,
    required this.progress,
    required this.leading,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF4E4B5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            headline,
            style: const TextStyle(
              fontSize: 17,
              color: Colors.black87,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: const Color(0xFFF2E8C8),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFF0C53E),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                leading,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                trailing,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;

  const _SmallActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: WMTheme.royalPurple,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: WMTheme.royalPurple,
        side: const BorderSide(color: WMTheme.royalPurple),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
