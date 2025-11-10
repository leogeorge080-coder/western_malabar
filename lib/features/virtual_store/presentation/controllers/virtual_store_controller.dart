import 'package:flutter/material.dart';

class VirtualStoreController extends ChangeNotifier {
  double cameraX = 0, cameraY = 0, cameraZ = 1.0;

  void pan(double dx, double dy) {
    cameraX += dx; cameraY += dy;
    notifyListeners();
  }

  void zoom(double z) {
    cameraZ = (cameraZ + z).clamp(0.5, 2.0);
    notifyListeners();
  }
}
