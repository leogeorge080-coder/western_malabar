import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Global, draggable "Ask Malabar" bubble that floats above the whole app.
/// Vector coconut-style icon (no PNG). Tap -> haptic + callback; Drag; Double-tap -> reset.
class AskMalabarOverlay {
  static OverlayEntry? _entry;
  static bool get isShown => _entry != null;

  /// Start bottom-right (relative 0..1 in SafeArea)
  static Offset _rel = const Offset(0.90, 0.84);

  static void show(BuildContext context, VoidCallback onTap) {
    if (_entry != null) return;

    final overlay = Overlay.of(context, rootOverlay: true);
    _entry = OverlayEntry(
      opaque: false,
      maintainState: true,
      builder: (ctx) => SafeArea(
        child: _BubbleLayer(
          initialRel: _rel,
          onRelChanged: (v) {
            _rel = v;
            _entry?.markNeedsBuild();
          },
          onTap: () {
            Feedback.forTap(ctx);
            HapticFeedback.mediumImpact();
            onTap();
          },
        ),
      ),
    );
    overlay.insert(_entry!);
  }

  static void hide() {
    _entry?.remove();
    _entry = null;
  }
}

class _BubbleLayer extends StatefulWidget {
  final Offset initialRel; // relative 0..1
  final ValueChanged<Offset> onRelChanged;
  final VoidCallback onTap;

  const _BubbleLayer({
    required this.initialRel,
    required this.onRelChanged,
    required this.onTap,
  });

  @override
  State<_BubbleLayer> createState() => _BubbleLayerState();
}

class _BubbleLayerState extends State<_BubbleLayer> {
  // Absolute position (inside SafeArea)
  Offset? _posPx;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, c) {
      const double bubble = 64; // visual size
      const double pad = 8;

      // Initialize absolute position from relative if needed
      if (_posPx == null) {
        final double x = (widget.initialRel.dx * c.maxWidth) - bubble / 2;
        final double y = (widget.initialRel.dy * c.maxHeight) - bubble / 2;
        _posPx = Offset(
          x.clamp(pad, c.maxWidth - bubble - pad),
          y.clamp(pad, c.maxHeight - bubble - pad),
        );
      }

      final dx = _posPx!.dx;
      final dy = _posPx!.dy;

      return Stack(children: [
        Positioned(
          left: dx,
          top: dy,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onDoubleTap: () {
              setState(() {
                final x = (0.90 * c.maxWidth) - bubble / 2;
                final y = (0.84 * c.maxHeight) - bubble / 2;
                _posPx = Offset(
                  x.clamp(pad, c.maxWidth - bubble - pad),
                  y.clamp(pad, c.maxHeight - bubble - pad),
                );
              });
              widget.onRelChanged(Offset(
                (_posPx!.dx + bubble / 2) / c.maxWidth,
                (_posPx!.dy + bubble / 2) / c.maxHeight,
              ));
            },
            onTap: widget.onTap,
            child: Draggable<int>(
              feedback: const _CoconutBubbleAnimated(size: bubble),
              childWhenDragging: const SizedBox(width: bubble, height: bubble),
              child: const _CoconutBubbleAnimated(size: bubble),
              onDragStarted: () => HapticFeedback.selectionClick(),
              onDragEnd: (details) {
                // Convert global end offset to local overlay coords
                final box = context.findRenderObject() as RenderBox;
                final local = box.globalToLocal(details.offset);
                final newX = (local.dx).clamp(pad, c.maxWidth - bubble - pad);
                final newY = (local.dy).clamp(pad, c.maxHeight - bubble - pad);

                setState(() => _posPx = Offset(newX, newY));
                widget.onRelChanged(Offset(
                  (newX + bubble / 2) / c.maxWidth,
                  (newY + bubble / 2) / c.maxHeight,
                ));
                HapticFeedback.selectionClick();
              },
            ),
          ),
        ),
      ]);
    });
  }
}

/// Animated vector coconut bubble (no assets).
class _CoconutBubbleAnimated extends StatefulWidget {
  const _CoconutBubbleAnimated({this.size = 64});
  final double size;

  @override
  State<_CoconutBubbleAnimated> createState() => _CoconutBubbleAnimatedState();
}

class _CoconutBubbleAnimatedState extends State<_CoconutBubbleAnimated>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;
  late final AnimationController _blinkCtrl;
  late final Animation<double> _blink; // 0 (open) … 1 (closed peak)

  @override
  void initState() {
    super.initState();
    // Gentle breathing
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulse = Tween(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Blink cycle
    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _blink = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 86),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 7),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 7),
    ]).animate(_blinkCtrl);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _blinkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseCtrl, _blinkCtrl]),
      builder: (context, _) {
        final scale = _pulse.value;
        final eyeSquash = 1.0 - (_blink.value * 0.84); // 1 → ~0.16 at peak

        return Transform.scale(
          scale: scale,
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // soft drop shadow
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 16,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                  ),
                ),

                // vector coconut
                CustomPaint(
                  size: Size.square(size),
                  painter: _CoconutPainter(eyeSquash: eyeSquash),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Vector painter for the coconut button (with TWO sprouts on top).
class _CoconutPainter extends CustomPainter {
  _CoconutPainter({required this.eyeSquash});

  final double eyeSquash;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width;

    // --- Base circle with green gradient
    final rect = Rect.fromCircle(center: Offset(s / 2, s / 2), radius: s / 2);
    final baseGrad = const LinearGradient(
      colors: [Color(0xFF48C86D), Color(0xFF2AA15A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(rect);

    final base = Paint()..shader = baseGrad;
    canvas.drawCircle(Offset(s / 2, s / 2), s * 0.48, base);

    // bright rim
    final rim = Paint()
      ..color = const Color(0xFF52D072)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.045;
    canvas.drawCircle(
        Offset(s / 2, s / 2), s * 0.48 - (rim.strokeWidth / 2), rim);

    // glossy highlight
    final gloss = Paint()..color = Colors.white.withValues(alpha: 0.20);
    final glossRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.18, s * 0.10, s * 0.40, s * 0.20),
      Radius.circular(s),
    );
    canvas.drawRRect(glossRRect, gloss);

    // ====== SPROUTS (two curved strokes) ======
    final sproutStroke = Paint()
      ..color = const Color(0xFF2AA15A)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s * 0.06;

    // Left sprout (curve)
    var p = Path();
    p.moveTo(s * 0.50, s * 0.06);
    p.quadraticBezierTo(s * 0.40, s * 0.00, s * 0.34, s * 0.10);
    canvas.drawPath(p, sproutStroke);

    // Right sprout (mirror)
    p = Path();
    p.moveTo(s * 0.50, s * 0.06);
    p.quadraticBezierTo(s * 0.60, s * 0.00, s * 0.66, s * 0.10);
    canvas.drawPath(p, sproutStroke);

    // Tiny tips on sprouts
    final tip = Paint()..color = const Color(0xFF48C86D);
    canvas.drawCircle(Offset(s * 0.34, s * 0.10), s * 0.025, tip);
    canvas.drawCircle(Offset(s * 0.66, s * 0.10), s * 0.025, tip);

    // ====== Small leaves near base of sprouts ======
    final leafPaint = Paint()..color = const Color(0xFF48C86D);

    // left leaf (rounded rect, rotated)
    canvas.save();
    canvas.translate(s * 0.37, s * 0.12);
    canvas.rotate(-0.55);
    final leftLeaf = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, 18, 14).scaleTo(s * 0.16, s * 0.12),
      Radius.circular(s),
    );
    canvas.drawRRect(leftLeaf, leafPaint);
    canvas.restore();

    // right leaf
    canvas.save();
    canvas.translate(s * 0.63, s * 0.12);
    canvas.rotate(0.55);
    final rightLeaf = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, 18, 14).scaleTo(s * 0.16, s * 0.12),
      Radius.circular(s),
    );
    canvas.drawRRect(rightLeaf, leafPaint);
    canvas.restore();

    // ====== Purple face (rounded bean) ======
    final facePaint = Paint()..color = const Color(0xFF5A2D82);
    final faceRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.19, s * 0.30, s * 0.62, s * 0.46),
      Radius.circular(s * 0.28),
    );
    canvas.drawRRect(faceRect, facePaint);

    // subtle shadow under face
    final faceShadow = Paint()
      ..color = const Color(0x33000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(faceRect, faceShadow);

    // ====== Eyes (blink squash) ======
    final eyePaint = Paint()..color = Colors.white;
    final eyeR = s * 0.115 / 2;
    final squashY = eyeSquash.clamp(0.15, 1.0);

    void drawEye(Offset c) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.scale(1.0, squashY);
      canvas.drawCircle(Offset.zero, eyeR, eyePaint);
      canvas.restore();
    }

    drawEye(Offset(s * 0.38, s * 0.53));
    drawEye(Offset(s * 0.62, s * 0.53));

    // tiny sparkle
    final spark = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(s * 0.70, s * 0.70), s * 0.02, spark);
    canvas.drawCircle(Offset(s * 0.73, s * 0.66), s * 0.012, spark);
  }

  @override
  bool shouldRepaint(covariant _CoconutPainter oldDelegate) {
    return oldDelegate.eyeSquash != eyeSquash;
  }
}

/// Helper to scale a Rect to a target size (used for leaves)
extension on Rect {
  Rect scaleTo(double w, double h) => Rect.fromLTWH(left, top, w, h);
}
