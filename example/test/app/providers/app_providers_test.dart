import 'dart:convert';

import 'package:flutter_sdk_base/flutter_sdk_base.dart';
import 'package:flutter_sdk_base_example/app/providers/app_providers.dart';
import 'package:flutter_sdk_base_example/core/demo/demo_health_scenario.dart';
import 'package:flutter_sdk_base_example/core/demo/demo_sdk_http_transport.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the demo transport reads the scenario for each open call', () async {
    DemoHealthScenario scenario = DemoHealthScenario.healthy;
    final DemoSdkHttpTransport transport = DemoSdkHttpTransport(
      scenarioReader: () => scenario,
    );
    addTearDown(transport.close);
    final SdkHttpRequest request = SdkHttpRequest(
      method: 'GET',
      uri: Uri.parse('https://api.example.com/health'),
      headers: <String, String>{},
    );

    final SdkHttpCall firstCall = transport.open(request);
    scenario = DemoHealthScenario.unauthorized;
    final SdkHttpCall secondCall = transport.open(request);

    final SdkHttpResponse firstResponse = await firstCall.response;
    final SdkHttpResponse secondResponse = await secondCall.response;

    expect(firstResponse.statusCode, 200);
    expect(jsonDecode(firstResponse.bodyAsString), <String, String>{'status': 'ok'});
    expect(secondResponse.statusCode, 401);
  });

  test('the default client returns healthy data', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final SdkHealth health = await container.read(sdkClientProvider).health.check();

    expect(health.isHealthy, isTrue);
    expect(health.status, 'ok');
  });

  test('an unauthorized scenario maps to the SDK unauthorized error code', () async {
    final container = ProviderContainer(
      overrides: [
        demoHealthScenarioProvider.overrideWithValue(DemoHealthScenario.unauthorized),
      ],
    );
    addTearDown(container.dispose);

    expect(
      () => container.read(sdkClientProvider).health.check(),
      throwsA(
        isA<SdkException>().having(
          (SdkException error) => error.failure.code,
          'failure code',
          SdkErrorCodes.unauthorized,
        ),
      ),
    );
  });

  test('disposing the provider container closes the SDK transport', () async {
    final container = ProviderContainer();
    final DemoSdkHttpTransport transport = container.read(demoTransportProvider);
    container.read(sdkClientProvider);

    container.dispose();
    await Future<void>.delayed(Duration.zero);

    expect(transport.isClosed, isTrue);
  });
}
