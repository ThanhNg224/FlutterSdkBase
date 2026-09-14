import 'package:flutter/material.dart';
import 'package:flutter_sdk_base/core/theme/app_colors.dart';
import 'package:flutter_sdk_base/core/theme/app_semantic_colors.dart';
import 'package:flutter_sdk_base/core/theme/app_spacing.dart';
import 'package:flutter_sdk_base/core/theme/app_typography.dart';

/// Comprehensive ThemeData configurations for Light and Dark modes.
abstract class AppTheme {
  static ThemeData get lightTheme {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: AppColors.onLightFill,
          secondary: AppColors.secondary,
          onSecondary: Colors.white,
          surface: AppColors.surfaceLight,
          error: AppColors.errorOnLight,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: AppTypography.fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      textTheme: _textTheme(primary: AppColors.textPrimaryLight, secondary: AppColors.textSecondaryLight),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundLight,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusL),
          side: const BorderSide(color: AppColors.borderLight),
        ),
      ),
      elevatedButtonTheme: _elevatedButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme(foreground: AppColors.primaryDark, border: AppColors.primary),
      inputDecorationTheme: _inputDecorationTheme(
        border: AppColors.controlBorderLight,
        hint: AppColors.textHintLight,
        error: AppColors.errorOnLight,
        focus: AppColors.primaryDark,
      ),
      segmentedButtonTheme: _segmentedButtonTheme(
        selectedBackground: AppColors.primary,
        selectedForeground: AppColors.onLightFill,
        unselectedForeground: AppColors.textPrimaryLight,
        border: AppColors.primary,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.borderLight, space: AppSpacing.m, thickness: 1),
      extensions: const [AppSemanticColors.light],
    );
  }

  static ThemeData get darkTheme {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AppColors.primaryLight,
          onPrimary: Colors.black,
          secondary: AppColors.secondary,
          onSecondary: Colors.white,
          surface: AppColors.surfaceDark,
          error: AppColors.error,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: AppTypography.fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      textTheme: _textTheme(primary: AppColors.textPrimaryDark, secondary: AppColors.textSecondaryDark),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusL),
          side: const BorderSide(color: AppColors.borderDark),
        ),
      ),
      elevatedButtonTheme: _elevatedButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme(foreground: AppColors.primaryLight, border: AppColors.primaryLight),
      inputDecorationTheme: _inputDecorationTheme(
        border: AppColors.controlBorderDark,
        hint: AppColors.textHintDark,
        error: AppColors.error,
        focus: AppColors.primary,
      ),
      segmentedButtonTheme: _segmentedButtonTheme(
        selectedBackground: AppColors.primaryLight,
        selectedForeground: Colors.black,
        unselectedForeground: AppColors.textPrimaryDark,
        border: AppColors.primaryLight,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.borderDark, space: AppSpacing.m, thickness: 1),
      extensions: const [AppSemanticColors.dark],
    );
  }

  /// Maps [AppTypography]'s named styles onto M3 [TextTheme] slots.
  static TextTheme _textTheme({required Color primary, required Color secondary}) {
    return TextTheme(
      displayLarge: AppTypography.displayLarge.copyWith(color: primary),
      headlineMedium: AppTypography.headlineMedium.copyWith(color: primary),
      titleLarge: AppTypography.titleLarge.copyWith(color: primary),
      titleMedium: AppTypography.titleMedium.copyWith(color: primary),
      bodyLarge: AppTypography.bodyLarge.copyWith(color: primary),
      bodyMedium: AppTypography.bodyMedium.copyWith(color: secondary),
      labelMedium: AppTypography.labelMedium.copyWith(color: secondary),
      bodySmall: AppTypography.caption.copyWith(color: secondary),
    );
  }

  static final ElevatedButtonThemeData _elevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusM)),
      textStyle: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
    ),
  );

  static OutlinedButtonThemeData _outlinedButtonTheme({required Color foreground, required Color border}) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: foreground,
        side: BorderSide(color: border),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusM)),
        textStyle: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  static InputDecorationTheme _inputDecorationTheme({
    required Color border,
    required Color hint,
    required Color error,
    required Color focus,
  }) {
    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusM),
      borderSide: BorderSide(color: border),
    );
    return InputDecorationTheme(
      border: baseBorder,
      enabledBorder: baseBorder,
      focusedBorder: baseBorder.copyWith(borderSide: BorderSide(color: focus, width: 2)),
      errorBorder: baseBorder.copyWith(borderSide: BorderSide(color: error)),
      focusedErrorBorder: baseBorder.copyWith(borderSide: BorderSide(color: error, width: 2)),
      hintStyle: AppTypography.bodyMedium.copyWith(color: hint),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
    );
  }

  static SegmentedButtonThemeData _segmentedButtonTheme({
    required Color selectedBackground,
    required Color selectedForeground,
    required Color unselectedForeground,
    required Color border,
  }) {
    Color foreground(Set<WidgetState> states) =>
        states.contains(WidgetState.selected) ? selectedForeground : unselectedForeground;
    Color background(Set<WidgetState> states) =>
        states.contains(WidgetState.selected) ? selectedBackground : Colors.transparent;

    return SegmentedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith(foreground),
        backgroundColor: WidgetStateProperty.resolveWith(background),
        side: WidgetStatePropertyAll(BorderSide(color: border)),
      ),
    );
  }
}
