// lib/widgets/weather_smart_picks.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:western_malabar/services/weather_service.dart';

/// Brand colours (same palette you’re using)
const _wmPurple = Color(0xFF4B208C);
const _wmLavender = Color(0xFFE5DBFF);

class WeatherSmartPicks extends StatelessWidget {
  const WeatherSmartPicks({
    super.key,
    this.city = 'Scunthorpe',
    this.country = 'GB',
    this.onShopTap,
  });

  final String city;
  final String country;
  final void Function(String slug)? onShopTap;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WeatherNow?>(
      future: WeatherService.fetchCurrent(city: city, country: country),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _SkeletonCard();
        }
        final w = snap.data;
        if (w == null) return const SizedBox.shrink();

        final mood = _moodFor(w);
        final suggestion = _suggestFor(w);

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              height: 130,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Brand gradient base
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF5A2A9B), Color(0xFF9C6ADE)],
                      ),
                    ),
                  ),

                  // ✨ Weather background that blends into brand colours
                  _AnimatedWeatherBackdrop(mood: mood),

                  // Subtle moving sheen (kept from your previous card)
                  const _MovingSheenStripe(),

                  // Foreground content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        // Icon cloud/sun “chip” (vector-like)
                        _MoodBadge(mood: mood),
                        const SizedBox(width: 14),
                        Expanded(
                          child: DefaultTextStyle(
                            style: const TextStyle(color: Colors.white),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  suggestion.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  suggestion.subtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${w.tempC.toStringAsFixed(0)}°C • $city',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: _wmPurple,
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => onShopTap?.call(suggestion.slug),
                          child: Text(
                            suggestion.cta,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ---- mapping logic ---------------------------------------------------------

  _WeatherMood _moodFor(WeatherNow w) {
    final m = w.main.toLowerCase();
    if (m.contains('snow')) return _WeatherMood.snow;
    if (m.contains('rain') || m.contains('drizzle')) return _WeatherMood.rain;
    if (m.contains('cloud')) return _WeatherMood.clouds;
    return _WeatherMood.sun; // clear / default pleasant
  }

  _Suggestion _suggestFor(WeatherNow w) {
    final t = w.tempC;
    final main = w.main.toLowerCase();
    final windy = w.windKph > 28;

    if (main.contains('rain') || main.contains('drizzle')) {
      return _Suggestion(
        title: 'Rainy Day Comforts',
        subtitle: 'Hot chai, pakoras & ready curries.',
        cta: 'Shop Picks',
        slug: 'collections/rain-comforts',
      );
    }
    if (main.contains('snow')) {
      return _Suggestion(
        title: 'Warm & Hearty',
        subtitle: 'Soups, ready gravies & masalas.',
        cta: 'Get Cozy',
        slug: 'collections/warm-hearty',
      );
    }
    if (t <= 8) {
      return _Suggestion(
        title: 'Cold Weather Staples',
        subtitle: 'Parathas, soups, masala chai.',
        cta: 'Warm Me',
        slug: 'collections/cold-staples',
      );
    }
    if (t >= 24) {
      return _Suggestion(
        title: 'Cool & Fresh',
        subtitle: 'Buttermilk, tender coconut & ice creams.',
        cta: 'Cool Me',
        slug: 'collections/cool-refreshers',
      );
    }
    if (windy) {
      return _Suggestion(
        title: 'Quick Bite, Quick Day',
        subtitle: 'Ready mixes & grab-n-go snacks.',
        cta: 'Quick Picks',
        slug: 'collections/quick-bites',
      );
    }
    if (main.contains('cloud')) {
      return _Suggestion(
        title: 'Cloudy Day Specials',
        subtitle: 'Filter coffee & evening snacks.',
        cta: 'Shop Now',
        slug: 'collections/cloudy-specials',
      );
    }
    return _Suggestion(
      title: 'Today’s Fresh Picks',
      subtitle: 'Veg, fruits & fresh staples.',
      cta: 'Browse',
      slug: 'collections/fresh-picks',
    );
  }
}

// -----------------------------------------------------------------------------

enum _WeatherMood { sun, clouds, rain, snow }

/// Small “badge” icon that keeps to your brand style (no external images).
class _MoodBadge extends StatelessWidget {
  const _MoodBadge({required this.mood});
  final _WeatherMood mood;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      width: 56,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(.35)),
      ),
      alignment: Alignment.center,
      child: CustomPaint(
        size: const Size(34, 34),
        painter: _BadgePainter(mood),
      ),
    );
  }
}

class _BadgePainter extends CustomPainter {
  _BadgePainter(this.mood);
  final _WeatherMood mood;

  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..isAntiAlias = true;
    switch (mood) {
      case _WeatherMood.sun:
        // sun disk
        final center = Offset(s.width / 2, s.height / 2);
        final r = math.min(s.width, s.height) * 0.28;
        p.shader = RadialGradient(
          colors: [Colors.amber.shade200, const Color(0xFFFFF3B0)],
        ).createShader(Rect.fromCircle(center: center, radius: r));
        c.drawCircle(center, r, p);
        // tiny rays
        final ray = Paint()
          ..color = Colors.white.withOpacity(.6)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;
        for (int i = 0; i < 8; i++) {
          final a = (i / 8) * 2 * math.pi;
          final p1 = center + Offset(math.cos(a), math.sin(a)) * (r + 5);
          final p2 = center + Offset(math.cos(a), math.sin(a)) * (r + 10);
          c.drawLine(p1, p2, ray);
        }
        break;

      case _WeatherMood.clouds:
      case _WeatherMood.rain:
      case _WeatherMood.snow:
        // simple cloud puffs
        final cloudPaint = Paint()..color = Colors.white.withOpacity(.9);
        final y = s.height * 0.58;
        c.drawCircle(Offset(s.width * .35, y), 9, cloudPaint);
        c.drawCircle(Offset(s.width * .48, y - 5), 11, cloudPaint);
        c.drawCircle(Offset(s.width * .58, y), 8, cloudPaint);
        final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(s.width * .48, y + 4), width: 34, height: 14),
          const Radius.circular(8),
        );
        c.drawRRect(rect, cloudPaint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _BadgePainter oldDelegate) =>
      oldDelegate.mood != mood;
}

/// Animated painter background that blends with the purple gradient.
class _AnimatedWeatherBackdrop extends StatefulWidget {
  const _AnimatedWeatherBackdrop({required this.mood});
  final _WeatherMood mood;

  @override
  State<_AnimatedWeatherBackdrop> createState() =>
      _AnimatedWeatherBackdropState();
}

class _AnimatedWeatherBackdropState extends State<_AnimatedWeatherBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(seconds: 8))
        ..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return CustomPaint(
          painter: _WeatherBackdropPainter(
            t: _ctrl.value,
            mood: widget.mood,
          ),
        );
      },
    );
  }
}

class _WeatherBackdropPainter extends CustomPainter {
  _WeatherBackdropPainter({required this.t, required this.mood});
  final double t; // 0..1
  final _WeatherMood mood;

  @override
  void paint(Canvas c, Size s) {
    switch (mood) {
      case _WeatherMood.sun:
        _paintSun(c, s);
        break;
      case _WeatherMood.clouds:
        _paintClouds(c, s, drift: true);
        break;
      case _WeatherMood.rain:
        _paintClouds(c, s, drift: false);
        _paintRain(c, s);
        break;
      case _WeatherMood.snow:
        _paintClouds(c, s, drift: false);
        _paintSnow(c, s);
        break;
    }
  }

  void _paintSun(Canvas c, Size s) {
    final center = Offset(s.width * .82, s.height * .18);
    final r = s.shortestSide * .30;
    final sun = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFF3B0).withOpacity(.75),
          Colors.transparent,
        ],
        stops: const [.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: r));
    c.drawCircle(center, r, sun);

    // very soft rays rotation
    final rays = Paint()
      ..color = Colors.white.withOpacity(.10)
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;
    final a0 = t * 2 * math.pi;
    for (int i = 0; i < 6; i++) {
      final a = a0 + i * (math.pi / 3);
      final p1 = center + Offset(math.cos(a), math.sin(a)) * (r * .55);
      final p2 = center + Offset(math.cos(a), math.sin(a)) * (r * .95);
      c.drawLine(p1, p2, rays);
    }
  }

  void _paintClouds(Canvas c, Size s, {required bool drift}) {
    final cloud = Paint()..color = Colors.white.withOpacity(.20);

    double x(double phase) {
      if (!drift) return phase;
      final dx = math.sin((t * 2 * math.pi) + phase) * 12;
      return phase + dx;
    }

    // three layers, left to right
    _drawCloud(c, Offset(x(40), s.height * .28), 90, cloud);
    _drawCloud(c, Offset(x(s.width - 70), s.height * .34), 110, cloud);
    _drawCloud(c, Offset(x(s.width * .45), s.height * .22), 70, cloud);
  }

  void _drawCloud(Canvas c, Offset o, double w, Paint p) {
    final r = RRect.fromRectAndRadius(
      Rect.fromCenter(center: o, width: w, height: w * .44),
      const Radius.circular(22),
    );
    c.drawRRect(r, p);
    c.drawCircle(o + Offset(-w * .22, -10), w * .18, p);
    c.drawCircle(o + Offset(0, -12), w * .22, p);
    c.drawCircle(o + Offset(w * .22, -8), w * .17, p);
  }

  void _paintRain(Canvas c, Size s) {
    final drops = Paint()
      ..color = Colors.white.withOpacity(.28)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final count = 28;
    for (int i = 0; i < count; i++) {
      final seed = i * 37.0;
      final phase = (t + seed / 100) % 1.0;
      final x = (seed % s.width);
      final y = phase * s.height;
      c.drawLine(Offset(x, y - 10), Offset(x, y + 8), drops);
    }

    // ground mist
    final mist = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          Colors.white.withOpacity(.18),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, s.height - 36, s.width, 36));
    c.drawRect(Rect.fromLTWH(0, s.height - 36, s.width, 36), mist);
  }

  void _paintSnow(Canvas c, Size s) {
    final flake = Paint()..color = Colors.white.withOpacity(.80);
    final count = 18;
    for (int i = 0; i < count; i++) {
      final seed = i * 53.0;
      final phase = (t + seed / 120) % 1.0;
      final x = (seed % s.width) + math.sin(phase * 6.28) * 6;
      final y = phase * s.height;
      c.drawCircle(Offset(x, y), 2.2, flake);
    }
  }

  @override
  bool shouldRepaint(covariant _WeatherBackdropPainter old) =>
      old.t != t || old.mood != mood;
}

// -----------------------------------------------------------------------------

class _Suggestion {
  final String title;
  final String subtitle;
  final String cta;
  final String slug;
  _Suggestion({
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.slug,
  });
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: _wmLavender,
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}

/// Gentle diagonal sheen stripe for premium feel
class _MovingSheenStripe extends StatefulWidget {
  const _MovingSheenStripe();
  @override
  State<_MovingSheenStripe> createState() => _MovingSheenStripeState();
}

class _MovingSheenStripeState extends State<_MovingSheenStripe>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))
        ..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        // move -1.2 .. 1.2 horizontally
        final x = -1.2 + 2.4 * _ctrl.value;
        return Align(
          alignment: Alignment(x, 0),
          child: Transform.rotate(
            angle: -0.35,
            child: IgnorePointer(
              child: Container(
                width: 160,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.white.withOpacity(0.0),
                      Colors.white.withOpacity(0.18),
                      Colors.white.withOpacity(0.0),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
