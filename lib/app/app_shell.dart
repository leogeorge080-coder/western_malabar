import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:western_malabar/features/home/screens/home_screen.dart';
import 'package:western_malabar/features/catalog/screens/category_screen.dart';
import 'package:western_malabar/features/profile/screens/profile_screen.dart';
import 'package:western_malabar/features/cart/screens/cart_screen.dart';

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
    HomeScreen(key: _homeKey),
    const CategoryScreen(),
    const ProfileScreen(),
    const CartScreen(),
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
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _index,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF5A2D82),
          unselectedItemColor: const Color(0xFF7A7A7A),
          showUnselectedLabels: true,
          onTap: _onTap,
          items: <BottomNavigationBarItem>[
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined),
              activeIcon: Icon(Icons.grid_view_rounded),
              label: 'Categories',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: _CartIcon(
                key: wmBottomCartNavKey,
                count: cartCount,
              ),
              activeIcon: _CartIcon(
                count: cartCount,
                active: true,
              ),
              label: 'Cart',
            ),
          ],
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

class _CartIcon extends StatelessWidget {
  const _CartIcon({
    super.key,
    required this.count,
    this.active = false,
  });

  final int count;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final Color color =
        active ? const Color(0xFF5A2D82) : const Color(0xFF7A7A7A);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(Icons.shopping_bag_outlined, color: color),
        if (count > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF5A2D82),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ),
              ),
            ),
          ),
      ],
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


