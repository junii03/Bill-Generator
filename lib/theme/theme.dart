import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData dark(String fontFamily) => ThemeData(
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: const Color(0xff4b4bc3), // indigo
      onPrimary: Colors.white,
      secondary: const Color(0xff707ff5), // cornflower blue
      onSecondary: Colors.black,
      tertiary: const Color(0xffa195f9), // portage
      onTertiary: Colors.black,
      error: Colors.red,
      onError: Colors.white,
      surface: const Color(0xff1e1e76), // lucky point
      inverseSurface: Colors.white,
      onSurface: Colors.white,
      onInverseSurface: const Color(0xff707ff5), // cornflower blue
      onSurfaceVariant: Colors.black,
      inversePrimary: const Color(0xfff2a1f2), // lavender magenta
    ),
    useMaterial3: true,
    fontFamily: fontFamily,
    appBarTheme: const AppBarTheme(centerTitle: false),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );

  static ThemeData light(String fontFamily) => ThemeData(
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff4b4bc3), // indigo
      onPrimary: Colors.white,
      secondary: Color(0xff707ff5), // cornflower blue
      onSecondary: Colors.white,
      tertiary: Color(0xffa195f9), // portage
      onTertiary: Colors.white,
      error: Colors.red,
      onError: Colors.white,
      surface: Colors.white,
      inverseSurface: Color(0xff1e1e76), // lucky point
      onSurface: Colors.black,
      onInverseSurface: Colors.white,
      onSurfaceVariant: Colors.grey,
      inversePrimary: Color(0xfff2a1f2), // lavender magenta
    ),
    useMaterial3: true,
    fontFamily: fontFamily,
    appBarTheme: const AppBarTheme(centerTitle: false),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );
}
