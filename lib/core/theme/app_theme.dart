import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const deepGreen = Color(0xFF193F38);
  static const darkGreen = Color(0xFF102D28);
  static const gold = Color(0xFFD9A441);
  static const softGold = Color(0xFFE5B65A);
  static const ivory = Color(0xFFFBF7EF);

  static ThemeData light() => _theme(
        brightness: Brightness.light,
        surface: ivory,
        onSurface: const Color(0xFF17332E),
        surfaceContainer: const Color(0xFFF2EBDD),
      );

  static ThemeData dark() => _theme(
        brightness: Brightness.dark,
        surface: const Color(0xFF0D211D),
        onSurface: const Color(0xFFF7F1E7),
        surfaceContainer: const Color(0xFF17352E),
      );

  static ThemeData _theme({
    required Brightness brightness,
    required Color surface,
    required Color onSurface,
    required Color surfaceContainer,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: deepGreen,
      primary:
          brightness == Brightness.light ? deepGreen : const Color(0xFF9EDAC6),
      secondary: gold,
      surface: surface,
      onSurface: onSurface,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Cairo',
      colorScheme: scheme,
      scaffoldBackgroundColor: surface,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      cardTheme: CardTheme(
        color: brightness == Brightness.light ? Colors.white : surfaceContainer,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainer,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: gold, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: deepGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 78,
        backgroundColor: brightness == Brightness.light
            ? const Color(0xFFFFFCF6)
            : darkGreen,
        indicatorColor: brightness == Brightness.light
            ? const Color(0x33D9A441)
            : const Color(0x3349A98B),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? gold
                : onSurface.withOpacity(.72),
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontWeight: FontWeight.w800,
            color: states.contains(WidgetState.selected)
                ? brightness == Brightness.dark
                    ? softGold
                    : deepGreen
                : onSurface.withOpacity(.76),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceContainer,
        selectedColor: deepGreen,
        secondarySelectedColor: deepGreen,
        labelStyle: TextStyle(color: onSurface, fontWeight: FontWeight.w600),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
