import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sdk_base/core/theme/app_spacing.dart';
import 'package:flutter_sdk_base/core/widgets/app_button.dart';
import 'package:flutter_sdk_base/core/widgets/app_card.dart';
import 'package:flutter_sdk_base/core/widgets/app_section_header.dart';
import 'package:flutter_sdk_base/core/widgets/app_text_field.dart';

import '../support/widget_harness.dart';

/// Renders the design system in one frame per theme, so a change to a color
/// token, radius, or text style shows up as a visual diff instead of silently shipping.
void main() {
  for (final brightness in Brightness.values) {
    testWidgets('component gallery renders properly in ${brightness.name} mode', (tester) async {
      tester.view
        ..physicalSize = const Size(1000, 1600)
        ..devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(harness(brightness: brightness, child: const _ComponentGallery()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(_ComponentGallery), findsOneWidget);
      expect(find.text('Buttons'), findsOneWidget);
      expect(find.text('Input Fields'), findsOneWidget);
    });
  }
}

class _ComponentGallery extends StatelessWidget {
  const _ComponentGallery();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppSectionHeader(title: 'Buttons', subtitle: 'Variants, states, and sizes'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppButton(label: 'Primary Button', onPressed: () {}),
                const SizedBox(height: AppSpacing.s),
                AppButton(label: 'Secondary Button', variant: ButtonVariant.secondary, onPressed: () {}),
                const SizedBox(height: AppSpacing.s),
                AppButton(label: 'Outline Button', variant: ButtonVariant.outline, onPressed: () {}),
                const SizedBox(height: AppSpacing.s),
                AppButton(label: 'Danger Button', variant: ButtonVariant.danger, onPressed: () {}),
                const SizedBox(height: AppSpacing.s),
                const AppButton(label: 'Disabled Button'),
                const SizedBox(height: AppSpacing.s),
                const AppButton(label: 'Loading Button', isLoading: true),
                const SizedBox(height: AppSpacing.s),
                const AppButton(label: 'Loading Outline', variant: ButtonVariant.outline, isLoading: true),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          const AppSectionHeader(title: 'Input Fields', subtitle: 'Default, hints, and errors'),
          const AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(label: 'Text Field', hint: 'Enter text here', prefixIcon: Icons.edit_note_rounded),
                SizedBox(height: AppSpacing.m),
                AppTextField(
                  label: 'Field with Error',
                  initialValue: 'Wrong input',
                  errorText: 'This field has a validation error',
                  prefixIcon: Icons.error_outline_rounded,
                ),
                SizedBox(height: AppSpacing.m),
                AppTextField(
                  label: 'Field with Helper',
                  helperText: 'Informational helper text below input',
                  prefixIcon: Icons.info_outline_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
