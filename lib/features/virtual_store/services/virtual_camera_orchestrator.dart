// lib/services/virtual_camera_orchestrator.dart
import 'package:flutter/foundation.dart';

/// Minimal controller now; expand with sensors/gestures later.
class VirtualCameraOrchestrator {
  /// -1.0 (look left) … 0 … +1.0 (look right), for future parallax/pan
  final ValueNotifier<double> yaw = ValueNotifier<double>(0);

  /// -1.0 (down shelf) … 0 … +1.0 (up shelf)
  final ValueNotifier<double> pitch = ValueNotifier<double>(0);

  void dispose() {
    yaw.dispose();
    pitch.dispose();
  }
}
