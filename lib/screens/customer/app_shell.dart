// lib/screens/customer/app_shell.dart
import 'package:flutter/material.dart';

// Screens
import 'package:western_malabar/screens/customer/home_screen.dart';
import 'package:western_malabar/screens/customer/category_screen.dart';
import 'package:western_malabar/screens/customer/profile_screen.dart';
import 'package:western_malabar/screens/customer/cart_screen.dart';

// Virtual Store feature
import 'package:western_malabar/features/virtual_store/virtual_store.dart';

// Utilities & overlay
import 'package:western_malabar/utils/haptic.dart';
import 'package:western_malabar/widgets/ask_malabar_overlay.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final PageStorageBucket _bucket = PageStorageBucket();

  // Order must match BottomNavigationBar items
  late final List<Widget> _screens = <Widget>[
    const HomeScreen(),
    const CategoryScreen(),
    const VirtualStoreScreen(), // 🟣 Virtual Store tab
    const ProfileScreen(),
    const CartScreen(),
  ];

  int _index = 0;
  bool _isChatOpen = false; // guard: prevent multiple sheets

  // If you later wire cart count from state/provider, bind here.
  int get _cartCount => 0;

  // ─────────────────────────────────────────────────────────────
  // Ask Malabar bubble
  // ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    // Show the floating bubble after first layout (slight delay for polish)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      AskMalabarOverlay.show(context, _onAskMalabarBubbleTap);
    });
  }

  Future<void> _onAskMalabarBubbleTap() async {
    if (_isChatOpen) return;
    _isChatOpen = true;

    Haptic.medium(context);
    AskMalabarOverlay.hide();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _AskMalabarSheet(),
    );

    _isChatOpen = false;
    if (!mounted) return;
    AskMalabarOverlay.show(context, _onAskMalabarBubbleTap);
  }

  // ─────────────────────────────────────────────────────────────
  // Navigation
  // ─────────────────────────────────────────────────────────────
  void _onTap(int i) {
    if (i == _index) {
      // Scroll-to-top when re-tapping the active tab
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
    // Back from non-home tabs goes to Home first.
    return WillPopScope(
      onWillPop: () async {
        if (_index != 0) {
          setState(() => _index = 0);
          return false;
        }
        return true;
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
              icon: Icon(Icons.storefront_outlined),
              activeIcon: Icon(Icons.storefront_rounded),
              label: 'Virtual Store',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: _CartIcon(count: _cartCount),
              activeIcon: _CartIcon(count: _cartCount, active: true),
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

/// Small, dependency-free badge for the cart tab.
class _CartIcon extends StatelessWidget {
  const _CartIcon({required this.count, this.active = false});
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

/// Bottom sheet content for Ask Malabar.
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
