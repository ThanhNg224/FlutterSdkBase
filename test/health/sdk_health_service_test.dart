import 'package:flutter_sdk_base/src/client/sdk_config.dart';
import 'package:flutter_sdk_base/src/client/sdk_request_executor.dart';
import 'package:flutter_sdk_base/src/errors/sdk_error_codes.dart';
import 'package:flutter_sdk_base/src/errors/sdk_exception.dart';
import 'package:flutter_sdk_base/src/health/sdk_health.dart';
import 'package:flutter_sdk_base/src/health/sdk_health_service.dart';
import 'package:flutter_sdk_base/src/transport/fake_sdk_http_transport.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/recording_sdk_logger.dart';

const String _testApiKey = 'test-api-key';
final DateTime _frozenNow = DateTime.utc(2026, 9, 14, 10, 30);

({SdkHealthService service, FakeSdkHttpTransport transport}) _subject({
  Uri? baseUri,
  RecordingSdkLogger? logger,
}) {
  final transport = FakeSdkHttpTransport();
  final config = SdkConfig(
    baseUri: baseUri ?? Uri.parse('https://api.example.com'),
    apiKey: _testApiKey,
  );
  final service = SdkHealthService(
    executor: SdkRequestExecutor(
      config: config,
      transport: transport,
      logger: logger ?? RecordingSdkLogger(),
    ),
    config: config,
    clock: () => _frozenNow,
  );
  return (service: service, transport: transport);
}

void main() {
  group('SdkHealthService.check', () {
    test('maps an ok status to a healthy result stamped by the injected clock', () async {
      final subject = _subject()..transport.enqueueJson('{"status":"ok"}');

      final SdkHealth health = await subject.service.check();

      expect(health.isHealthy, isTrue);
      expect(health.status, 'ok');
      expect(health.checkedAt, _frozenNow);
    });

    test('maps any other status to an unhealthy result', () async {
      final subject = _subject()..transport.enqueueJson('{"status":"degraded"}');

      final SdkHealth health = await subject.service.check();

      expect(health.isHealthy, isFalse);
      expect(health.status, 'degraded');
    });

    test('requests GET /health under the configured base path with auth', () async {
      final subject = _subject(baseUri: Uri.parse('https://api.example.com/v1'))
        ..transport.enqueueJson('{"status":"ok"}');

      await subject.service.check();

      final request = subject.transport.requests.single;
      expect(request.method, 'GET');
      expect(request.uri.toString(), 'https://api.example.com/v1/health');
      expect(request.headers['X-Api-Key'], _testApiKey);
    });

    test('maps 401 to unauthorized', () async {
      final subject = _subject()..transport.enqueueJson('{}', statusCode: 401);

      final SdkException error = await _captureSdkException(subject.service.check);

      expect(error.failure.code, SdkErrorCodes.unauthorized);
      expect(error.failure.statusCode, 401);
      expect(error.failure.isRetryable, isFalse);
    });

    test('maps 404 to client', () async {
      final subject = _subject()..transport.enqueueJson('{}', statusCode: 404);

      final SdkException error = await _captureSdkException(subject.service.check);

      expect(error.failure.code, SdkErrorCodes.client);
    });

    test('maps 503 to a retryable server failure', () async {
      final subject = _subject()..transport.enqueueJson('{}', statusCode: 503);

      final SdkException error = await _captureSdkException(subject.service.check);

      expect(error.failure.code, SdkErrorCodes.server);
      expect(error.failure.isRetryable, isTrue);
    });

    test('maps a 2xx body that is not JSON to invalidResponse', () async {
      final subject = _subject()..transport.enqueueJson('<html>oops</html>');

      final SdkException error = await _captureSdkException(subject.service.check);

      expect(error.failure.code, SdkErrorCodes.invalidResponse);
      expect(error.failure.isRetryable, isFalse);
    });

    test('maps a 2xx JSON body without a status field to invalidResponse', () async {
      final subject = _subject()..transport.enqueueJson('{"state":"ok"}');

      final SdkException error = await _captureSdkException(subject.service.check);

      expect(error.failure.code, SdkErrorCodes.invalidResponse);
    });
  });
}

Future<SdkException> _captureSdkException(Future<void> Function() action) async {
  try {
    await action();
  } on SdkException catch (error) {
    return error;
  }
  fail('expected an SdkException');
}
