import 'package:flutter/material.dart';
import 'package:western_malabar/shared/widgets/premium_icon_reveal.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      body: Center(
        child: PremiumIconReveal(
          imagePath: 'assets/icon/app_icon.png',
          size: 180,
          useTile: false,
        ),
      ),
    );
  }
}
