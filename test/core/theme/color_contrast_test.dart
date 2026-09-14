import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sdk_base/core/theme/app_colors.dart';
import 'package:flutter_sdk_base/core/theme/app_semantic_colors.dart';

/// WCAG 2.1 relative luminance.
double _luminance(Color c) {
  double channel(double v) => v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}

/// WCAG AA for normal-size text.
const double _aaText = 4.5;

void main() {
  group('theme contrast', () {
    final themes = {
      'light': (
        AppSemanticColors.light,
        [AppColors.surfaceLight, AppColors.backgroundLight],
      ),
      'dark': (
        AppSemanticColors.dark,
        [AppColors.surfaceDark, AppColors.backgroundDark],
      ),
    };

    for (final entry in themes.entries) {
      final (colors, surfaces) = entry.value;

      test('${entry.key}: foreground status colors clear AA on every surface', () {
        final foregrounds = {
          'statusSuccess': colors.statusSuccess,
          'statusWarning': colors.statusWarning,
          'statusError': colors.statusError,
        };

        for (final fg in foregrounds.entries) {
          for (final surface in surfaces) {
            final ratio = _contrast(fg.value, surface);
            expect(
              ratio,
              greaterThanOrEqualTo(_aaText),
              reason:
                  '${entry.key} ${fg.key} on '
                  '#${surface.toARGB32().toRadixString(16).substring(2)} '
                  'is ${ratio.toStringAsFixed(2)}:1',
            );
          }
        }
      });

      test('${entry.key}: body, secondary, and hint text clear AA on every surface', () {
        final isDark = entry.key == 'dark';
        final textColors = {
          'textPrimary': isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          'textSecondary': colors.textSecondary,
          'textHint': colors.textHint,
        };

        for (final fg in textColors.entries) {
          for (final surface in surfaces) {
            final ratio = _contrast(fg.value, surface);
            expect(
              ratio,
              greaterThanOrEqualTo(_aaText),
              reason: '${entry.key} ${fg.key} is ${ratio.toStringAsFixed(2)}:1',
            );
          }
        }
      });
    }

    test('filled control labels clear AA against their primary fill', () {
      final ratio = _contrast(Colors.white, AppColors.primary);
      expect(ratio, greaterThanOrEqualTo(_aaText));
    });

    test('the raw fill palette is documented as unsafe for light foreground', () {
      expect(_contrast(AppColors.warning, AppColors.surfaceLight), lessThan(_aaText));
    });
  });
}
