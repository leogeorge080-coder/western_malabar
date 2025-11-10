// lib/services/virtual_camera_orchestrator.dart
import 'package:flutter/foundation.dart';

/// Minimal camera/orbit state (expand later).
class VirtualCameraOrchestrator {
  /// -1..+1: yaw (left/right)
  final ValueNotifier<double> yaw = ValueNotifier<double>(0);

  /// -1..+1: pitch (down/up)
  final ValueNotifier<double> pitch = ValueNotifier<double>(0);

  void dispose() {
    yaw.dispose();
    pitch.dispose();
  }
}
