import 'package:flutter/material.dart';
import 'package:flutter_sdk_base/core/theme/app_colors.dart';

/// Brightness-aware semantic color tokens for cases that need raw [Color]
/// (icons, borders, surfaces, status foregrounds).
/// Widgets read these via `context.colors`.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  final Color surface;
  final Color textSecondary;
  final Color textHint;
  final Color border;
  final Color brandAccent;
  final Color track;
  final Color statusSuccess;
  final Color statusWarning;
  final Color statusError;

  const AppSemanticColors({
    required this.surface,
    required this.textSecondary,
    required this.textHint,
    required this.border,
    required this.brandAccent,
    required this.track,
    required this.statusSuccess,
    required this.statusWarning,
    required this.statusError,
  });

  static const light = AppSemanticColors(
    surface: AppColors.surfaceLight,
    textSecondary: AppColors.textSecondaryLight,
    textHint: AppColors.textHintLight,
    border: AppColors.borderLight,
    brandAccent: AppColors.primaryDark,
    track: AppColors.inactive,
    statusSuccess: AppColors.successOnLight,
    statusWarning: AppColors.warningOnLight,
    statusError: AppColors.errorOnLight,
  );

  static const dark = AppSemanticColors(
    surface: AppColors.surfaceDark,
    textSecondary: AppColors.textSecondaryDark,
    textHint: AppColors.textHintDark,
    border: AppColors.borderDark,
    brandAccent: AppColors.primaryLight,
    track: AppColors.borderDark,
    statusSuccess: AppColors.successOnDark,
    statusWarning: AppColors.warning,
    statusError: AppColors.error,
  );

  @override
  AppSemanticColors copyWith({
    Color? surface,
    Color? textSecondary,
    Color? textHint,
    Color? border,
    Color? brandAccent,
    Color? track,
    Color? statusSuccess,
    Color? statusWarning,
    Color? statusError,
  }) {
    return AppSemanticColors(
      surface: surface ?? this.surface,
      textSecondary: textSecondary ?? this.textSecondary,
      textHint: textHint ?? this.textHint,
      border: border ?? this.border,
      brandAccent: brandAccent ?? this.brandAccent,
      track: track ?? this.track,
      statusSuccess: statusSuccess ?? this.statusSuccess,
      statusWarning: statusWarning ?? this.statusWarning,
      statusError: statusError ?? this.statusError,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      surface: Color.lerp(surface, other.surface, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      border: Color.lerp(border, other.border, t)!,
      brandAccent: Color.lerp(brandAccent, other.brandAccent, t)!,
      track: Color.lerp(track, other.track, t)!,
      statusSuccess: Color.lerp(statusSuccess, other.statusSuccess, t)!,
      statusWarning: Color.lerp(statusWarning, other.statusWarning, t)!,
      statusError: Color.lerp(statusError, other.statusError, t)!,
    );
  }
}

extension AppSemanticColorsContext on BuildContext {
  AppSemanticColors get colors => Theme.of(this).extension<AppSemanticColors>()!;
}
