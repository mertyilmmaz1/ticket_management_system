import 'package:flutter/material.dart';
import '../constants.dart';

/// Simple, functional theme for tablet adisyon app.
/// Neutral background, dark text, single accent; large typography for tablet.
class AppTheme {
  AppTheme._();

  static Color get _accent => const Color(0xFF2E7D32); // green
  static Color get _surface => Colors.white;
  static Color get _background => const Color(0xFFF5F5F5);
  static Color get _onSurface => const Color(0xFF212121);
  static Color get _onSurfaceVariant => const Color(0xFF757575);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.light(
          primary: _accent,
          surface: _surface,
          onSurface: _onSurface,
          onSurfaceVariant: _onSurfaceVariant,
          outline: const Color(0xFFE0E0E0),
        ),
        scaffoldBackgroundColor: _background,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Color(0xFF212121),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          margin: const EdgeInsets.all(8),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(AppConstants.minTouchTarget, AppConstants.minTouchTarget),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(fontSize: 17),
          bodyMedium: TextStyle(fontSize: 16),
          labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          hintStyle: const TextStyle(fontSize: 16),
        ),
      );
}
