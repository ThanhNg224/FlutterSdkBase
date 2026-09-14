import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sdk_base/core/constants/app_constants.dart';
import 'package:flutter_sdk_base/features/home/presentation/home_screen.dart';

import '../../support/widget_harness.dart';

void main() {
  testWidgets('HomeScreen renders app name and settings action', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: harness(
          child: const HomeScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(AppConstants.appName), findsWidgets);
    expect(find.byIcon(Icons.settings_outlined), findsWidgets);
  });
}
