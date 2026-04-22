import 'package:flutter/material.dart';

class QuickCat {
  final String slug;
  final String label;
  final IconData icon;
  final List<Color> colors; // [start, end]
  const QuickCat({
    required this.slug,
    required this.label,
    required this.icon,
    required this.colors,
  });
}

class WmQuickCategories extends StatelessWidget {
  const WmQuickCategories({
    super.key,
    required this.items,
    this.onTap,
    this.height = 60,
    this.itemWidth = 160,
  });

  final List<QuickCat> items;
  final void Function(String slug)? onTap;
  final double height;
  final double itemWidth;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final it = items[i];
          return _CatPill(
            width: itemWidth,
            icon: it.icon,
            label: it.label,
            colors: it.colors,
            onTap: () => onTap?.call(it.slug),
          );
        },
      ),
    );
  }
}

class _CatPill extends StatelessWidget {
  const _CatPill({
    required this.width,
    required this.icon,
    required this.label,
    required this.colors,
    this.onTap,
  });

  final double width;
  final IconData icon;
  final String label;
  final List<Color> colors;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          boxShadow: const [
            BoxShadow(
                color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .22),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: .35)),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
