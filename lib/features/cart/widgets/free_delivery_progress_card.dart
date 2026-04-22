import 'package:flutter/material.dart';
import 'package:western_malabar/shared/theme/theme.dart';

class FreeDeliveryProgressCard extends StatelessWidget {
  const FreeDeliveryProgressCard({
    super.key,
    required this.cartTotalCents,
    this.freeDeliveryThresholdCents = 2000,
  });

  final int cartTotalCents;
  final int freeDeliveryThresholdCents;

  bool get _unlocked => cartTotalCents >= freeDeliveryThresholdCents;

  int get _remainingCents {
    final remaining = freeDeliveryThresholdCents - cartTotalCents;
    return remaining > 0 ? remaining : 0;
  }

  double get _progress {
    if (freeDeliveryThresholdCents <= 0) return 0;
    final value = cartTotalCents / freeDeliveryThresholdCents;
    return value.clamp(0.0, 1.0);
  }

  String _money(int cents) => '£${(cents / 100).toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final bg = _unlocked ? const Color(0xFFF1FAF3) : const Color(0xFFFFF9EE);
    final border =
        _unlocked ? const Color(0xFFBFE3C7) : const Color(0xFFF4D98B);
    final accent = _unlocked ? const Color(0xFF2E9B57) : WMTheme.royalPurple;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _unlocked
                  ? Icons.check_circle_rounded
                  : Icons.local_shipping_rounded,
              color: accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _unlocked
                      ? 'You\'ve unlocked free delivery'
                      : 'Add ${_money(_remainingCents)} more for free delivery',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _unlocked
                      ? 'Nice — your order now qualifies for free delivery.'
                      : 'Keep shopping to save on delivery charges.',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 10,
                    backgroundColor: Colors.white,
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      _money(cartTotalCents),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _money(freeDeliveryThresholdCents),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
