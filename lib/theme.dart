// lib/theme.dart
import 'package:flutter/material.dart';

/// Brand palette (compile-time consts)
class WMTheme {
  // Core brand
  static const Color purple = Color(0xFF5A2D82); // primary
  static const Color royalPurple = Color(0xFF432C7A); // darker variant
  static const Color gold = Color(0xFFFFC857); // accent / CTA
  static const Color lightGold = Color(0xFFFFF4DE); // soft surface bg
  static const Color softBg = Color(0xFFF9FAFB); // scaffold bg

  // Greys / text
  static const Color text = Color(0xFF121212);
  static const Color subText = Color(0xFF474747);
  static const Color divider = Color(0xFFE6E6EA);

  // Feedback
  static const Color success = Color(0xFF0B9B73);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
}

/// Public theme you import in main.dart
final ThemeData wmLightTheme = _buildLightTheme();

ThemeData _buildLightTheme() {
  // Use ColorScheme.light to avoid extra deprecated fields noise.
  const scheme = ColorScheme.light(
    primary: WMTheme.purple,
    onPrimary: Colors.white,
    secondary: WMTheme.gold,
    onSecondary: Colors.black,
    tertiary: WMTheme.royalPurple,
    error: WMTheme.danger,
    surface: Colors.white,
    onSurface: WMTheme.text,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.white,

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: WMTheme.purple),
      titleTextStyle: TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 20,
        color: WMTheme.purple,
      ),
    ),

    // Inputs (search etc.)
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: WMTheme.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: WMTheme.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: WMTheme.purple, width: 1.2),
      ),
      prefixIconColor: WMTheme.purple,
      suffixIconColor: WMTheme.purple,
      hintStyle: const TextStyle(
        color: WMTheme.subText,
        fontWeight: FontWeight.w600,
      ),
    ),

    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: WMTheme.gold,
        foregroundColor: Colors.black,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: WMTheme.purple,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),

    // Text
    textTheme: const TextTheme(
      titleLarge: TextStyle(
          fontWeight: FontWeight.w900, fontSize: 20, color: WMTheme.purple),
      titleMedium: TextStyle(
          fontWeight: FontWeight.w800, fontSize: 16, color: WMTheme.text),
      bodyMedium: TextStyle(
          fontWeight: FontWeight.w600, fontSize: 14, color: WMTheme.text),
      bodySmall: TextStyle(
          fontWeight: FontWeight.w600, fontSize: 12, color: WMTheme.subText),
    ),

    // Bottom nav
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: WMTheme.purple,
      unselectedItemColor: WMTheme.subText,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w800),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w700),
      showUnselectedLabels: true,
    ),

    // Divider
    dividerColor: WMTheme.divider,

    // NOTE: We intentionally omit `cardTheme` here to avoid version
    // mismatches between `CardTheme` vs `CardThemeData` on different
    // Flutter SDKs. Style individual Cards where needed.
  );
}
