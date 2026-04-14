import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:western_malabar/features/home/screens/home_screen.dart';
import 'package:western_malabar/features/catalog/screens/category_screen.dart';
import 'package:western_malabar/features/cart/screens/cart_screen.dart';
import 'package:western_malabar/features/rewards/screens/rewards_screen.dart';
import 'package:western_malabar/features/profile/screens/profile_screen.dart';

import 'package:western_malabar/shared/utils/haptic.dart';
import 'package:western_malabar/shared/utils/cart_fly_target.dart';
import 'package:western_malabar/shared/widgets/ask_malabar_overlay.dart';
import 'package:western_malabar/features/cart/providers/cart_provider.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  final PageStorageBucket _bucket = PageStorageBucket();
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();

  late final List<Widget> _screens = <Widget>[
    HomeScreen(key: _homeKey), // 0
    const CategoryScreen(), // 1
    const CartScreen(), // 2
    const RewardsScreen(), // 3
    const ProfileScreen(), // 4
  ];

  int _index = 0;

  void _onTap(int i) {
    if (i == 0) {
      if (_index != 0) {
        Haptic.light(context);
        setState(() => _index = 0);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _homeKey.currentState?.scrollToTop();
        });
        return;
      }

      _homeKey.currentState?.scrollToTop();
      return;
    }

    if (i == _index) {
      final primary = PrimaryScrollController.maybeOf(context);
      if (primary != null && primary.hasClients) {
        primary.animateTo(
          0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
      return;
    }

    Haptic.light(context);
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final cartCount = cartItems.fold<int>(0, (sum, item) => sum + item.qty);

    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _index != 0) {
          setState(() => _index = 0);
        }
      },
      child: Scaffold(
        body: PageStorage(
          bucket: _bucket,
          child: IndexedStack(
            index: _index,
            children: _screens,
          ),
        ),
        bottomNavigationBar: _WMCustomBottomNav(
          currentIndex: _index,
          cartCount: cartCount,
          onTap: _onTap,
        ),
      ),
    );
  }

  @override
  void dispose() {
    AskMalabarOverlay.hide();
    super.dispose();
  }
}

class _WMCustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final int cartCount;
  final ValueChanged<int> onTap;

  const _WMCustomBottomNav({
    required this.currentIndex,
    required this.cartCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      padding: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            color: Color(0x14000000),
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            children: [
              _NavItem(
                label: 'Home',
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                label: 'Categories',
                icon: Icons.grid_view_outlined,
                activeIcon: Icons.grid_view_rounded,
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              const SizedBox(width: 86),
              _NavItem(
                label: 'Rewards',
                icon: Icons.workspace_premium_outlined,
                activeIcon: Icons.workspace_premium_rounded,
                isActive: currentIndex == 3,
                onTap: () => onTap(3),
              ),
              _NavItem(
                label: 'Profile',
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                isActive: currentIndex == 4,
                onTap: () => onTap(4),
              ),
            ],
          ),
          Positioned(
            top: -4,
            child: _AnimatedCartButton(
              key: const ValueKey('animated-cart-button'),
              count: cartCount,
              isActive: currentIndex == 2,
              onTap: () => onTap(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF5A2D82) : const Color(0xFF7A7A7A);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 72,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                color: color,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedCartButton extends StatefulWidget {
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  const _AnimatedCartButton({
    super.key,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_AnimatedCartButton> createState() => _AnimatedCartButtonState();
}

class _AnimatedCartButtonState extends State<_AnimatedCartButton>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _bounceController;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _bounceAnimation;

  int _previousCount = 0;

  @override
  void initState() {
    super.initState();
    _previousCount = widget.count;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _pulseAnimation = Tween<double>(
      begin: 0.88,
      end: 1.10,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeOut,
      ),
    );

    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.14)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.14, end: 0.96)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.96, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
    ]).animate(_bounceController);

    if (widget.count > 0) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedCartButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    final countIncreased = widget.count > oldWidget.count;
    final countChanged = widget.count != oldWidget.count;

    if (widget.count > 0) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _pulseController.value = 0;
    }

    if (countChanged && countIncreased) {
      _bounceController.forward(from: 0);
    }

    _previousCount = widget.count;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor =
        widget.isActive ? const Color(0xFF4E2675) : const Color(0xFF5A2D82);

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseController, _bounceController]),
        builder: (context, child) {
          final glowScale = widget.count > 0 ? _pulseAnimation.value : 0.0;
          final bounceScale =
              _bounceController.isAnimating ? _bounceAnimation.value : 1.0;

          return Transform.scale(
            scale: bounceScale,
            child: SizedBox(
              width: 84,
              height: 84,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  if (widget.count > 0)
                    Transform.scale(
                      scale: glowScale,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              const Color(0xFF5A2D82).withValues(alpha: 0.10),
                        ),
                      ),
                    ),
                  if (widget.count > 0)
                    Transform.scale(
                      scale: glowScale * 0.92,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              const Color(0xFF8753C4).withValues(alpha: 0.10),
                        ),
                      ),
                    ),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: buttonColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF5A2D82).withValues(alpha: 0.20),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.isActive
                          ? Icons.shopping_bag_rounded
                          : Icons.shopping_bag_outlined,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  if (widget.count > 0)
                    Positioned(
                      top: 6,
                      right: 4,
                      child: _AnimatedCartBadge(count: widget.count),
                    ),
                  Positioned(
                    bottom: -22,
                    child: Text(
                      'Cart',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: widget.isActive
                            ? const Color(0xFF5A2D82)
                            : const Color(0xFF7A7A7A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AnimatedCartBadge extends StatelessWidget {
  final int count;

  const _AnimatedCartBadge({
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          ),
          child: child,
        );
      },
      child: Container(
        key: ValueKey<int>(count),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: const Color(0xFF5A2D82),
            width: 1.4,
          ),
        ),
        constraints: const BoxConstraints(
          minWidth: 22,
          minHeight: 22,
        ),
        child: Center(
          child: Text(
            count > 99 ? '99+' : '$count',
            style: const TextStyle(
              color: Color(0xFF5A2D82),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

class _AskMalabarSheet extends StatelessWidget {
  const _AskMalabarSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ask Malabar (AI Chat)',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5A2D82),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ask about products, orders, deals or recipes.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              decoration: InputDecoration(
                hintText: 'e.g., Find Kerala snacks under £5',
                prefixIcon: const Icon(Icons.chat_bubble_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Haptic.heavy(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5A2D82),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.close),
              label: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
