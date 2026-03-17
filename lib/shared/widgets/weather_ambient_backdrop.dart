import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:western_malabar/shared/services/weather_service.dart';

/// Ambient weather layer that blends with your purple header.
/// Place it under your UI, above the gradient.
/// It auto-fetches (and caches) weather with WeatherService.
class WeatherAmbientBackdrop extends StatefulWidget {
  const WeatherAmbientBackdrop({
    super.key,
    this.city = 'Scunthorpe',
    this.country = 'GB',
    this.apiKey,
    this.height, // if null -> fills parent (Positioned.fill)
    this.intensity = 1.0, // 0.0–1.0 visual strength
  });

  final String city;
  final String country;
  final String? apiKey;
  final double? height;
  final double intensity;

  @override
  State<WeatherAmbientBackdrop> createState() => _WeatherAmbientBackdropState();
}

class _WeatherAmbientBackdropState extends State<WeatherAmbientBackdrop>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  Future<WeatherNow?>? _future;
  WeatherNow? _last;

  late final AnimationController _slow = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 22),
  )..repeat();

  late final AnimationController _med = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 10),
  )..repeat();

  late final AnimationController _fast = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  )..repeat();

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<WeatherNow?> _fetch() async {
    final data = await WeatherService.fetchCurrent(
      city: widget.city,
      country: widget.country,
      apiKey: widget.apiKey,
    );
    if (mounted && data != null) _last = data;
    return data ?? _last;
  }

  @override
  void dispose() {
    _slow.dispose();
    _med.dispose();
    _fast.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final content = FutureBuilder<WeatherNow?>(
      future: _future,
      builder: (context, snap) {
        final w = snap.data ?? _last;
        if (w == null) return const SizedBox.shrink();

        final main = w.main.toLowerCase();
        Widget painter;

        if (main.contains('rain') || main.contains('drizzle')) {
          painter = _RainLayer(t1: _med, t2: _fast, strength: widget.intensity);
        } else if (main.contains('snow')) {
          painter = _SnowLayer(t: _med, strength: widget.intensity);
        } else if (main.contains('cloud')) {
          painter = _CloudsLayer(t: _slow, strength: widget.intensity);
        } else {
          painter = _SunRaysLayer(t: _slow, strength: widget.intensity);
        }

        return RepaintBoundary(
          child: IgnorePointer(
            child: painter,
          ),
        );
      },
    );

    return widget.height == null
        ? Positioned.fill(child: content)
        : SizedBox(height: widget.height, child: content);
  }

  @override
  bool get wantKeepAlive => true;
}

/* ---------------- CLOUDS ---------------- */

class _CloudsLayer extends StatelessWidget {
  const _CloudsLayer({required this.t, required this.strength});
  final AnimationController t;
  final double strength;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: t,
      builder: (_, __) {
        return CustomPaint(
          painter: _CloudsPainter(
            phase: t.value,
            opacity: 0.10 + 0.10 * strength,
          ),
        );
      },
    );
  }
}

class _CloudsPainter extends CustomPainter {
  _CloudsPainter({required this.phase, required this.opacity});
  final double phase;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final base = Paint()..color = Colors.white.withOpacity(opacity);

    void cloud(double y, double scale, double speed, double spread) {
      final x = (phase * speed * w * 2) % (w * 2) - w; // wrap
      final cx = x + spread;
      final o = Offset(cx, y);

      final r = RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: o, width: w * 0.55 * scale, height: h * 0.24 * scale),
        const Radius.circular(22),
      );
      canvas.drawRRect(r, base);
      canvas.drawCircle(o + const Offset(-40, -14) * scale, 22 * scale, base);
      canvas.drawCircle(o + const Offset(0, -18) * scale, 26 * scale, base);
      canvas.drawCircle(o + const Offset(42, -12) * scale, 20 * scale, base);
    }

    cloud(h * .24, 1.00, .40, -20);
    cloud(h * .38, 0.85, .30, 80);
    cloud(h * .55, 0.75, .35, -60);
  }

  @override
  bool shouldRepaint(covariant _CloudsPainter old) =>
      old.phase != phase || old.opacity != opacity;
}

/* ---------------- RAIN ---------------- */

class _RainLayer extends StatelessWidget {
  const _RainLayer(
      {required this.t1, required this.t2, required this.strength});
  final AnimationController t1; // drift
  final AnimationController t2; // streak
  final double strength;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([t1, t2]),
      builder: (_, __) {
        return CustomPaint(
          painter: _RainPainter(
            drift: t1.value,
            fall: t2.value,
            opacity: 0.20 + 0.12 * strength,
          ),
        );
      },
    );
  }
}

class _RainPainter extends CustomPainter {
  _RainPainter(
      {required this.drift, required this.fall, required this.opacity});
  final double drift; // 0..1
  final double fall; // 0..1
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final p = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // diagonal light rain
    const count = 120;
    for (var i = 0; i < count; i++) {
      final fx = (i / count);
      final x = fx * w + math.sin((fx + drift) * math.pi * 2) * 8;
      final y = (fx * h * 1.5 + fall * h) % (h + 60) - 30;
      canvas.drawLine(Offset(x, y), Offset(x - 8, y + 16), p);
    }

    // faint mist at top
    final mist = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x55FFFFFF), Color(0x00FFFFFF)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * .18), mist);
  }

  @override
  bool shouldRepaint(covariant _RainPainter old) =>
      old.drift != drift || old.fall != fall || old.opacity != opacity;
}

/* ---------------- SNOW ---------------- */

class _SnowLayer extends StatefulWidget {
  const _SnowLayer({required this.t, required this.strength});
  final AnimationController t;
  final double strength;

  @override
  State<_SnowLayer> createState() => _SnowLayerState();
}

class _SnowLayerState extends State<_SnowLayer> {
  late final List<_Flake> _flakes;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random(42);
    _flakes = List.generate(80, (i) {
      final s = 1.0 + rnd.nextDouble() * 2.0;
      return _Flake(
        x: rnd.nextDouble(),
        y: rnd.nextDouble(),
        size: s,
        sway: 16 + rnd.nextDouble() * 16,
        speed: .05 + rnd.nextDouble() * .12,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.t,
      builder: (_, __) => CustomPaint(
        painter: _SnowPainter(
          flakes: _flakes,
          t: widget.t.value,
          opacity: 0.20 + 0.12 * widget.strength,
        ),
      ),
    );
  }
}

class _Flake {
  _Flake({
    required this.x,
    required this.y,
    required this.size,
    required this.sway,
    required this.speed,
  });
  double x, y, size, sway, speed;
}

class _SnowPainter extends CustomPainter {
  _SnowPainter({required this.flakes, required this.t, required this.opacity});
  final List<_Flake> flakes;
  final double t;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final p = Paint()..color = Colors.white.withOpacity(opacity);

    for (final f in flakes) {
      final yy = (f.y + f.speed * t) % 1.2;
      final xx = (f.x + 0.002 * math.sin(yy * math.pi * 2)) % 1.0;
      final x = xx * w + math.sin((yy + t) * math.pi * 2) * f.sway * 0.2;
      final y = yy * h;
      canvas.drawCircle(Offset(x, y), f.size, p);
    }
  }

  @override
  bool shouldRepaint(covariant _SnowPainter old) =>
      old.t != t || old.opacity != opacity;
}

/* ---------------- SUN RAYS ---------------- */

class _SunRaysLayer extends StatelessWidget {
  const _SunRaysLayer({required this.t, required this.strength});
  final AnimationController t;
  final double strength;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: t,
      builder: (_, __) {
        return CustomPaint(
          painter: _SunRaysPainter(
            phase: t.value,
            opacity: 0.18 + 0.10 * strength,
          ),
        );
      },
    );
  }
}

class _SunRaysPainter extends CustomPainter {
  _SunRaysPainter({required this.phase, required this.opacity});
  final double phase;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // radial glow at top-left
    final glow = Paint()
      ..shader = RadialGradient(
        center: Alignment(-.9 + .2 * math.sin(phase * math.pi * 2), -.9),
        radius: .9,
        colors: [Colors.white.withOpacity(opacity), Colors.transparent],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, glow);

    // a few soft rays
    final rays = Paint()..color = Colors.white.withOpacity(opacity * 0.6);
    for (var i = 0; i < 5; i++) {
      final shift = (phase + i * .18) % 1.0;
      final x = -w * .4 + shift * w * 1.6;
      final path = Path()
        ..moveTo(x, 0)
        ..lineTo(x + 60, 0)
        ..lineTo(x + 140, h)
        ..lineTo(x + 80, h)
        ..close();
      canvas.drawPath(path, rays);
    }
  }

  @override
  bool shouldRepaint(covariant _SunRaysPainter old) =>
      old.phase != phase || old.opacity != opacity;
}




