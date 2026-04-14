import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class WmProductImage extends StatelessWidget {
  final String? imageUrl;
  final double width;
  final double height;
  final double borderRadius;
  final BoxFit fit;
  final IconData placeholderIcon;

  const WmProductImage({
    super.key,
    required this.imageUrl,
    required this.width,
    required this.height,
    this.borderRadius = 16,
    this.fit = BoxFit.cover,
    this.placeholderIcon = Icons.inventory_2_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    final cacheWidth = width.isFinite && width > 0 ? (width * 3).round() : null;
    final cacheHeight =
        height.isFinite && height > 0 ? (height * 3).round() : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: url == null || url.isEmpty
            ? _FallbackBox(
                icon: placeholderIcon,
              )
            : CachedNetworkImage(
                imageUrl: url,
                fit: fit,
                fadeInDuration: const Duration(milliseconds: 180),
                fadeOutDuration: const Duration(milliseconds: 100),
                memCacheWidth: cacheWidth,
                memCacheHeight: cacheHeight,
                placeholder: (_, __) => const _ImageLoadingBox(),
                errorWidget: (_, __, ___) => const _FallbackBox(
                  icon: Icons.broken_image_rounded,
                ),
              ),
      ),
    );
  }
}

class _ImageLoadingBox extends StatelessWidget {
  const _ImageLoadingBox();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFF3F4F6),
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _FallbackBox extends StatelessWidget {
  final IconData icon;

  const _FallbackBox({
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF6F0FB),
      child: Center(
        child: Icon(
          icon,
          color: const Color(0xFF5A2D82),
        ),
      ),
    );
  }
}
