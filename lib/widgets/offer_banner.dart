import 'package:flutter/material.dart';

enum WMBannerStyle { gradientGold, glass, outline }

class WMBanner extends StatelessWidget {
  const WMBanner({
    super.key,
    required this.style,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final WMBannerStyle style;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  // Brand palette
  static const _purple = Color(0xFF5A2D82);
  static const _gold = Color(0xFFF0C53E);
  static const _goldDeep = Color(0xFFE4B42F);
  static const _goldLight = Color(0xFFFFF3C7);

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case WMBannerStyle.gradientGold:
        return _GradientGold(
            icon: icon, title: title, subtitle: subtitle, onTap: onTap);
      case WMBannerStyle.glass:
        return _Glass(
            icon: icon, title: title, subtitle: subtitle, onTap: onTap);
      case WMBannerStyle.outline:
        return _Outline(
            icon: icon, title: title, subtitle: subtitle, onTap: onTap);
    }
  }
}

/// 1) Hero: rich gradient gold card
class _GradientGold extends StatelessWidget {
  const _GradientGold({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  static const _purple = Color(0xFF5A2D82);
  static const _gold = Color(0xFFF0C53E);
  static const _goldDeep = Color(0xFFE4B42F);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_gold, Color(0xFFFFD96A), _goldDeep],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
                color: Color(0x26000000), blurRadius: 12, offset: Offset(0, 8)),
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
              child: Icon(icon, color: _purple),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: _purple,
                      )),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      )),
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

/// 2) Elegant: glass card on a soft gold wash
class _Glass extends StatelessWidget {
  const _Glass({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  static const _purple = Color(0xFF5A2D82);
  static const _goldLight = Color(0xFFFFF3C7);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(2), // thin border shimmer
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0x22FFFFFF), Color(0x11FFFFFF)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white, // “glass” feel against gold wash background
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 10,
                  offset: Offset(0, 6)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 36,
                decoration: BoxDecoration(
                  color: _purple,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 12),
              Icon(icon, color: _purple),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: _purple)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black87)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.black45),
            ],
          ),
        ),
      ),
    );
  }
}

/// 3) Minimal: outlined pill with icon chip + tiny CTA
class _Outline extends StatelessWidget {
  const _Outline({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  static const _purple = Color(0xFF5A2D82);
  static const _gold = Color(0xFFF0C53E);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _gold, width: 1.2),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _purple.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: _purple),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: _purple)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style:
                          const TextStyle(fontSize: 13, color: Colors.black87)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _purple,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Details',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
