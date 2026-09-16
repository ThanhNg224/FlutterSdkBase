import 'package:flutter_sdk_base/flutter_sdk_base.dart';
import 'package:flutter_sdk_base/flutter_sdk_base_testing.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/recording_sdk_observer.dart';

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

    test('emits one terminal success event for a health check', () async {
      final observer = RecordingSdkObserver();
      final client = SdkClient(
        config: _config(),
        transport: FakeSdkHttpTransport()..enqueueJson('{"status":"ok"}'),
        observer: observer,
      );

      await client.health.check();

      expect(observer.events, hasLength(1));
      final event = observer.events.single;
      expect(event.operation, 'health.check');
      expect(event.sdkVersion, isNotEmpty);
      expect(event.outcome, SdkOperationOutcome.succeeded);
      expect(event.elapsed, greaterThanOrEqualTo(Duration.zero));
      expect(event.failureCode, isNull);
      expect(event.isRetryable, isNull);
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

    test('close emits one cancelled terminal event for in-flight work', () async {
      final observer = RecordingSdkObserver();
      final transport = FakeSdkHttpTransport()..enqueueNeverCompletes();
      final client = SdkClient(config: _config(), transport: transport, observer: observer);
      final Future<SdkException> pending = _captureSdkException(client.health.check);
      await Future<void>.delayed(Duration.zero);

      await client.close();
      final SdkException error = await pending;

      expect(error.failure.code, SdkErrorCodes.cancelled);
      expect(observer.events, hasLength(1));
      expect(observer.events.single.outcome, SdkOperationOutcome.failed);
      expect(observer.events.single.failureCode, SdkErrorCodes.cancelled);
      expect(observer.events.single.isRetryable, isFalse);
    });

    test('an operation after close throws StateError', () async {
      final observer = RecordingSdkObserver();
      final client = SdkClient(
        config: _config(),
        transport: FakeSdkHttpTransport(),
        observer: observer,
      );
      await client.close();

      expect(client.health.check, throwsStateError);
      expect(observer.events, isEmpty);
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

Future<SdkException> _captureSdkException(Future<SdkHealth> Function() action) async {
  try {
    await action();
  } on SdkException catch (error) {
    return error;
  }
  fail('expected an SdkException');
}
