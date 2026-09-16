import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sdk_base_example/app/app.dart';
import 'package:flutter_sdk_base_example/app/providers/app_providers.dart';
import 'package:flutter_sdk_base_example/core/demo/demo_health_scenario.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('starts on the Health route', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: HostApp()));
    await tester.pumpAndSettle();

    expect(find.text('SDK health'), findsOneWidget);
    expect(find.text('Check health'), findsOneWidget);
  });

  testWidgets('navigates to Settings from the host shell', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: HostApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Host diagnostics'), findsOneWidget);
    expect(find.text('Offline deterministic fake transport'), findsOneWidget);
  });

  testWidgets('renders a successful health check', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: HostApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Check health'));
    await tester.pumpAndSettle();

    expect(find.text('Healthy'), findsOneWidget);
    expect(find.text('Status: ok'), findsOneWidget);
  });

  testWidgets('renders unauthorized error copy from an overridden scenario', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          demoHealthScenarioProvider.overrideWithValue(DemoHealthScenario.unauthorized),
        ],
        child: const HostApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Check health'));
    await tester.pumpAndSettle();

    expect(find.text('Your API key was rejected.'), findsOneWidget);
  });
}
