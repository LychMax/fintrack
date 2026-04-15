import 'package:flutter/material.dart';

class AppTheme {
  static const background = Color(0xFF0F172A);
  static const foreground = Color(0xFFE2E8F0);
  static const card = Color(0xFF1E293B);
  static const cardForeground = Color(0xFFE2E8F0);
  static const primary = Color(0xFFEC4899);
  static const primaryForeground = Color(0xFFFFFFFF);
  static const secondary = Color(0xFFA855F7);
  static const accent = Color(0xFF6366F1);
  static const border = Color(0xFF334155);
  static const muted = Color(0xFF64748B);
  static const mutedForeground = Color(0xFF94A3B8);
  static const destructive = Color(0xFFEF4444);
  static const income = Color(0xFF22C55E);
  static const expense = Color(0xFFEF4444);
  static const amber = Color(0xFFF59E0B);
  static const glass = Color.fromRGBO(30, 41, 59, 0.6);

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme.dark(
      primary: primary,
      onPrimary: primaryForeground,
      secondary: secondary,
      onSecondary: primaryForeground,
      surface: card,
      onSurface: foreground,
      background: background,
      onBackground: foreground,
      error: destructive,
      onError: Colors.white,
      outline: border,
      surfaceVariant: muted,
      onSurfaceVariant: mutedForeground,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      foregroundColor: foreground,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardTheme(
      color: card,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: primaryForeground,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(color: foreground, fontWeight: FontWeight.bold, fontSize: 28),
      titleLarge: TextStyle(color: foreground, fontSize: 22),
      titleMedium: TextStyle(color: foreground, fontSize: 16, fontWeight: FontWeight.w600),
      bodyMedium: TextStyle(color: foreground, fontSize: 16),
      bodySmall: TextStyle(color: mutedForeground, fontSize: 14),
      labelLarge: TextStyle(color: foreground),
    ),
    dividerColor: border,
    iconTheme: const IconThemeData(color: foreground),
  );
}