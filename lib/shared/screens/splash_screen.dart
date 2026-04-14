import 'package:flutter/material.dart';
import 'package:western_malabar/shared/widgets/premium_icon_reveal.dart';

/// Premium splash screen with animated app icon reveal.
///
/// Displays on app launch with the full premium animation sequence.
/// Call [Navigator.of(context).pushReplacementNamed('home')] in [onCompleted]
/// to transition to the main app after animation finishes.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigated = false;

  Future<void> _goNext() async {
    if (_navigated || !mounted) return;
    _navigated = true;

    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: PremiumIconReveal(
        imagePath: 'assets/icon/app_icon.png',
        size: 180,
        useTile: false,
        onCompleted: _goNext,
      ),
    );
  }
}
