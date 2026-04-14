import 'package:flutter/material.dart';

class PremiumIconReveal extends StatefulWidget {
  const PremiumIconReveal({
    super.key,
    required this.imagePath,
    this.size = 180,
    this.backgroundColor = const Color(0xFFFAFAFA),
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
  late final Animation<double> _shadowOpacity;
  late final Animation<double> _tileOpacity;
  late final Animation<double> _tileScale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1450),
    );

    _tileOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.00, 0.20, curve: Curves.easeOut),
    );

    _tileScale = Tween<double>(begin: 0.965, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.00, 0.24, curve: Curves.easeOutCubic),
      ),
    );

    _iconOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.12, 0.58, curve: Curves.easeOut),
    );

    _iconScale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.12, 0.62, curve: Curves.easeOutQuart),
      ),
    );

    _iconSlide = Tween<Offset>(
      begin: const Offset(0, 0.045),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.12, 0.62, curve: Curves.easeOutCubic),
      ),
    );

    _shadowOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.14, 0.52, curve: Curves.easeOut),
      ),
    );

    _settleScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.014)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 52,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.014, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 48,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.72, 1.0),
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
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.10),
                                  blurRadius: size * 0.07,
                                  offset: Offset(0, size * 0.022),
                                ),
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.70),
                                  blurRadius: size * 0.028,
                                  offset: Offset(0, -size * 0.008),
                                  spreadRadius: -1,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    FadeTransition(
                      opacity: _shadowOpacity,
                      child: Transform.translate(
                        offset: Offset(0, size * 0.02),
                        child: Container(
                          width: size * 0.74,
                          height: size * 0.74,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: size * 0.08,
                                spreadRadius: size * 0.005,
                              ),
                            ],
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
