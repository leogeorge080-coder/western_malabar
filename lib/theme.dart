import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WMTheme {
  // ===== Brand Colors =====
  static const royalPurple = Color(0xFF5A2D82);
  static const gold = Color(0xFFF0C53E);
  static const lightGoldBg = Color(0xFFFFF3C7); // warm cream background

  // Back-compat alias used in some screens (point to warm cream by default)
  static const lightGold = lightGoldBg;

  // ===== Theme Builder =====
  static ThemeData build() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: royalPurple,
      primary: royalPurple,
      secondary: gold,
      surface: Colors.white,
      background: Colors.white,
      // brightness: Brightness.light, // uncomment if you ever flip schemes
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,

      // Global scaffold background
      scaffoldBackgroundColor: Colors.white,

      // AppBar look (works well with our blurred, semi-transparent header)
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: royalPurple,
        elevation: 0,
        surfaceTintColor: Colors.transparent, // avoid M3 auto-tint
        titleTextStyle: TextStyle(
          color: royalPurple,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),

      // NavigationBar styling
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: Color(0x115A2D82),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 64,
      ),

      // Cards
      cardTheme: CardThemeData(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadowColor: Colors.black12,
        elevation: 4,
        surfaceTintColor: Colors.white, // keep bright in M3
      ),

      // Buttons (brand purple)
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

      // TextFields default to rounded, subtle fill (matches your search field)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: Colors.black54),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: royalPurple, width: 1.4),
        ),
      ),
    );
  }
}
