import 'package:flutter/material.dart';

/// Système visuel « Dunes et Oasis » : sable clair, oasis profond et or du Souf.
class AppTheme {
  static const primaryColor = Color(0xFF214A3B);
  static const secondaryColor = Color(0xFFD58B2D);
  static const tertiaryColor = Color(0xFFB85E32);
  static const duneInk = Color(0xFF30241B);
  static const duneNight = Color(0xFF231B17);
  static const sand = Color(0xFFFFF7EA);
  static const sandSoft = Color(0xFFF4E8D5);
  static const duneLine = Color(0xFFE5D2B4);

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Cairo',
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.light,
        seedColor: primaryColor,
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: secondaryColor,
        onSecondary: duneInk,
        tertiary: tertiaryColor,
        onTertiary: Colors.white,
        surface: sand,
        onSurface: duneInk,
        surfaceContainerHighest: sandSoft,
        outline: duneLine,
      ),
      scaffoldBackgroundColor: sand,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: const Color(0xFFFFFCF7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: duneLine),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Color(0xFFFFFCF7),
        indicatorColor: Color(0x33214A3B),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: secondaryColor,
        foregroundColor: duneInk,
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Cairo',
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: primaryColor,
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: secondaryColor,
        onSecondary: duneInk,
        tertiary: tertiaryColor,
        onTertiary: Colors.white,
        surface: const Color(0xFF2D251F),
        onSurface: const Color(0xFFF8EEDC),
        surfaceContainerHighest: const Color(0xFF3A3027),
        outline: const Color(0xFF5A4B3D),
      ),
      scaffoldBackgroundColor: duneNight,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF2D251F),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: const Color(0xFF2D251F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF5A4B3D)),
        ),
      ),
    );
  }
}
