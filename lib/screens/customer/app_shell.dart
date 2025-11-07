import 'package:flutter/material.dart';
import 'package:western_malabar/screens/customer/home_screen.dart';
import 'package:western_malabar/screens/customer/category_screen.dart';
import 'package:western_malabar/screens/customer/favourites_screen.dart';
import 'package:western_malabar/screens/customer/profile_screen.dart';
import 'package:western_malabar/screens/customer/cart_screen.dart';
import 'package:western_malabar/widgets/ask_malabar_overlay.dart';
import 'package:western_malabar/utils/haptic.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  bool _isChatOpen = false; // prevents multiple sheets

  final _screens = const [
    HomeScreen(),
    CategoryScreen(),
    FavouritesScreen(),
    ProfileScreen(),
    CartScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Show floating bubble after first layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!mounted) return;
        AskMalabarOverlay.show(context, _onBubbleTap);
      });
    });
  }

  Future<void> _onBubbleTap() async {
    if (_isChatOpen) return; // ✅ block re-entry
    _isChatOpen = true;

    Haptic.medium(context);

    // Hide bubble so it can’t be tapped while the sheet is open
    AskMalabarOverlay.hide();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AskMalabarSheet(),
    );

    // Sheet closed
    _isChatOpen = false;
    if (!mounted) return;
    AskMalabarOverlay.show(context, _onBubbleTap);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        height: 64,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0x115A2D82),
        selectedIndex: _index,
        onDestinationSelected: (i) {
          Haptic.light(context);
          setState(() => _index = i);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.grid_view_rounded), label: 'Categories'),
          NavigationDestination(
              icon: Icon(Icons.favorite_outline), label: 'Favourites'),
          NavigationDestination(
              icon: Icon(Icons.person_outline), label: 'Profile'),
          NavigationDestination(
              icon: Icon(Icons.shopping_cart_outlined), label: 'Cart'),
        ],
      ),
    );
  }

  @override
  void dispose() {
    AskMalabarOverlay.hide();
    super.dispose();
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
