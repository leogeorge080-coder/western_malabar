import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────
/// Skeleton Loader for Products (instead of spinner)
///
/// Why skeleton > spinner?
/// - Keeps layout stable (no collapse)
/// - Shows expected content shape
/// - Professional (see Amazon, Google, LinkedIn)
/// - Better perceived performance
/// ─────────────────────────────────────────────────────────────

class ProductSkeleton extends StatelessWidget {
  final double height;
  final double width;
  final BorderRadius? borderRadius;

  const ProductSkeleton({
    super.key,
    this.height = 150,
    this.width = double.infinity,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
      ),
      child: _ShimmerEffect(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            borderRadius: borderRadius ?? BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image skeleton
        ProductSkeleton(
          height: 180,
          width: double.infinity,
          borderRadius: BorderRadius.circular(12),
        ),
        const SizedBox(height: 12),

        // Title skeleton (2 lines)
        ProductSkeleton(
          height: 16,
          width: double.infinity,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 8),
        ProductSkeleton(
          height: 16,
          width: 200,
          borderRadius: BorderRadius.circular(4),
        ),

        const SizedBox(height: 12),

        // Price skeleton
        ProductSkeleton(
          height: 14,
          width: 80,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}

/// Full grid of skeleton cards
class ProductGridSkeleton extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;
  final double childAspectRatio;

  const ProductGridSkeleton({
    super.key,
    this.itemCount = 8,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.65,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: itemCount,
      itemBuilder: (_, __) => const ProductCardSkeleton(),
    );
  }
}

/// List-style skeleton (for search results)
class ProductListSkeleton extends StatelessWidget {
  final int itemCount;
  final bool shrinkWrap;

  const ProductListSkeleton({
    super.key,
    this.itemCount = 6,
    this.shrinkWrap = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: shrinkWrap,
      padding: const EdgeInsets.all(12),
      itemCount: itemCount,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _ProductListSkeletonItem(),
      ),
    );
  }
}

class _ProductListSkeletonItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Image
        ProductSkeleton(
          height: 100,
          width: 100,
          borderRadius: BorderRadius.circular(8),
        ),
        const SizedBox(width: 12),

        // Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              ProductSkeleton(
                height: 16,
                width: double.infinity,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),

              // Description
              ProductSkeleton(
                height: 12,
                width: 200,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),

              // Price
              ProductSkeleton(
                height: 14,
                width: 60,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Shimmer effect for skeleton animation
class _ShimmerEffect extends StatefulWidget {
  final Widget child;

  const _ShimmerEffect({required this.child});

  @override
  State<_ShimmerEffect> createState() => __ShimmerEffectState();
}

class __ShimmerEffectState extends State<_ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-2, 0),
              end: Alignment(1, 0),
              stops: const [0.0, 0.5, 1.0],
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
              transform: GradientRotation(
                2 * 3.14159 * _controller.value,
              ),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}
