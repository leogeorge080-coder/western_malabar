import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Haptics helper that works on most devices/emulators.
/// Note: Some Androids require "Vibrate on tap" to be enabled in system settings.
class Haptic {
  static void _tap(BuildContext ctx) {
    // Also triggers Material ripple feedback for consistency.
    Feedback.forTap(ctx);
  }

  static void light(BuildContext ctx) {
    _tap(ctx);
    HapticFeedback.lightImpact();
  }

  static void medium(BuildContext ctx) {
    _tap(ctx);
    HapticFeedback.mediumImpact();
  }

  static void heavy(BuildContext ctx) {
    _tap(ctx);
    HapticFeedback.heavyImpact();
  }

  static void select() {
    HapticFeedback.selectionClick();
  }
}
