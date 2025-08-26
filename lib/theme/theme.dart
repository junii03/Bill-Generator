import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData dark(String fontFamily) {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xff6366f1), // Modern indigo
      brightness: Brightness.dark,
    );

    return ThemeData(
      colorScheme: baseScheme.copyWith(
        secondary: const Color(0xff8b5cf6), // Purple accent
        tertiary: const Color(0xff06b6d4), // Cyan accent
        surface: const Color(0xff0f172a), // Deep slate
        surfaceContainerHighest: const Color(0xff1e293b),
        onSurface: const Color(0xffe2e8f0),
      ),
      useMaterial3: true,
      fontFamily: fontFamily,
      textTheme: _textTheme(fontFamily, Brightness.dark),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: baseScheme.surface,
        foregroundColor: baseScheme.onSurface,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: baseScheme.onSurface,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: baseScheme.primary,
          foregroundColor: baseScheme.onPrimary,
          elevation: 2,
          shadowColor: baseScheme.primary.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: baseScheme.primary,
          foregroundColor: baseScheme.onPrimary,
          elevation: 1,
          shadowColor: baseScheme.primary.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: baseScheme.primary,
          side: BorderSide(color: baseScheme.outline, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: baseScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: baseScheme.secondary,
        foregroundColor: baseScheme.onSecondary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      cardTheme: CardThemeData(
        color: baseScheme.surfaceContainerHighest,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: baseScheme.surfaceContainerHighest.withOpacity(0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: baseScheme.outline.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: baseScheme.primary, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: baseScheme.error, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: baseScheme.error, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        labelStyle: TextStyle(
          color: baseScheme.onSurfaceVariant,
          fontFamily: fontFamily,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          color: baseScheme.onSurfaceVariant.withOpacity(0.7),
          fontFamily: fontFamily,
        ),
        prefixIconColor: baseScheme.onSurfaceVariant,
        suffixIconColor: baseScheme.onSurfaceVariant,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: baseScheme.primary,
        linearTrackColor: baseScheme.surfaceContainerHighest,
        circularTrackColor: baseScheme.surfaceContainerHighest,
      ),
    );
  }

  static ThemeData light(String fontFamily) {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xff6366f1), // Modern indigo
      brightness: Brightness.light,
    );

    return ThemeData(
      colorScheme: baseScheme.copyWith(
        secondary: const Color(0xff8b5cf6), // Purple accent
        tertiary: const Color(0xff06b6d4), // Cyan accent
        surface: const Color(0xfffafaff), // Pure white with hint of blue
        surfaceContainerHighest: const Color(0xfff8fafc),
        onSurface: const Color(0xff0f172a),
      ),
      useMaterial3: true,
      fontFamily: fontFamily,
      textTheme: _textTheme(fontFamily, Brightness.light),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: baseScheme.surface,
        foregroundColor: baseScheme.onSurface,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: baseScheme.onSurface,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: baseScheme.primary,
          foregroundColor: baseScheme.onPrimary,
          elevation: 2,
          shadowColor: baseScheme.primary.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: baseScheme.primary,
          foregroundColor: baseScheme.onPrimary,
          elevation: 1,
          shadowColor: baseScheme.primary.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: baseScheme.primary,
          side: BorderSide(color: baseScheme.outline, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: baseScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: baseScheme.secondary,
        foregroundColor: baseScheme.onSecondary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      cardTheme: CardThemeData(
        color: baseScheme.surface,
        elevation: 3,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: baseScheme.surfaceContainerHighest.withOpacity(0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: baseScheme.outline.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: baseScheme.primary, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: baseScheme.error, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: baseScheme.error, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        labelStyle: TextStyle(
          color: baseScheme.onSurfaceVariant,
          fontFamily: fontFamily,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          color: baseScheme.onSurfaceVariant.withOpacity(0.7),
          fontFamily: fontFamily,
        ),
        prefixIconColor: baseScheme.onSurfaceVariant,
        suffixIconColor: baseScheme.onSurfaceVariant,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: baseScheme.primary,
        linearTrackColor: baseScheme.surfaceContainerHighest,
        circularTrackColor: baseScheme.surfaceContainerHighest,
      ),
    );
  }

  static TextTheme _textTheme(String fontFamily, Brightness brightness) {
    final base = brightness == Brightness.dark
        ? Typography.whiteMountainView
        : Typography.blackMountainView;

    return base.copyWith(
      displayLarge: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
      ),
      displaySmall: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      headlineLarge: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
      ),
      headlineMedium: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      headlineSmall: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      titleLarge: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      titleMedium: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
      ),
      titleSmall: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
      ),
      bodySmall: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
      ),
      labelLarge: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
    );
  }
}
