import 'package:flutter/material.dart';

class WMTheme {
  // ===== Brand Colors =====
  static const royalPurple = Color(0xFF5A2D82);
  static const gold = Color(0xFFF0C53E);
  static const lightGoldBg = Color(0xFFFFF3C7);

  // Back-compat alias used in some screens
  static const lightGold = Colors.white;

  // ===== Theme Builder =====
  static ThemeData build() {
    return ThemeData(
      useMaterial3: true,

      // global scaffold + background color
      scaffoldBackgroundColor: Colors.white,

      colorScheme: ColorScheme.fromSeed(
        seedColor: royalPurple,
        primary: royalPurple,
        secondary: gold,
        surface: Colors.white,
        background: Colors.white,
      ),

      // AppBar look
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: royalPurple,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: royalPurple,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),

      // NavigationBar styling
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: Color(0x115A2D82),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 64,
      ),

      // Card theme (Material 3 uses CardThemeData here)
      cardTheme: CardThemeData(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadowColor: Colors.black12,
        elevation: 4,
        // surfaceTintColor keeps cards bright in M3
        surfaceTintColor: Colors.white,
      ),

      // Button styles (brand purple)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: royalPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
