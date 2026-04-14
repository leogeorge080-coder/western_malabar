import 'dart:math' as math;
import 'package:flutter/material.dart';

class MhMonogramAnimation extends StatefulWidget {
  const MhMonogramAnimation({
    super.key,
    this.size = 180,
    this.backgroundColor = const Color(0xFFFAFAFA),
    this.tileColor = const Color(0xFFF7F7F7),
    this.monogramColor = const Color(0xFF111111),
    this.accentColor = const Color(0xFFD4AF37),
    this.showTile = true,
    this.onCompleted,
  });

  final double size;
  final Color backgroundColor;
  final Color tileColor;
  final Color monogramColor;
  final Color accentColor;
  final bool showTile;
  final VoidCallback? onCompleted;

  @override
  State<MhMonogramAnimation> createState() => _MhMonogramAnimationState();
}

class _MhMonogramAnimationState extends State<MhMonogramAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _tileOpacity;
  late final Animation<double> _tileScale;

  late final Animation<double> _monogramOpacity;
  late final Animation<Offset> _monogramSlide;
  late final Animation<double> _monogramScale;

  late final Animation<double> _accentOpacity;
  late final Animation<Offset> _accentSlide;

  late final Animation<double> _finalSettleScale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1450),
    );

    _tileOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.00, 0.18, curve: Curves.easeOut),
    );

    _tileScale = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.00, 0.24, curve: Curves.easeOutCubic),
      ),
    );

    _monogramOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.18, 0.62, curve: Curves.easeOut),
    );

    _monogramSlide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.18, 0.62, curve: Curves.easeOutCubic),
      ),
    );

    _monogramScale = Tween<double>(begin: 0.985, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.18, 0.62, curve: Curves.easeOutQuart),
      ),
    );

    _accentOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.58, 0.82, curve: Curves.easeOut),
    );

    _accentSlide = Tween<Offset>(
      begin: const Offset(-0.015, 0.02),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.58, 0.82, curve: Curves.easeOutCubic),
      ),
    );

    _finalSettleScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.012)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.012, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 45,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.78, 1.0),
      ),
    );

    _controller.forward().whenComplete(() {
      if (mounted) widget.onCompleted?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;

    return ColoredBox(
      color: widget.backgroundColor,
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Transform.scale(
              scale: _finalSettleScale.value,
              child: SizedBox(
                width: size,
                height: size,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (widget.showTile)
                      Opacity(
                        opacity: _tileOpacity.value,
                        child: Transform.scale(
                          scale: _tileScale.value,
                          child: _Tile(size: size, color: widget.tileColor),
                        ),
                      ),
                    FadeTransition(
                      opacity: _monogramOpacity,
                      child: SlideTransition(
                        position: _monogramSlide,
                        child: ScaleTransition(
                          scale: _monogramScale,
                          child: _MonogramMark(
                            size: size,
                            monogramColor: widget.monogramColor,
                          ),
                        ),
                      ),
                    ),
                    FadeTransition(
                      opacity: _accentOpacity,
                      child: SlideTransition(
                        position: _accentSlide,
                        child: _RiceAccent(
                          size: size,
                          color: widget.accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: size * 0.075,
            offset: Offset(0, size * 0.022),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.75),
            blurRadius: size * 0.03,
            offset: Offset(0, -size * 0.01),
            spreadRadius: -1,
          ),
        ],
      ),
    );
  }
}

class _MonogramMark extends StatelessWidget {
  const _MonogramMark({
    required this.size,
    required this.monogramColor,
  });

  final double size;
  final Color monogramColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 0.74,
      height: size * 0.52,
      child: CustomPaint(
        painter: _MonogramPainter(color: monogramColor),
      ),
    );
  }
}

class _RiceAccent extends StatelessWidget {
  const _RiceAccent({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(size * 0.065, -size * 0.165),
      child: SizedBox(
        width: size * 0.18,
        height: size * 0.11,
        child: CustomPaint(
          painter: _RiceAccentPainter(color: color),
        ),
      ),
    );
  }
}

class _MonogramPainter extends CustomPainter {
  const _MonogramPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final mPath = Path()
      ..moveTo(size.width * 0.10, size.height * 0.90)
      ..quadraticBezierTo(
        size.width * 0.15,
        size.height * 0.90,
        size.width * 0.15,
        size.height * 0.78,
      )
      ..lineTo(size.width * 0.19, size.height * 0.18)
      ..quadraticBezierTo(
        size.width * 0.20,
        size.height * 0.08,
        size.width * 0.07,
        size.height * 0.07,
      )
      ..cubicTo(
        size.width * 0.12,
        size.height * 0.04,
        size.width * 0.20,
        size.height * 0.08,
        size.width * 0.26,
        size.height * 0.22,
      )
      ..lineTo(size.width * 0.43, size.height * 0.72)
      ..lineTo(size.width * 0.60, size.height * 0.22)
      ..quadraticBezierTo(
        size.width * 0.64,
        size.height * 0.10,
        size.width * 0.69,
        size.height * 0.08,
      )
      ..lineTo(size.width * 0.76, size.height * 0.08)
      ..lineTo(size.width * 0.67, size.height * 0.08)
      ..quadraticBezierTo(
        size.width * 0.63,
        size.height * 0.10,
        size.width * 0.62,
        size.height * 0.19,
      )
      ..lineTo(size.width * 0.52, size.height * 0.88)
      ..quadraticBezierTo(
        size.width * 0.50,
        size.height * 0.94,
        size.width * 0.47,
        size.height * 0.95,
      )
      ..lineTo(size.width * 0.43, size.height * 0.95)
      ..lineTo(size.width * 0.25, size.height * 0.43)
      ..lineTo(size.width * 0.21, size.height * 0.84)
      ..quadraticBezierTo(
        size.width * 0.21,
        size.height * 0.90,
        size.width * 0.28,
        size.height * 0.90,
      )
      ..close();

    final hPath = Path()
      ..moveTo(size.width * 0.63, size.height * 0.12)
      ..lineTo(size.width * 0.80, size.height * 0.12)
      ..quadraticBezierTo(
        size.width * 0.88,
        size.height * 0.12,
        size.width * 0.88,
        size.height * 0.18,
      )
      ..quadraticBezierTo(
        size.width * 0.84,
        size.height * 0.16,
        size.width * 0.82,
        size.height * 0.22,
      )
      ..lineTo(size.width * 0.82, size.height * 0.78)
      ..quadraticBezierTo(
        size.width * 0.82,
        size.height * 0.90,
        size.width * 0.90,
        size.height * 0.90,
      )
      ..lineTo(size.width * 0.75, size.height * 0.90)
      ..quadraticBezierTo(
        size.width * 0.79,
        size.height * 0.90,
        size.width * 0.79,
        size.height * 0.82,
      )
      ..lineTo(size.width * 0.79, size.height * 0.55)
      ..lineTo(size.width * 0.60, size.height * 0.55)
      ..lineTo(size.width * 0.60, size.height * 0.82)
      ..quadraticBezierTo(
        size.width * 0.60,
        size.height * 0.90,
        size.width * 0.64,
        size.height * 0.90,
      )
      ..lineTo(size.width * 0.50, size.height * 0.90)
      ..quadraticBezierTo(
        size.width * 0.58,
        size.height * 0.90,
        size.width * 0.58,
        size.height * 0.78,
      )
      ..lineTo(size.width * 0.58, size.height * 0.22)
      ..quadraticBezierTo(
        size.width * 0.57,
        size.height * 0.16,
        size.width * 0.53,
        size.height * 0.15,
      )
      ..quadraticBezierTo(
        size.width * 0.57,
        size.height * 0.12,
        size.width * 0.63,
        size.height * 0.12,
      )
      ..close();

    final bridgePath = Path()
      ..moveTo(size.width * 0.36, size.height * 0.64)
      ..quadraticBezierTo(
        size.width * 0.48,
        size.height * 0.58,
        size.width * 0.60,
        size.height * 0.59,
      )
      ..lineTo(size.width * 0.80, size.height * 0.59)
      ..lineTo(size.width * 0.80, size.height * 0.55)
      ..lineTo(size.width * 0.60, size.height * 0.55)
      ..quadraticBezierTo(
        size.width * 0.47,
        size.height * 0.55,
        size.width * 0.34,
        size.height * 0.61,
      )
      ..close();

    canvas.save();
    canvas.translate(0, 1.5);
    canvas.drawPath(mPath, shadowPaint);
    canvas.drawPath(hPath, shadowPaint);
    canvas.drawPath(bridgePath, shadowPaint);
    canvas.restore();

    canvas.drawPath(mPath, paint);
    canvas.drawPath(hPath, paint);
    canvas.drawPath(bridgePath, paint);
  }

  @override
  bool shouldRepaint(covariant _MonogramPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _RiceAccentPainter extends CustomPainter {
  const _RiceAccentPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stem = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.06
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final grainPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final stemPath = Path()
      ..moveTo(size.width * 0.12, size.height * 0.82)
      ..quadraticBezierTo(
        size.width * 0.34,
        size.height * 0.44,
        size.width * 0.84,
        size.height * 0.20,
      );

    canvas.drawPath(stemPath, stem);

    _drawGrain(
      canvas,
      Rect.fromCenter(
        center: Offset(size.width * 0.46, size.height * 0.46),
        width: size.width * 0.22,
        height: size.height * 0.40,
      ),
      -0.45,
      grainPaint,
    );

    _drawGrain(
      canvas,
      Rect.fromCenter(
        center: Offset(size.width * 0.69, size.height * 0.27),
        width: size.width * 0.24,
        height: size.height * 0.42,
      ),
      -0.72,
      grainPaint,
    );
  }

  void _drawGrain(
    Canvas canvas,
    Rect rect,
    double rotation,
    Paint paint,
  ) {
    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.rotate(rotation);

    final grain = Path()
      ..moveTo(0, -rect.height / 2)
      ..quadraticBezierTo(rect.width / 2, 0, 0, rect.height / 2)
      ..quadraticBezierTo(-rect.width / 2, 0, 0, -rect.height / 2)
      ..close();

    canvas.drawPath(grain, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RiceAccentPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
