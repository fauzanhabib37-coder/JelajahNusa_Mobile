import 'package:flutter/material.dart';

abstract final class Nusa {
  static const green = Color(0xFF426B50),
      bg = Color(0xFFF8F9F5),
      ink = Color(0xFF23372C),
      muted = Color(0xFF6A786E),
      soft = Color(0xFFE8EEE5),
      red = Color(0xFFA33D35);
  static TextStyle heading([double size = 28, Color color = ink]) => TextStyle(
    fontFamily: 'NusaSerif',
    fontSize: size,
    height: 1.3,
    color: color,
    fontWeight: FontWeight.w400,
  );
}

ThemeData nusaTheme() => ThemeData(
  useMaterial3: true,
  fontFamily: 'NusaSans',
  scaffoldBackgroundColor: Nusa.bg,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Nusa.green,
    primary: Nusa.green,
    surface: Nusa.bg,
    error: Nusa.red,
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(fontSize: 14, height: 1.7, color: Nusa.ink),
    bodySmall: TextStyle(fontSize: 12, height: 1.6, color: Nusa.muted),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Nusa.bg,
    foregroundColor: Nusa.ink,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: Nusa.green,
      foregroundColor: Colors.white,
      minimumSize: const Size(48, 54),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      shape: const StadiumBorder(),
      textStyle: const TextStyle(
        fontFamily: 'NusaSans',
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      minimumSize: const Size(48, 48),
      foregroundColor: Nusa.green,
      textStyle: const TextStyle(fontFamily: 'NusaSans', fontSize: 12),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    hintStyle: const TextStyle(fontSize: 13, color: Nusa.muted),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: const BorderSide(color: Color(0xFFE8ECE5)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: const BorderSide(color: Nusa.green),
    ),
    errorMaxLines: 3,
  ),
  dividerTheme: const DividerThemeData(color: Nusa.soft),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: Nusa.ink,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
);
