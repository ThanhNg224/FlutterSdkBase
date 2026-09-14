import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sdk_base/core/theme/app_colors.dart';
import 'package:flutter_sdk_base/core/theme/app_semantic_colors.dart';
import 'package:flutter_sdk_base/core/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppTheme text theme', () {
    test('light theme maps emphasis vs secondary text colors correctly', () {
      final textTheme = AppTheme.lightTheme.textTheme;
      expect(textTheme.titleLarge?.color, AppColors.textPrimaryLight);
      expect(textTheme.bodyMedium?.color, AppColors.textSecondaryLight);
      expect(textTheme.bodySmall?.color, AppColors.textSecondaryLight);
    });

    test('dark theme maps emphasis vs secondary text colors correctly', () {
      final textTheme = AppTheme.darkTheme.textTheme;
      expect(textTheme.titleLarge?.color, AppColors.textPrimaryDark);
      expect(textTheme.bodyMedium?.color, AppColors.textSecondaryDark);
      expect(textTheme.bodySmall?.color, AppColors.textSecondaryDark);
    });
  });

  group('AppTheme segmented button', () {
    test('selected segment in light theme resolves to brand primary and onLightFill', () {
      final style = AppTheme.lightTheme.segmentedButtonTheme.style!;
      final selectedBackground = style.backgroundColor!.resolve({WidgetState.selected});
      final selectedForeground = style.foregroundColor!.resolve({WidgetState.selected});
      final unselectedBackground = style.backgroundColor!.resolve({});

      expect(selectedBackground, AppColors.primary);
      expect(selectedForeground, AppColors.onLightFill);
      expect(unselectedBackground, isNot(AppColors.primary));
    });

    test('selected segment in dark theme resolves to primaryLight and black for contrast', () {
      final style = AppTheme.darkTheme.segmentedButtonTheme.style!;
      final selectedBackground = style.backgroundColor!.resolve({WidgetState.selected});
      final selectedForeground = style.foregroundColor!.resolve({WidgetState.selected});

      expect(selectedBackground, AppColors.primaryLight);
      expect(selectedForeground, Colors.black);
    });
  });

  group('AppTheme outlined button', () {
    test('light/dark outline variants use theme-owned brand colors', () {
      final lightStyle = AppTheme.lightTheme.outlinedButtonTheme.style!;
      final darkStyle = AppTheme.darkTheme.outlinedButtonTheme.style!;

      expect(lightStyle.foregroundColor!.resolve({}), AppColors.primaryDark);
      expect(darkStyle.foregroundColor!.resolve({}), AppColors.primaryLight);
    });
  });

  group('AppSemanticColors', () {
    test('light and dark themes register distinct semantic color extensions', () {
      final light = AppTheme.lightTheme.extension<AppSemanticColors>();
      final dark = AppTheme.darkTheme.extension<AppSemanticColors>();

      expect(light, isNotNull);
      expect(dark, isNotNull);
      expect(light!.textSecondary, AppColors.textSecondaryLight);
      expect(dark!.textSecondary, AppColors.textSecondaryDark);
    });

    test('brand accent flips shade per brightness so it stays legible', () {
      final light = AppTheme.lightTheme.extension<AppSemanticColors>()!;
      final dark = AppTheme.darkTheme.extension<AppSemanticColors>()!;

      expect(light.brandAccent, AppColors.primaryDark);
      expect(dark.brandAccent, AppColors.primaryLight);
      expect(dark.brandAccent, isNot(light.brandAccent));
    });

    test('track differs per brightness', () {
      final light = AppTheme.lightTheme.extension<AppSemanticColors>()!;
      final dark = AppTheme.darkTheme.extension<AppSemanticColors>()!;

      expect(dark.track, isNot(light.track));
    });

    test('lerp interpolates every token', () {
      final light = AppSemanticColors.light;
      final mid = light.lerp(AppSemanticColors.dark, 0.5);

      expect(mid.brandAccent, isNot(light.brandAccent));
      expect(mid.track, isNot(light.track));
      expect(mid.surface, isNot(light.surface));
      expect(mid.border, isNot(light.border));
    });
  });
}
