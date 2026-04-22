import 'dart:math' show max;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; // <-- add this line
// for wmPurple, wmGreen, wmGold if you use them

/// Collapsible "location area" delegate
class LocationHeader extends SliverPersistentHeaderDelegate {
  LocationHeader({
    required this.maxH,
    required this.minH,
    required this.builder,
  });

  final double maxH;
  final double minH;
  final Widget Function(BuildContext context, double t) builder;

  @override
  double get minExtent => minH;
  @override
  double get maxExtent => max(maxH, minH);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final total = (maxExtent - minExtent);
    final t = total <= 0 ? 1.0 : (shrinkOffset / total).clamp(0.0, 1.0);
    return builder(context, t);
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}

/// Scroll-reactive header (blur + opacity + morphing search)
class SearchHeaderDelegate extends StatefulWidget {
  const SearchHeaderDelegate({super.key});

  @override
  State<SearchHeaderDelegate> createState() => _SearchHeaderDelegateState();
}

class _SearchHeaderDelegateState extends State<SearchHeaderDelegate> {
  late final ScrollController _controller;
  bool _compact = false;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController()
      ..addListener(() {
        final dir = _controller.position.userScrollDirection;
        if (dir == ScrollDirection.reverse && !_compact) {
          setState(() => _compact = true);
        } else if (dir == ScrollDirection.forward && _compact) {
          setState(() => _compact = false);
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return CustomScrollView(
      controller: _controller,
      slivers: [
        // Header
        SliverAppBar(
          pinned: true,
          floating: true,
          snap: true,
          expandedHeight: 168,
          backgroundColor:
              Colors.white.withValues(alpha: _compact ? 0.75 : 0.92),
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: _compact ? 10 : 6,
                sigmaY: _compact ? 10 : 6,
              ),
              child: Container(
                padding: EdgeInsets.only(top: topPad),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.88),
                      Colors.white.withValues(alpha: 0.82),
                    ],
                  ),
                  boxShadow: [
                    if (_compact)
                      const BoxShadow(
                        blurRadius: 12,
                        offset: Offset(0, 4),
                        color: Color(0x14000000),
                      ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Text(
                            'Western Malabar',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: Colors.black,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.shopping_cart_outlined),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Morphing search bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _compact
                            ? const _CompactSearch(key: ValueKey('compact'))
                            : const _ExpandedSearch(key: ValueKey('expanded')),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Location bar hides on scroll up
        SliverPersistentHeader(
          pinned: false,
          delegate: LocationHeader(
            maxH: 44,
            minH: 0,
            builder: (context, t) {
              final opacity = (1 - t).clamp(0.0, 1.0);
              final offsetY = 6 * t;
              return Transform.translate(
                offset: Offset(0, -offsetY),
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.place_outlined, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Delivering to: Glasgow, UK',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('Change'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Example scroll content
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) => ListTile(
              title: Text('Item $i'),
              subtitle: const Text('Product details'),
            ),
            childCount: 40,
          ),
        ),
      ],
    );
  }
}

class _ExpandedSearch extends StatelessWidget {
  const _ExpandedSearch({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey.withValues(alpha: 0.12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: const Row(
        children: [
          Icon(Icons.search, color: Colors.black87),
          SizedBox(width: 10),
          Text('Search Western Malabar',
              style: TextStyle(color: Colors.black87)),
        ],
      ),
    );
  }
}

class _CompactSearch extends StatelessWidget {
  const _CompactSearch({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.withValues(alpha: 0.12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: const Row(
        children: [
          Icon(Icons.search, size: 18, color: Colors.black87),
          SizedBox(width: 8),
          Text('Search', style: TextStyle(color: Colors.black87)),
        ],
      ),
    );
  }
}
