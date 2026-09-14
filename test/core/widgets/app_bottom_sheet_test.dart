import 'package:flutter/material.dart';
import 'package:flutter_sdk_base/core/widgets/app_bottom_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/widget_harness.dart';

void main() {
  testWidgets('renders a rounded, draggable sheet with an icon/title header and a close action', (tester) async {
    await tester.pumpWidget(
      harness(
        child: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => AppBottomSheet.show<void>(
                context: context,
                title: 'Create post',
                icon: Icons.post_add_rounded,
                builder: (_) => const Text('sheet body'),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Header: icon + title + close action are all present.
    expect(find.text('Create post'), findsOneWidget);
    expect(find.byIcon(Icons.post_add_rounded), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    // Content passed to `builder` is rendered below the header.
    expect(find.text('sheet body'), findsOneWidget);

    // Rounded top corners, not a plain rectangle.
    final material = tester.widget<Material>(
      find.descendant(of: find.byType(BottomSheet), matching: find.byType(Material)).first,
    );
    final shape = material.shape as RoundedRectangleBorder;
    expect(shape.borderRadius, const BorderRadius.vertical(top: Radius.circular(24)));

    // The close button dismisses the sheet.
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.text('sheet body'), findsNothing);
  });

  testWidgets('renders without a header when no title is given', (tester) async {
    await tester.pumpWidget(
      harness(
        child: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => AppBottomSheet.show<void>(
                context: context,
                builder: (_) => const Text('untitled body'),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.close_rounded), findsNothing);
    expect(find.text('untitled body'), findsOneWidget);
  });
}
