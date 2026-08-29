import 'package:flutter/material.dart';

const Color ccmRed = Color(0xFF071A33);

const Color ccmBlue = Color(0xFF003DA5);

const Color ccmWhite = Color(0xFFFFFFFF);

const Color ccmLightGray = Color(0xFFF5F5F5);

const Color ccmSand = Color(0xFFF5EEE5);
const Color ccmSandDark = Color(0xFFD8C5AC);
const Color ccmInk = Color(0xFF412817);
const Color ccmMutedInk = Color(0xFF5D5047);

ThemeData buildCcmTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: ccmRed,
    brightness: Brightness.light,
  );

  return ThemeData(
    colorScheme: scheme.copyWith(
      primary: ccmRed,
      secondary: ccmBlue,
      surface: ccmSand,
    ),
    scaffoldBackgroundColor: ccmSand,
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      backgroundColor: ccmSandDark,
      foregroundColor: ccmInk,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: ccmWhite.withValues(alpha: .62),
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ccmWhite.withValues(alpha: .72),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: ccmRed.withValues(alpha: .25)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: ccmRed.withValues(alpha: .25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: ccmRed, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ccmRed,
        foregroundColor: ccmWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: ccmInk,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
