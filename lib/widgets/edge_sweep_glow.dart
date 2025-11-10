// lib/widgets/edge_sweep_glow.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

class EdgeSweepGlow extends StatefulWidget {
  const EdgeSweepGlow({
    super.key,
    required this.height,
    this.borderRadius = 28.0,
    this.thickness = 3.8,
    this.blurSigma = 18.0,
    this.opacity = 0.2,
    this.cycle = const Duration(seconds: 14),
  });

  final double height;
  final double borderRadius;
  final double thickness;
  final double blurSigma;
  final double opacity;
  final Duration cycle;

  @override
  State<EdgeSweepGlow> createState() => _EdgeSweepGlowState();
}

class _EdgeSweepGlowState extends State<EdgeSweepGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: widget.cycle)..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            return CustomPaint(
              painter: _EdgeGlowPainter(
                t: _ctrl.value,
                borderRadius: widget.borderRadius,
                thickness: widget.thickness,
                blurSigma: widget.blurSigma,
                opacity: widget.opacity,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EdgeGlowPainter extends CustomPainter {
  _EdgeGlowPainter({
    required this.t,
    required this.borderRadius,
    required this.thickness,
    required this.blurSigma,
    required this.opacity,
  });

  final double t;
  final double borderRadius;
  final double thickness;
  final double blurSigma;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(thickness / 2),
      Radius.circular(borderRadius),
    );

    final sweep = SweepGradient(
      startAngle: 0,
      endAngle: math.pi * 2,
      colors: [
        Colors.transparent,
        const Color(0xFFFFE08A).withOpacity(opacity * .25),
        const Color(0xFFFFC94C).withOpacity(opacity),
        const Color(0xFFFFE08A).withOpacity(opacity * .25),
        Colors.transparent,
      ],
      stops: const [0.00, 0.06, 0.09, 0.12, 0.18],
      transform: GradientRotation(t * math.pi * 2),
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..shader = sweep.createShader(rect)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma)
      ..blendMode = BlendMode.screen;

    canvas.drawRRect(rrect, paint);
    canvas.drawRRect(
      rrect,
      paint..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma * .6),
    );
  }

  @override
  bool shouldRepaint(covariant _EdgeGlowPainter old) =>
      old.t != t ||
      old.borderRadius != borderRadius ||
      old.thickness != thickness ||
      old.blurSigma != blurSigma ||
      old.opacity != opacity;
}
