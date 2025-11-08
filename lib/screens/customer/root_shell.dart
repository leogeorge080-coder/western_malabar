// lib/screens/customer/root_shell.dart
import 'package:flutter/material.dart';

// Haptics + Ask Malabar overlay (keep these paths as in your project)
import 'package:western_malabar/widgets/ask_malabar_overlay.dart';
import 'package:western_malabar/utils/haptic.dart';

// Screens
import 'package:western_malabar/screens/customer/home_screen.dart';
import 'package:western_malabar/screens/customer/category_screen.dart';
import 'package:western_malabar/screens/customer/favourites_screen.dart';
import 'package:western_malabar/screens/customer/profile_screen.dart';
import 'package:western_malabar/screens/customer/cart_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  // Prevent multiple overlay insertions (e.g., hot reloads)
  bool _askOverlayShown = false;

  // Keep your pages const for perf
  final List<Widget> _pages = const [
    HomeScreen(),
    CategoryScreen(),
    FavouritesScreen(),
    ProfileScreen(),
    CartScreen(),
  ];

  @override
  void initState() {
    super.initState();

    // Show Ask Malabar overlay once the first frame is drawn.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_askOverlayShown) {
        _askOverlayShown = true;

        AskMalabarOverlay.show(context, () {
          // haptic bump then open the chat sheet
          Haptic.medium(context);
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (_) => const _AskMalabarSheet(),
          );
        });
      }
    });
  }

  @override
  void dispose() {
    // Clean up overlay on shell destroy
    if (AskMalabarOverlay.isShown) {
      AskMalabarOverlay.hide();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // keep pages alive & fast to switch
      body: IndexedStack(index: _index, children: _pages),

      // nice visual when FABs/overlays near nav bar
      extendBody: true,

      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (i) {
          Haptic.light(context); // subtle click
          setState(() => _index = i);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.grid_view_rounded), label: 'Categories'),
          NavigationDestination(
              icon: Icon(Icons.favorite_border), label: 'Favourites'),
          NavigationDestination(
              icon: Icon(Icons.person_outline), label: 'Profile'),
          NavigationDestination(
              icon: Icon(Icons.shopping_cart_outlined), label: 'Cart'),
        ],
      ),
    );
  }
}

/// Ask Malabar bottom sheet (placeholder UI; hook your chat here)
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
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF5A2D82),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Ask about products, orders, deals or recipes.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5A2D82),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Haptic.heavy(context); // strong confirmation
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Close'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
