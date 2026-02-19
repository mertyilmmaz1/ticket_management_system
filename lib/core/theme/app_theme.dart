import 'package:flutter/material.dart';
import '../constants.dart';

/// Simple, functional theme for tablet adisyon app.
/// Neutral background, dark text, single accent; large typography for tablet.
class AppTheme {
  AppTheme._();

  // Forest + amber palette for readable long-shift tablet usage.
  static Color get _accent => const Color(0xFF1F6F5F);
  static Color get _surface => Colors.white;
  static Color get _background => const Color(0xFFF4F6F4);
  static Color get _onSurface => const Color(0xFF1D2B32);
  static Color get _onSurfaceVariant => const Color(0xFF5A6872);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        visualDensity: VisualDensity.standard,
        colorScheme: ColorScheme.light(
          primary: _accent,
          onPrimary: Colors.white,
          secondary: const Color(0xFFC58A28),
          onSecondary: Colors.white,
          tertiary: const Color(0xFF2E6DB3),
          onTertiary: Colors.white,
          primaryContainer: const Color(0xFFD7ECE6),
          onPrimaryContainer: const Color(0xFF0E4E42),
          secondaryContainer: const Color(0xFFF6E3BE),
          onSecondaryContainer: const Color(0xFF6C4A0B),
          surface: _surface,
          surfaceContainerHighest: const Color(0xFFE9EFEB),
          onSurface: _onSurface,
          onSurfaceVariant: _onSurfaceVariant,
          outline: const Color(0xFFCBD5D2),
          error: const Color(0xFFB83A3A),
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: _background,
        appBarTheme: AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: _surface,
          foregroundColor: _onSurface,
          titleTextStyle: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: _onSurface,
          ),
        ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: const Color(0xFFCBD5D2)),
          ),
          margin: const EdgeInsets.all(6),
          color: _surface,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: Colors.white,
            minimumSize: const Size(AppConstants.minTouchTarget, AppConstants.minTouchTarget),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: Colors.white,
            minimumSize: const Size(AppConstants.minTouchTarget, AppConstants.minTouchTarget),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _onSurface,
            minimumSize: const Size(AppConstants.minTouchTarget, AppConstants.minTouchTarget),
            side: const BorderSide(color: Color(0xFFCBD5D2)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            minimumSize: const Size(AppConstants.minTouchTarget, AppConstants.minTouchTarget),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: const BorderSide(color: Color(0xFFCBD5D2)),
          selectedColor: const Color(0xFFD7ECE6),
          backgroundColor: Colors.white,
          labelStyle: TextStyle(color: _onSurface, fontSize: 15, fontWeight: FontWeight.w600),
          secondaryLabelStyle: const TextStyle(
            color: Color(0xFF0E4E42),
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
            minimumSize: WidgetStateProperty.all(
              const Size(AppConstants.minTouchTarget, AppConstants.minTouchTarget),
            ),
            textStyle: WidgetStateProperty.all(
              const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            foregroundColor: _onSurfaceVariant,
            minimumSize: const Size(AppConstants.minTouchTarget, AppConstants.minTouchTarget),
            padding: const EdgeInsets.all(12),
          ),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, height: 1.15),
          titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.2),
          titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.3),
          bodyLarge: TextStyle(fontSize: 16, height: 1.35),
          bodyMedium: TextStyle(fontSize: 15, height: 1.35),
          labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFCBD5D2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFCBD5D2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _accent, width: 1.5),
          ),
          hintStyle: const TextStyle(fontSize: 16),
        ),
      );
}
