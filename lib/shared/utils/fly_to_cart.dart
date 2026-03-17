import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

Future<void> flyToCart({
  required BuildContext context,
  required GlobalKey cartKey,
  required GlobalKey imageKey,
}) async {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  final cartContext = cartKey.currentContext;
  final imageContext = imageKey.currentContext;
  if (cartContext == null || imageContext == null) return;

  final cartObject = cartContext.findRenderObject();
  final imageObject = imageContext.findRenderObject();

  if (cartObject is! RenderBox || imageObject is! RenderBox) return;
  if (!cartObject.attached || !imageObject.attached) return;
  if (!cartObject.hasSize || !imageObject.hasSize) return;

  final imageTopLeft = imageObject.localToGlobal(Offset.zero);
  final imageSize = imageObject.size;

  final cartTopLeft = cartObject.localToGlobal(Offset.zero);
  final cartSize = cartObject.size;

  final start = Offset(
    imageTopLeft.dx + imageSize.width * 0.5,
    imageTopLeft.dy + imageSize.height * 0.5,
  );

  final end = Offset(
    cartTopLeft.dx + cartSize.width * 0.5,
    cartTopLeft.dy + cartSize.height * 0.45,
  );

  var removed = false;

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _FlyingCartParticle(
      start: start,
      end: end,
      startSize: imageSize.shortestSide.clamp(26.0, 52.0),
    ),
  );

  try {
    overlay.insert(entry);
  } catch (_) {
    return;
  }

  await Future.delayed(const Duration(milliseconds: 760));

  if (!removed) {
    removed = true;
    try {
      entry.remove();
    } catch (_) {
      // Ignore remove race during rebuild/navigation.
    }
  }
}

class _FlyingCartParticle extends StatefulWidget {
  const _FlyingCartParticle({
    required this.start,
    required this.end,
    required this.startSize,
  });

  final Offset start;
  final Offset end;
  final double startSize;

  @override
  State<_FlyingCartParticle> createState() => _FlyingCartParticleState();
}

class _FlyingCartParticleState extends State<_FlyingCartParticle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _t;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );

    _t = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubicEmphasized,
    );

    unawaited(_controller.forward());
  }

  Offset _positionAt(double t) {
    final control = Offset(
      lerpDouble(widget.start.dx, widget.end.dx, 0.55)!,
      widget.start.dy - 90,
    );

    final p0 = widget.start;
    final p1 = control;
    final p2 = widget.end;

    final oneMinusT = 1 - t;

    final x = oneMinusT * oneMinusT * p0.dx +
        2 * oneMinusT * t * p1.dx +
        t * t * p2.dx;

    final y = oneMinusT * oneMinusT * p0.dy +
        2 * oneMinusT * t * p1.dy +
        t * t * p2.dy;

    return Offset(x, y);
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _t,
        builder: (_, __) {
          final t = _t.value;
          final pos = _positionAt(t);

          final scale = lerpDouble(1.0, 0.38, t)!;
          final rawOpacity =
              t < 0.82 ? 1.0 : lerpDouble(1.0, 0.0, (t - 0.82) / 0.18)!;
          final opacity = rawOpacity.clamp(0.0, 1.0).toDouble();

          final glowOpacity = t < 0.7 ? 0.18 : 0.08;

          return Stack(
            children: [
              Positioned(
                left: pos.dx - (widget.startSize * scale) / 2,
                top: pos.dy - (widget.startSize * scale) / 2,
                child: Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: widget.startSize,
                      height: widget.startSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF5A2D82)
                                .withOpacity(glowOpacity),
                            blurRadius: 18,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.shopping_bag_rounded,
                        size: 28,
                        color: Color(0xFF5A2D82),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}




