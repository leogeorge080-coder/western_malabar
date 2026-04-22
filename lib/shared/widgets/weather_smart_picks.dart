// lib/widgets/weather_smart_picks.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:western_malabar/shared/services/weather_service.dart';

const _wmPurple = Color(0xFF4B208C);
const _wmLavender = Color(0xFFE5DBFF);

class WeatherSmartPicks extends StatefulWidget {
  const WeatherSmartPicks({
    super.key,
    this.city = 'Scunthorpe',
    this.country = 'GB',
    this.apiKey,
    this.onShopTap,
  });

  final String city;
  final String country;
  final String? apiKey;
  final void Function(String slug)? onShopTap;

  @override
  State<WeatherSmartPicks> createState() => _WeatherSmartPicksState();
}

class _WeatherSmartPicksState extends State<WeatherSmartPicks>
    with AutomaticKeepAliveClientMixin {
  Future<WeatherNow?>? _future;
  WeatherNow? _last; // keep last good result to avoid visual reset

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  @override
  void didUpdateWidget(covariant WeatherSmartPicks oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only refetch when parameters actually change
    if (oldWidget.city != widget.city ||
        oldWidget.country != widget.country ||
        oldWidget.apiKey != widget.apiKey) {
      _future = _fetch();
    }
  }

  Future<WeatherNow?> _fetch() async {
    final data = await WeatherService.fetchCurrent(
      city: widget.city,
      country: widget.country,
      apiKey: widget.apiKey,
    );
    if (mounted && data != null) _last = data;
    return data ?? _last; // fall back to last to prevent flicker
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // for keep-alive
    return FutureBuilder<WeatherNow?>(
      future: _future,
      builder: (context, snap) {
        final data = snap.data ?? _last;
        if (data == null) {
          return const _SkeletonCard();
        }
        final s = _suggestFor(data);

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: RepaintBoundary(
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_wmPurple, Color(0xFF9C6ADE)],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const _MovingSheenStripe(),
                  // Weather glyph blended into the card (no network image = no flicker)
                  Positioned.fill(child: _WeatherGlyph(data)),
                  Row(
                    children: [
                      const SizedBox(width: 14),
                      // Icon bubble – now we draw glyph inside so it never flashes
                      Container(
                        height: 64,
                        width: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.18),
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: Colors.white.withOpacity(.35)),
                        ),
                        alignment: Alignment.center,
                        child: SizedBox(
                          height: 38,
                          width: 38,
                          child: _MiniGlyph(data),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: DefaultTextStyle(
                          style: const TextStyle(color: Colors.white),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                s.subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${data.tempC.toStringAsFixed(0)}°C • ${widget.city}',
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
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: _wmPurple,
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => widget.onShopTap?.call(s.slug),
                          child: Text(
                            s.cta,
                            style: const TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;

  _Suggestion _suggestFor(WeatherNow w) {
    final t = w.tempC;
    final main = w.main.toLowerCase();
    final windy = w.windKph > 28;

    if (main.contains('rain') || main.contains('drizzle')) {
      return _Suggestion(
          'Rainy Day Comforts',
          'Hot chai, pakoras & ready curries.',
          'Shop Picks',
          'collections/rain-comforts');
    }
    if (main.contains('snow')) {
      return _Suggestion('Warm & Hearty', 'Soups, ready gravies & masalas.',
          'Get Cozy', 'collections/warm-hearty');
    }
    if (t <= 8) {
      return _Suggestion(
          'Cold Weather Staples',
          'Parathas, soups, masala chai.',
          'Warm Me',
          'collections/cold-staples');
    }
    if (t >= 24) {
      return _Suggestion(
          'Cool & Fresh',
          'Buttermilk, tender coconut & ice creams.',
          'Cool Me',
          'collections/cool-refreshers');
    }
    if (windy) {
      return _Suggestion(
          'Quick Bite, Quick Day',
          'Ready mixes & grab-n-go snacks.',
          'Quick Picks',
          'collections/quick-bites');
    }
    if (main.contains('cloud')) {
      return _Suggestion(
          'Cloudy Day Specials',
          'Filter coffee & evening snacks.',
          'Shop Now',
          'collections/cloudy-specials');
    }
    return _Suggestion('Today’s Fresh Picks', 'Veg, fruits & fresh staples.',
        'Browse', 'collections/fresh-picks');
  }
}

class _Suggestion {
  final String title, subtitle, cta, slug;
  _Suggestion(this.title, this.subtitle, this.cta, this.slug);
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: _wmLavender,
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}

/// ——— Moving sheen (unchanged) ———
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
                      Colors.white.withOpacity(0.22),
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

/// ——— Big blended glyph behind content ———
class _WeatherGlyph extends StatelessWidget {
  const _WeatherGlyph(this.w);
  final WeatherNow w;

  @override
  Widget build(BuildContext context) {
    final main = w.main.toLowerCase();
    if (main.contains('rain') || main.contains('drizzle')) {
      return CustomPaint(painter: _RainPainter());
    }
    if (main.contains('snow')) {
      return CustomPaint(painter: _SnowPainter());
    }
    if (main.contains('cloud')) {
      return CustomPaint(painter: _CloudsPainter());
    }
    return CustomPaint(painter: _SunPainter());
  }
}

/// ——— Tiny glyph for the left bubble ———
class _MiniGlyph extends StatelessWidget {
  const _MiniGlyph(this.w);
  final WeatherNow w;
  @override
  Widget build(BuildContext context) {
    final main = w.main.toLowerCase();
    if (main.contains('rain') || main.contains('drizzle')) {
      return CustomPaint(painter: _MiniRainPainter());
    }
    if (main.contains('snow')) {
      return CustomPaint(painter: _MiniSnowPainter());
    }
    if (main.contains('cloud')) {
      return CustomPaint(painter: _MiniCloudPainter());
    }
    return CustomPaint(painter: _MiniSunPainter());
  }
}

/* ==== Painters (same visual style, lightweight) ==== */

class _CloudsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final c = Paint()..color = Colors.white.withOpacity(.12);

    void cloud(Offset o, double s) {
      final r = RRect.fromRectAndRadius(
        Rect.fromCenter(center: o, width: w * s, height: h * s * .55),
        const Radius.circular(22),
      );
      canvas.drawRRect(r, c);
      canvas.drawCircle(o + Offset(-w * .22 * s, -10), w * .18 * s, c);
      canvas.drawCircle(o + Offset(0, -12), w * .22 * s, c);
      canvas.drawCircle(o + Offset(w * .22 * s, -8), w * .17 * s, c);
    }

    cloud(Offset(w * .55, h * .45), .55);
    cloud(Offset(w * .75, h * .58), .45);
    cloud(Offset(w * .35, h * .56), .40);
  }

  @override
  bool shouldRepaint(covariant _CloudsPainter oldDelegate) => false;
}

class _RainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final p = Paint()
      ..color = Colors.white.withOpacity(.22)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 28; i++) {
      final x = (i / 28.0) * w;
      final y = (i.isEven ? h * .40 : h * .55);
      canvas.drawLine(Offset(x, y), Offset(x - 8, y + 16), p);
    }
  }

  @override
  bool shouldRepaint(covariant _RainPainter oldDelegate) => false;
}

class _SnowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final dot = Paint()..color = Colors.white.withOpacity(.24);

    for (var i = 0; i < 26; i++) {
      final x = (i / 26.0) * w;
      final y = (i.isOdd ? h * .45 : h * .60);
      canvas.drawCircle(Offset(x, y), 2.2, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _SnowPainter oldDelegate) => false;
}

class _SunPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final center = Offset(w * .48, h * .48);
    final sun = Paint()..color = Colors.white.withOpacity(.95);
    canvas.drawCircle(center, w * .20, sun);

    final ray = Paint()
      ..color = Colors.white.withOpacity(.75)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 10; i++) {
      final a = i / 10 * math.pi * 2;
      final p1 = center + Offset(w * .26 * math.cos(a), h * .26 * math.sin(a));
      final p2 = center + Offset(w * .36 * math.cos(a), h * .36 * math.sin(a));
      canvas.drawLine(p1, p2, ray);
    }
  }

  @override
  bool shouldRepaint(covariant _SunPainter oldDelegate) => false;
}

/* Mini versions for the 64×64 bubble */

class _MiniCloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final c = Paint()..color = Colors.white;
    final o = Offset(w * .5, h * .58);
    final r = RRect.fromRectAndRadius(
      Rect.fromCenter(center: o, width: w * .88, height: h * .54),
      const Radius.circular(12),
    );
    canvas.drawRRect(r, c);
    canvas.drawCircle(o + const Offset(-12, -8), 12, c);
    canvas.drawCircle(o + const Offset(0, -10), 13, c);
    canvas.drawCircle(o + const Offset(12, -6), 11, c);
  }

  @override
  bool shouldRepaint(covariant _MiniCloudPainter oldDelegate) => false;
}

class _MiniRainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 6; i++) {
      final x = 8 + i * 6;
      canvas.drawLine(Offset(x.toDouble(), 30), Offset(x - 3.0, 36), p);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniRainPainter oldDelegate) => false;
}

class _MiniSnowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint()..color = Colors.white;
    for (var i = 0; i < 6; i++) {
      canvas.drawCircle(Offset(10 + i * 6.0, 34), 1.8, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniSnowPainter oldDelegate) => false;
}

class _MiniSunPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 12, c);
  }

  @override
  bool shouldRepaint(covariant _MiniSunPainter oldDelegate) => false;
}
