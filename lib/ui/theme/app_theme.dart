import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Centralised theme for Flight Studio.
///
/// A dense, dark, JetBrains IDEA-inspired palette with the brand orange
/// `#ff7f27` as the single accent. Rounded corners are generous throughout
/// per the project's UI direction.
///
/// Note: theme-data constructors intentionally avoid the `const` keyword where
/// they reference the local `colors` token, because Dart's constant evaluation
/// does not allow property access on a local variable inside a constant
/// expression (even when the variable itself is `const`).
class AppTheme {
  AppTheme._();

  static const Color _seed = Color(0xFFFF7F27);

  static ThemeData dark() {
    const colors = AppColors.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    ).copyWith(
      surface: colors.surfaceBase,
      primary: colors.accent,
      onPrimary: Colors.black,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.surfaceBase,
      canvasColor: colors.surfaceBase,
      splashFactory: NoSplash.splashFactory,
      visualDensity: VisualDensity.standard,
      extensions: <ThemeExtension<dynamic>>[colors],
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surfaceRaised,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 12,
      ),
      dividerTheme: DividerThemeData(
        color: colors.border,
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(
        color: colors.textSecondary,
        size: 18,
      ),
      // Rounded, low-elevation surfaces (cards, panels, drawers).
      cardTheme: CardThemeData(
        color: colors.surfaceRaised,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusLg),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colors.surfaceLowered,
          borderRadius: BorderRadius.circular(_radiusSm),
          border: Border.all(color: colors.border),
        ),
        textStyle: TextStyle(
          color: colors.textPrimary,
          fontSize: 12,
        ),
        waitDuration: const Duration(milliseconds: 400),
      ),
      inputDecorationTheme: _inputDecoration(colors),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.accent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusMd),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.textPrimary,
          side: BorderSide(color: colors.borderStrong),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusMd),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colors.textSecondary,
          highlightColor: colors.accent.withValues(alpha: 0.12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusSm),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? colors.accent
              : colors.textDisabled;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? colors.accent.withValues(alpha: 0.4)
              : colors.surfaceLowered;
        }),
        trackOutlineColor: WidgetStatePropertyAll(colors.border),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colors.surfaceRaised,
        indicatorColor: colors.accent.withValues(alpha: 0.18),
        selectedIconTheme: IconThemeData(
          color: colors.accent,
          size: 20,
        ),
        unselectedIconTheme: IconThemeData(
          color: colors.textSecondary,
          size: 20,
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(
          colors.borderStrong.withValues(alpha: 0.6),
        ),
        radius: const Radius.circular(_radiusSm),
        thickness: const WidgetStatePropertyAll(8),
        mainAxisMargin: 4,
      ),
      textTheme: _textTheme(colors),
    );
  }

  static InputDecorationTheme _inputDecoration(AppColors colors) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(_radiusMd),
      borderSide: BorderSide(color: colors.border),
    );
    return InputDecorationTheme(
      filled: true,
      fillColor: colors.surfaceLowered,
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      hintStyle: TextStyle(color: colors.textDisabled, fontSize: 13),
      labelStyle: TextStyle(color: colors.textSecondary, fontSize: 13),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radiusMd),
        borderSide: BorderSide(color: colors.accent, width: 1.5),
      ),
    );
  }

  static TextTheme _textTheme(AppColors colors) {
    const base = TextStyle(fontSize: 13, height: 1.4);
    return TextTheme(
      displayLarge: base.copyWith(
          fontSize: 28, fontWeight: FontWeight.w600, color: colors.textPrimary),
      displayMedium: base.copyWith(
          fontSize: 22, fontWeight: FontWeight.w600, color: colors.textPrimary),
      headlineSmall: base.copyWith(
          fontSize: 17, fontWeight: FontWeight.w600, color: colors.textPrimary),
      titleLarge: base.copyWith(
          fontSize: 15, fontWeight: FontWeight.w600, color: colors.textPrimary),
      titleMedium: base.copyWith(
          fontSize: 14, fontWeight: FontWeight.w500, color: colors.textPrimary),
      titleSmall: base.copyWith(
          fontSize: 13, fontWeight: FontWeight.w500, color: colors.textPrimary),
      bodyLarge: base.copyWith(color: colors.textPrimary),
      bodyMedium: base.copyWith(color: colors.textPrimary, fontSize: 13),
      bodySmall: base.copyWith(color: colors.textSecondary, fontSize: 12),
      labelLarge:
          base.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w600),
      labelSmall:
          base.copyWith(color: colors.textSecondary, fontSize: 11),
    );
  }

  // Radii used across the app — intentionally generous for a softer look.
  static const double _radiusSm = 6;
  static const double _radiusMd = 10;
  static const double _radiusLg = 12;
}
