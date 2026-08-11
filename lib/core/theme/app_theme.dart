import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const _sand = Color(0xFFFFE8B5);
  static const _deepSand = Color(0xFF8C4A12);
  static const _oasis = Color(0xFF245C4A);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _oasis,
      brightness: Brightness.light,
      primary: _oasis,
      secondary: _deepSand,
      surface: const Color(0xFFFFFBF5),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFFFFBF5),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _sand.withOpacity(.35),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 76,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
              color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
