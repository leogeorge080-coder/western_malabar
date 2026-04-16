import 'package:flutter/material.dart';

class PremiumIconReveal extends StatefulWidget {
  const PremiumIconReveal({
    super.key,
    required this.imagePath,
    this.size = 180,
    this.backgroundColor = const Color(0xFFF4EEDC),
    this.useTile = false,
    this.tileColor = const Color(0xFFF7F7F7),
    this.onCompleted,
  });

  final String imagePath;
  final double size;
  final Color backgroundColor;
  final bool useTile;
  final Color tileColor;
  final VoidCallback? onCompleted;

  @override
  State<PremiumIconReveal> createState() => _PremiumIconRevealState();
}

class _PremiumIconRevealState extends State<PremiumIconReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _iconOpacity;
  late final Animation<double> _iconScale;
  late final Animation<Offset> _iconSlide;
  late final Animation<double> _settleScale;
  late final Animation<double> _tileOpacity;
  late final Animation<double> _tileScale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _tileOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.00, 0.18, curve: Curves.easeOut),
    );

    _tileScale = Tween<double>(begin: 0.975, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.00, 0.22, curve: Curves.easeOutCubic),
      ),
    );

    _iconOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.08, 0.55, curve: Curves.easeOut),
    );

    _iconScale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.08, 0.60, curve: Curves.easeOutCubic),
      ),
    );

    _iconSlide = Tween<Offset>(
      begin: const Offset(0, 0.035),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.08, 0.60, curve: Curves.easeOutCubic),
      ),
    );

    _settleScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.01)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.01, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.62, 1.0),
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
              scale: _settleScale.value,
              child: SizedBox(
                width: size,
                height: size,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (widget.useTile)
                      Opacity(
                        opacity: _tileOpacity.value,
                        child: Transform.scale(
                          scale: _tileScale.value,
                          child: Container(
                            width: size,
                            height: size,
                            decoration: BoxDecoration(
                              color: widget.tileColor,
                              borderRadius: BorderRadius.circular(size * 0.18),
                            ),
                          ),
                        ),
                      ),
                    FadeTransition(
                      opacity: _iconOpacity,
                      child: SlideTransition(
                        position: _iconSlide,
                        child: ScaleTransition(
                          scale: _iconScale,
                          child: Image.asset(
                            widget.imagePath,
                            width: size,
                            height: size,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
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
