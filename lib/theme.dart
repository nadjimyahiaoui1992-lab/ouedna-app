import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF193F38);
  static const Color secondaryColor = Color(0xFFD9A441);
  static const Color primaryDark = Color(0xFF102D28);
  static const Color secondaryLight = Color(0xFFE5B65A);
  static const Color backgroundColor = Color(0xFFFBF7EF);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: Colors.white,
      background: backgroundColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      centerTitle: true,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: secondaryColor,
      unselectedItemColor: Colors.grey,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
    ),
    fontFamily: 'Cairo', // Requires font setup
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryDark,
    scaffoldBackgroundColor: const Color(0xFF121212),
    colorScheme: ColorScheme.dark(
      primary: primaryDark,
      secondary: secondaryColor,
      surface: const Color(0xFF1E1E1E),
      background: const Color(0xFF121212),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryDark,
      foregroundColor: Colors.white,
      centerTitle: true,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: secondaryColor,
      unselectedItemColor: Colors.grey,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: const Color(0xFF1E1E1E),
    ),
    fontFamily: 'Cairo', // Requires font setup
  );
}
