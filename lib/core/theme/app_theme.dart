import 'package:flutter/material.dart';

/// Central place for app-wide theming.
class AppTheme {
  static const Color seedColor = Colors.teal;

  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: seedColor,
      brightness: Brightness.light,
    );

    return base.copyWith(
      scaffoldBackgroundColor: base.colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: base.colorScheme.surface,
        foregroundColor: base.colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      // NOTE: CardThemeData instead of CardTheme
      cardTheme: CardThemeData(
        color: base.colorScheme.surfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: base.colorScheme.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: base.colorScheme.primary, width: 1.4),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        iconColor: base.colorScheme.onSurfaceVariant,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: base.colorScheme.primaryContainer,
        foregroundColor: base.colorScheme.onPrimaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  /// Dark theme – not pure black, uses `surface` and `surfaceVariant`.
  static ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: seedColor,
      brightness: Brightness.dark,
    );

    return base.copyWith(
      scaffoldBackgroundColor: base.colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: base.colorScheme.surface,
        foregroundColor: base.colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      // NOTE: CardThemeData here as well
      cardTheme: CardThemeData(
        color: base.colorScheme.surfaceVariant.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: base.colorScheme.surfaceVariant.withOpacity(0.8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: base.colorScheme.primary, width: 1.4),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        iconColor: base.colorScheme.onSurfaceVariant,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: base.colorScheme.primaryContainer,
        foregroundColor: base.colorScheme.onPrimaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
