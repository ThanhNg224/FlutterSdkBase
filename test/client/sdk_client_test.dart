import 'package:flutter_sdk_base/flutter_sdk_base.dart';
import 'package:flutter_sdk_base/flutter_sdk_base_testing.dart';
import 'package:flutter_test/flutter_test.dart';

const String _testApiKey = 'test-api-key';

SdkConfig _config() => SdkConfig(
  baseUri: Uri.parse('https://api.example.com'),
  apiKey: _testApiKey,
);

void main() {
  group('SdkClient', () {
    test('performs a health check through an injected transport', () async {
      final transport = FakeSdkHttpTransport()..enqueueJson('{"status":"ok"}');
      final client = SdkClient(config: _config(), transport: transport);

      final SdkHealth health = await client.health.check();

      expect(health.isHealthy, isTrue);
      await client.close();
    });

    test('returns the same health service on repeated access', () {
      final client = SdkClient(config: _config(), transport: FakeSdkHttpTransport());

      expect(identical(client.health, client.health), isTrue);
    });

    test('close is idempotent and closes the owned transport', () async {
      final transport = FakeSdkHttpTransport();
      final client = SdkClient(config: _config(), transport: transport);

      await client.close();
      await expectLater(client.close(), completes);
      expect(transport.isClosed, isTrue);
    });

    test('an operation after close throws StateError', () async {
      final client = SdkClient(config: _config(), transport: FakeSdkHttpTransport());
      await client.close();

      expect(client.health.check, throwsStateError);
    });

    test('two clients run concurrently without sharing state', () async {
      final firstTransport = FakeSdkHttpTransport()..enqueueJson('{"status":"ok"}');
      final secondTransport = FakeSdkHttpTransport()..enqueueJson('{"status":"degraded"}');
      final first = SdkClient(config: _config(), transport: firstTransport);
      final second = SdkClient(config: _config(), transport: secondTransport);

      final List<SdkHealth> results = await Future.wait<SdkHealth>(<Future<SdkHealth>>[
        first.health.check(),
        second.health.check(),
      ]);

      expect(results[0].status, 'ok');
      expect(results[1].status, 'degraded');

      await first.close();
      expect(secondTransport.isClosed, isFalse, reason: 'closing one client must not affect another');
      await second.close();
    });

    test('a host can observe failures through SdkException only', () async {
      final transport = FakeSdkHttpTransport()..enqueueJson('{}', statusCode: 500);
      final client = SdkClient(config: _config(), transport: transport);

      try {
        await client.health.check();
        fail('expected an SdkException');
      } on SdkException catch (error) {
        expect(error.failure.code, SdkErrorCodes.server);
        expect(error.failure.isRetryable, isTrue);
      }

      await client.close();
    });
  });
}
