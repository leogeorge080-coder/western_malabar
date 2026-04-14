class PricingOption {
  final int priceCents;
  final String label;

  const PricingOption(this.priceCents, this.label);
}

class PricingEngine {
  static List<PricingOption> generate(int sellerPriceCents) {
    if (sellerPriceCents <= 0) return const [];

    final base = sellerPriceCents;

    final options = <int>{
      base,
      (base * 1.05).round(),
      (base * 1.10).round(),
      (base * 1.15).round(),
      (base * 1.25).round(),
      (base * 1.50).round(),
    };

    final rounded = options.map(_roundSmart).toSet().toList()..sort();

    return rounded
        .map((cents) => PricingOption(cents, _format(cents)))
        .toList();
  }

  static int _roundSmart(int cents) {
    final pounds = cents / 100;
    final endings = [0.09, 0.25, 0.49, 0.75, 0.99];

    double best = pounds;
    double minDiff = double.infinity;

    for (final e in endings) {
      final candidate = pounds.floor() + e;
      final diff = (candidate - pounds).abs();

      if (diff < minDiff) {
        minDiff = diff;
        best = candidate;
      }
    }

    return (best * 100).round();
  }

  static String _format(int cents) {
    return '£${(cents / 100).toStringAsFixed(2)}';
  }
}

class MarginResult {
  final double value;
  final double percent;

  const MarginResult(this.value, this.percent);
}

MarginResult calculateMargin(int cost, int sell) {
  final value = (sell - cost) / 100;
  final percent = sell == 0 ? 0.0 : ((sell - cost) / sell) * 100;
  return MarginResult(value, percent);
}
