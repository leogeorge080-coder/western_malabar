import 'dart:async';
import 'package:flutter/material.dart';

class WMPromoCarousel extends StatefulWidget {
  const WMPromoCarousel({
    super.key,
    required this.items,
    this.height = 120,
    this.interval = const Duration(seconds: 4),
    this.onTap,
  });

  /// Each item: icon, title, subtitle
  final List<_PromoItem> items;

  /// Banner height
  final double height;

  /// Auto-scroll interval
  final Duration interval;

  /// Tap callback with index
  final void Function(int index)? onTap;

  @override
  State<WMPromoCarousel> createState() => _WMPromoCarouselState();
}

class _WMPromoCarouselState extends State<WMPromoCarousel> {
  late final PageController _controller;
  Timer? _timer;
  int _index = 0;
  bool _userTouching = false;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 1);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.interval, (_) {
      if (!mounted || _userTouching) return;
      final next = (_index + 1) % widget.items.length;
      _animateTo(next);
    });
  }

  void _animateTo(int page) {
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final purple = const Color(0xFF5A2D82);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Listener(
          onPointerDown: (_) {
            _userTouching = true;
            _timer?.cancel();
          },
          onPointerUp: (_) {
            _userTouching = false;
            _startTimer();
          },
          child: SizedBox(
            height: widget.height,
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (i) => setState(() => _index = i),
              itemCount: widget.items.length,
              itemBuilder: (context, i) {
                final it = widget.items[i];
                return _GradientGoldCard(
                  icon: it.icon,
                  title: it.title,
                  subtitle: it.subtitle,
                  onTap: () => widget.onTap?.call(i),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.items.length, (i) {
            final selected = i == _index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: selected ? 18 : 6,
              decoration: BoxDecoration(
                color: selected ? purple : purple.withOpacity(0.25),
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
      ],
    );
  }
}

/// Data helper you’ll pass from screen
class _PromoItem {
  const _PromoItem(
      {required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;
}

/// Export a public factory so you can create items from outside
List<_PromoItem> wmPromoItems({
  required IconData i1,
  required String t1,
  required String s1,
  required IconData i2,
  required String t2,
  required String s2,
  required IconData i3,
  required String t3,
  required String s3,
}) =>
    [
      _PromoItem(icon: i1, title: t1, subtitle: s1),
      _PromoItem(icon: i2, title: t2, subtitle: s2),
      _PromoItem(icon: i3, title: t3, subtitle: s3),
    ];

/// Card style (matches your brand)
class _GradientGoldCard extends StatelessWidget {
  const _GradientGoldCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF5A2D82);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF0C53E), Color(0xFFFFD96A), Color(0xFFE4B42F)],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
                color: Color(0x1A000000), blurRadius: 10, offset: Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.local_fire_department_outlined,
                  color: purple),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: purple,
                      )),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontSize: 13, color: Colors.black87)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}
