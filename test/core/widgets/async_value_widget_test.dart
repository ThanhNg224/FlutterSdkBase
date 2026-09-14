import 'package:flutter/material.dart';
import 'package:flutter_sdk_base/core/errors/failure.dart';
import 'package:flutter_sdk_base/core/widgets/async_value_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/widget_harness.dart';

void main() {
  testWidgets('renders localized Failure copy without exposing its backend message', (tester) async {
    const backendMessage = 'PG::UniqueViolation on users.email at /internal/v2/admin';

    await tester.pumpWidget(
      harness(
        child: AsyncValueWidget<void>(
          value: AsyncValue.error(const Failure.server(message: backendMessage), StackTrace.empty),
          data: (_) => const SizedBox.shrink(),
        ),
      ),
    );

    expect(find.textContaining(backendMessage), findsNothing);
    expect(find.text('The server could not complete this request. Please try again in a moment.'), findsOneWidget);
  });
}
