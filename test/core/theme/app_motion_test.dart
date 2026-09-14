import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sdk_base/core/theme/app_motion.dart';

import '../../support/widget_harness.dart';

Future<List<Widget>> _entranceUnder(WidgetTester tester, {required bool disableAnimations}) async {
  late List<Widget> result;
  final children = <Widget>[const Text('a'), const Text('b'), const Text('c')];

  await tester.pumpWidget(
    harness(
      child: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Builder(
          builder: (context) {
            result = children.staggeredEntrance(context);
            return Column(children: result);
          },
        ),
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 2));
  return result;
}

void main() {
  group('staggeredEntrance', () {
    testWidgets('animates when the platform allows motion', (tester) async {
      final result = await _entranceUnder(tester, disableAnimations: false);

      expect(result, isA<AnimateList>());
      expect(find.byType(Animate), findsNWidgets(3));
    });

    testWidgets('returns children untouched under reduced motion', (tester) async {
      final result = await _entranceUnder(tester, disableAnimations: true);

      expect(result, isNot(isA<AnimateList>()));
      expect(find.byType(Animate), findsNothing);
      expect(find.text('a'), findsOneWidget);
      expect(find.text('c'), findsOneWidget);
    });
  });
}
