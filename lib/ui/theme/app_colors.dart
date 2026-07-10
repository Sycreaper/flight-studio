import 'package:flutter/material.dart';

/// Design tokens specific to Flight Studio, layered on top of [ThemeData].
///
/// Exposed via [ThemeExtension] so widgets can read it with
/// `Theme.of(context).extension<AppColors>()!`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.accent,
    required this.accentMuted,
    required this.surfaceBase,
    required this.surfaceRaised,
    required this.surfaceLowered,
    required this.chrome,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.success,
    required this.warning,
    required this.danger,
  });

  /// Brand orange `#ff7f27`.
  final Color accent;

  /// Dimmed accent for backgrounds/hover states.
  final Color accentMuted;

  /// Main content / editor background (medium dark).
  final Color surfaceBase;

  /// Drawers, panels, toolbar, tab strip (dark chrome).
  final Color surfaceRaised;

  /// Recessed areas (map canvas, scroll wells).
  final Color surfaceLowered;

  /// Status bar and tool-window dock stripes (lighter chrome).
  final Color chrome;

  final Color border;
  final Color borderStrong;

  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;

  final Color success;
  final Color warning;
  final Color danger;

  static const AppColors dark = AppColors(
    accent: Color(0xFFFF7F27),
    accentMuted: Color(0xFFB8591B),
    surfaceBase: Color(0xFF1E1F22),
    surfaceRaised: Color(0xFF191A1C),
    surfaceLowered: Color(0xFF141414),
    chrome: Color(0xFF26282C),
    border: Color(0xFF3C3F41),
    borderStrong: Color(0xFF4E5255),
    textPrimary: Color(0xFFBBBBBB),
    textSecondary: Color(0xFF808080),
    textDisabled: Color(0xFF5C5C5C),
    success: Color(0xFF59A869),
    warning: Color(0xFFCC8B37),
    danger: Color(0xFFF9844A),
  );

  @override
  AppColors copyWith({
    Color? accent,
    Color? accentMuted,
    Color? surfaceBase,
    Color? surfaceRaised,
    Color? surfaceLowered,
    Color? chrome,
    Color? border,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textDisabled,
    Color? success,
    Color? warning,
    Color? danger,
  }) {
    return AppColors(
      accent: accent ?? this.accent,
      accentMuted: accentMuted ?? this.accentMuted,
      surfaceBase: surfaceBase ?? this.surfaceBase,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceLowered: surfaceLowered ?? this.surfaceLowered,
      chrome: chrome ?? this.chrome,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textDisabled: textDisabled ?? this.textDisabled,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      accent: Color.lerp(accent, other.accent, t)!,
      accentMuted: Color.lerp(accentMuted, other.accentMuted, t)!,
      surfaceBase: Color.lerp(surfaceBase, other.surfaceBase, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      surfaceLowered: Color.lerp(surfaceLowered, other.surfaceLowered, t)!,
      chrome: Color.lerp(chrome, other.chrome, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}
