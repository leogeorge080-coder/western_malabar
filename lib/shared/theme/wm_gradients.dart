import 'package:flutter/material.dart';

class WMGradients {
  /// Strong gradient (Home screen)
  static const LinearGradient homeBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF3E1D65),
      Color(0xFF5F2F8E),
      Color(0xFF7B51B3),
      Color(0xFFE9E0F7),
      Colors.white,
    ],
    stops: [0.0, 0.18, 0.38, 0.82, 1.0],
  );

  /// Softer gradient for other pages
  static const LinearGradient pageBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF5F2F8E),
      Color(0xFF8A63BF),
      Color(0xFFEFE7FA),
      Colors.white,
    ],
    stops: [0.0, 0.25, 0.55, 1.0],
  );
}




