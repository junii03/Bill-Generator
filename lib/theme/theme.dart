import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData dark(String fontFamily) {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xff4b4bc3), // Indigo seed
      brightness: Brightness.dark,
    );

    return ThemeData(
      colorScheme: baseScheme.copyWith(
        secondary: const Color(0xff707ff5),
        tertiary: const Color(0xffa195f9),
        inversePrimary: const Color(0xfff2a1f2),
      ),
      useMaterial3: true,
      fontFamily: fontFamily,
      textTheme: _textTheme(fontFamily, Brightness.dark),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: baseScheme.surface,
        foregroundColor: baseScheme.onSurface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: baseScheme.primary,
          foregroundColor: baseScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: baseScheme.secondary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: baseScheme.secondary,
        foregroundColor: baseScheme.onSecondary,
      ),
      cardTheme: CardThemeData(
        color: baseScheme.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: baseScheme.surfaceContainerHighest.withOpacity(0.2),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: baseScheme.primary, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        labelStyle: TextStyle(color: baseScheme.onSurfaceVariant),
        hintStyle: TextStyle(
          color: baseScheme.onSurfaceVariant.withOpacity(0.7),
        ),
      ),
    );
  }

  static ThemeData light(String fontFamily) {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xff4b4bc3), // Indigo seed
      brightness: Brightness.light,
    );

    return ThemeData(
      colorScheme: baseScheme.copyWith(
        secondary: const Color(0xff707ff5),
        tertiary: const Color(0xffa195f9),
        inversePrimary: const Color(0xfff2a1f2),
      ),
      useMaterial3: true,
      fontFamily: fontFamily,
      textTheme: _textTheme(fontFamily, Brightness.light),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: baseScheme.surface,
        foregroundColor: baseScheme.onSurface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: baseScheme.primary,
          foregroundColor: baseScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: baseScheme.secondary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: baseScheme.secondary,
        foregroundColor: baseScheme.onSecondary,
      ),
      cardTheme: CardThemeData(
        color: baseScheme.surface,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: baseScheme.surfaceContainerHighest.withOpacity(0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: baseScheme.primary, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        labelStyle: TextStyle(color: baseScheme.onSurfaceVariant),
        hintStyle: TextStyle(
          color: baseScheme.onSurfaceVariant.withOpacity(0.7),
        ),
      ),
    );
  }

  static TextTheme _textTheme(String fontFamily, Brightness brightness) {
    final base = brightness == Brightness.dark
        ? Typography.whiteMountainView
        : Typography.blackMountainView;

    return base.copyWith(
      headlineLarge: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: TextStyle(fontFamily: fontFamily),
      bodyMedium: TextStyle(fontFamily: fontFamily),
      labelLarge: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
