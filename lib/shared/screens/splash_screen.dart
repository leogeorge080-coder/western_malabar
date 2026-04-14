import 'package:flutter/material.dart';
import 'package:western_malabar/shared/widgets/mh_monogram_animation.dart';

/// Premium splash screen with animated MH monogram.
///
/// Displays on app launch with the full premium animation sequence.
/// Call [Navigator.of(context).pushReplacementNamed('home')] in [onCompleted]
/// to transition to the main app after animation finishes.
class SplashScreen extends StatelessWidget {
  const SplashScreen({
    super.key,
    this.onCompleted,
  });

  /// Optional callback invoked when monogram animation completes.
  /// Typically used to navigate to the home screen.
  final VoidCallback? onCompleted;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: MhMonogramAnimation(
        size: 180,
        backgroundColor: const Color(0xFFFAFAFA),
        onCompleted: onCompleted,
      ),
    );
  }
}
