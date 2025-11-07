import 'dart:async';
import 'package:flutter/material.dart';

/// Single promo definition used by the carousel.
class WmPromoItem {
  final String title;
  final String subtitle;
  final IconData icon;

  /// Optional custom gradient (defaults to WM gold -> warm gold).
  final Color? startColor;
  final Color? endColor;

  /// Optional tap.
  final VoidCallback? onTap;

  const WmPromoItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.startColor,
    this.endColor,
    this.onTap,
  });
}

/// Auto-scrolling, pill-rounded promo banner with dots.
class WMPromoCarousel extends StatefulWidget {
  const WMPromoCarousel({
    super.key,
    required this.items,
    this.height = 120,
    this.autoPlay = true,
    this.interval = const Duration(seconds: 4),
    this.borderRadius = 24,
    this.padding = const EdgeInsets.symmetric(vertical: 6),
  });

  final List<WmPromoItem> items;
  final double height;
  final bool autoPlay;
  final Duration interval;
  final double borderRadius;
  final EdgeInsets padding;

  @override
  State<WMPromoCarousel> createState() => _WMPromoCarouselState();
}

class _WMPromoCarouselState extends State<WMPromoCarousel> {
  late final PageController _pc;
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _pc = PageController(viewportFraction: 0.96);
    _maybeStartTimer();
  }

  void _maybeStartTimer() {
    if (!widget.autoPlay || widget.items.length <= 1) return;
    _timer?.cancel();
    _timer = Timer.periodic(widget.interval, (_) {
      if (!mounted) return;
      final next = (_index + 1) % widget.items.length;
      _pc.animateToPage(
        next,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void didUpdateWidget(covariant WMPromoCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.autoPlay != widget.autoPlay ||
        oldWidget.items.length != widget.items.length ||
        oldWidget.interval != widget.interval) {
      _maybeStartTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: widget.padding,
      child: Column(
        children: [
          SizedBox(
            height: widget.height,
            child: PageView.builder(
              controller: _pc,
              onPageChanged: (i) => setState(() => _index = i),
              itemCount: widget.items.length,
              itemBuilder: (context, i) => _PromoCard(
                item: widget.items[i],
                borderRadius: widget.borderRadius,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _Dots(count: widget.items.length, index: _index),
        ],
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.item, required this.borderRadius});

  final WmPromoItem item;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final start = item.startColor ?? const Color(0xFFF3C24D); // WM gold
    final end = item.endColor ?? const Color(0xFFFFE085); // warm gold

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: item.onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [start, end],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(item.icon, size: 28, color: Colors.deepOrange),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF5A2D82),
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          letterSpacing: .2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.black54),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 22 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: active ? const Color(0xFF5A2D82) : const Color(0x335A2D82),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
