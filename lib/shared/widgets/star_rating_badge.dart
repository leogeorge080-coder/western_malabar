import 'package:flutter/material.dart';

class StarRatingBadge extends StatelessWidget {
  const StarRatingBadge({
    super.key,
    required this.avgRating,
    required this.ratingCount,
    this.size = 14,
  });

  final double? avgRating;
  final int? ratingCount;
  final double size;

  @override
  Widget build(BuildContext context) {
    final rating = avgRating ?? 0;
    final count = ratingCount ?? 0;

    if (count <= 0) return const SizedBox.shrink();

    final rounded = rating.round().clamp(0, 5);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (i) {
          return Icon(
            i < rounded ? Icons.star_rounded : Icons.star_border_rounded,
            size: size,
            color: const Color(0xFFF4B400),
          );
        }),
        const SizedBox(width: 6),
        Text(
          '${rating.toStringAsFixed(1)} ($count)',
          style: TextStyle(
            fontSize: size - 2,
            fontWeight: FontWeight.w700,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}




