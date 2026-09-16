import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_sdk_base/flutter_sdk_base.dart' show SdkOperationOutcome, sdkVersion;
import 'package:flutter_sdk_base/src/client/sdk_cancel_token.dart';
import 'package:flutter_sdk_base/src/client/sdk_config.dart';
import 'package:flutter_sdk_base/src/client/sdk_request_executor.dart';
import 'package:flutter_sdk_base/src/errors/sdk_error_codes.dart';
import 'package:flutter_sdk_base/src/errors/sdk_exception.dart';
import 'package:flutter_sdk_base/src/transport/fake_sdk_http_transport.dart';
import 'package:flutter_sdk_base/src/transport/sdk_http_request.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/recording_sdk_observer.dart';

const String _apiKey = 'secret-api-key';

SdkConfig _config({Duration timeout = const Duration(seconds: 15)}) => SdkConfig(
  baseUri: Uri.parse('https://api.example.com'),
  apiKey: _apiKey,
  requestTimeout: timeout,
);

SdkHttpRequest _request() => SdkHttpRequest(
  method: 'GET',
  uri: Uri.parse('https://api.example.com/health?secret=$_apiKey'),
  headers: <String, String>{'X-Secret': _apiKey},
  body: Uint8List.fromList(utf8.encode('body-secret=$_apiKey')),
);

Future<T> _execute<T>(
  SdkRequestExecutor executor, {
  SdkCancelToken? cancelToken,
  T Function(String body)? decode,
}) => executor.execute<T>(
  operation: 'health.check',
  request: _request(),
  cancelToken: cancelToken,
  decode: (response, requestId) => decode?.call(response.bodyAsString) as T,
);

void main() {
  group('SdkRequestExecutor', () {
    test('returns a decoded response and emits one success event', () async {
      final observer = RecordingSdkObserver();
      final transport = FakeSdkHttpTransport()..enqueueJson('{"status":"ok"}');
      final executor = SdkRequestExecutor(
        config: _config(),
        transport: transport,
        observer: observer,
      );

      expect(await _execute<String>(executor, decode: (body) => body), '{"status":"ok"}');
      expect(observer.events, hasLength(1));
      final event = observer.events.single;
      expect(event.operation, 'health.check');
      expect(event.requestId, transport.requests.single.headers['X-Request-Id']);
      expect(event.sdkVersion, sdkVersion);
      expect(event.outcome, SdkOperationOutcome.succeeded);
      expect(event.statusCode, 200);
      expect(event.failureCode, isNull);
      expect(event.isRetryable, isNull);
    });

    test('maps every non-2xx response centrally and includes status', () async {
      for (final (statusCode, code, retryable) in <(int, String, bool)>[
        (401, SdkErrorCodes.unauthorized, false),
        (503, SdkErrorCodes.server, true),
      ]) {
        final observer = RecordingSdkObserver();
        final transport = FakeSdkHttpTransport()..enqueueJson('{}', statusCode: statusCode);
        final executor = SdkRequestExecutor(
          config: _config(),
          transport: transport,
          observer: observer,
        );

        final SdkException error = await _captureSdkException(() => _execute<String>(executor));

        expect(error.failure.code, code);
        expect(observer.events, hasLength(1));
        expect(observer.events.single.outcome, SdkOperationOutcome.failed);
        expect(observer.events.single.statusCode, statusCode);
        expect(observer.events.single.failureCode, code);
        expect(observer.events.single.isRetryable, retryable);
      }
    });

    test('captures invalid response decoder failures as terminal invalid_response', () async {
      final observer = RecordingSdkObserver();
      final transport = FakeSdkHttpTransport()..enqueueJson('<html>secret=$_apiKey</html>');
      final executor = SdkRequestExecutor(
        config: _config(),
        transport: transport,
        observer: observer,
      );

      final SdkException error = await _captureSdkException(
        () => _execute<String>(executor, decode: (_) => throw const FormatException('bad JSON')),
      );

      expect(error.failure.code, SdkErrorCodes.invalidResponse);
      expect(observer.events.single.statusCode, 200);
      expect(observer.events.single.failureCode, SdkErrorCodes.invalidResponse);
      expect(observer.events.single.isRetryable, isFalse);
    });

    test('maps a timeout and cancels the call', () async {
      final observer = RecordingSdkObserver();
      final transport = FakeSdkHttpTransport()..enqueueNeverCompletes();
      final executor = SdkRequestExecutor(
        config: _config(timeout: const Duration(milliseconds: 30)),
        transport: transport,
        observer: observer,
      );

      final SdkException error = await _captureSdkException(() => _execute<String>(executor));

      expect(error.failure.code, SdkErrorCodes.timeout);
      expect(transport.hasPendingCancellation, isTrue);
      expect(observer.events.single.failureCode, SdkErrorCodes.timeout);
      expect(observer.events.single.isRetryable, isTrue);
    });

    test('pre-cancelled token emits cancelled without opening transport', () async {
      final observer = RecordingSdkObserver();
      final transport = FakeSdkHttpTransport();
      final executor = SdkRequestExecutor(
        config: _config(),
        transport: transport,
        observer: observer,
      );
      final token = SdkCancelToken()..cancel();

      final SdkException error = await _captureSdkException(
        () => _execute<String>(executor, cancelToken: token),
      );

      expect(error.failure.code, SdkErrorCodes.cancelled);
      expect(transport.requests, isEmpty);
      expect(observer.events, hasLength(1));
      expect(observer.events.single.failureCode, SdkErrorCodes.cancelled);
      expect(observer.events.single.statusCode, isNull);
      expect(observer.events.single.isRetryable, isFalse);
    });

    test('in-flight cancellation emits cancelled without closing transport', () async {
      final observer = RecordingSdkObserver();
      final transport = FakeSdkHttpTransport()..enqueueNeverCompletes();
      final executor = SdkRequestExecutor(
        config: _config(),
        transport: transport,
        observer: observer,
      );
      final token = SdkCancelToken();
      final Future<SdkException> pending = _captureSdkException(
        () => _execute<String>(executor, cancelToken: token),
      );
      await Future<void>.delayed(Duration.zero);
      token.cancel();

      final SdkException error = await pending;

      expect(error.failure.code, SdkErrorCodes.cancelled);
      expect(transport.hasPendingCancellation, isTrue);
      expect(transport.isClosed, isFalse);
      expect(observer.events.single.failureCode, SdkErrorCodes.cancelled);
    });

    test('maps transport failures and never exposes secret values in events', () async {
      final observer = RecordingSdkObserver();
      final transport = FakeSdkHttpTransport()..enqueueError(Exception('socket leaked $_apiKey'));
      final executor = SdkRequestExecutor(
        config: _config(),
        transport: transport,
        observer: observer,
      );

      final SdkException error = await _captureSdkException(() => _execute<String>(executor));

      expect(error.failure.code, SdkErrorCodes.transport);
      expect(error.failure.cause, isNotNull);
      expect(observer.events, hasLength(1));
      final event = observer.events.single;
      expect(
        <Object?>[
          event.operation,
          event.requestId,
          event.sdkVersion,
          event.outcome,
          event.elapsed,
          event.statusCode,
          event.failureCode,
          event.isRetryable,
        ].join(' '),
        isNot(contains(_apiKey)),
      );
      expect(event.requestId, transport.requests.single.headers['X-Request-Id']);
    });

    test('swallows observer exceptions', () async {
      final transport = FakeSdkHttpTransport()..enqueueJson('{"status":"ok"}');
      final executor = SdkRequestExecutor(
        config: _config(),
        transport: transport,
        observer: ThrowingSdkObserver(),
      );

      expect(await _execute<String>(executor, decode: (body) => body), '{"status":"ok"}');
    });

    test('adds version and request ID without mutating request headers', () async {
      final transport = FakeSdkHttpTransport()..enqueueJson('{"status":"ok"}');
      final executor = SdkRequestExecutor(
        config: _config(),
        transport: transport,
        observer: RecordingSdkObserver(),
      );
      final request = _request();
      final Map<String, String> original = Map<String, String>.of(request.headers);

      await executor.execute<String>(
        operation: 'health.check',
        request: request,
        decode: (response, requestId) => response.bodyAsString,
      );

      expect(request.headers, original);
      expect(transport.requests.single.headers['X-Sdk-Version'], sdkVersion);
      expect(transport.requests.single.headers['X-Request-Id'], matches(RegExp(r'^[0-9a-f]{32}$')));
    });

    test('send after close throws StateError and emits no event', () async {
      final observer = RecordingSdkObserver();
      final executor = SdkRequestExecutor(
        config: _config(),
        transport: FakeSdkHttpTransport(),
        observer: observer,
      );
      await executor.close();

      expect(() => _execute<String>(executor), throwsStateError);
      expect(observer.events, isEmpty);
    });

    test('close is idempotent', () async {
      final executor = SdkRequestExecutor(
        config: _config(),
        transport: FakeSdkHttpTransport(),
        observer: RecordingSdkObserver(),
      );

      await executor.close();
      await expectLater(executor.close(), completes);
      expect(executor.isClosed, isTrue);
    });
  });
}

Future<SdkException> _captureSdkException(Future<Object?> Function() action) async {
  try {
    await action();
  } on SdkException catch (error) {
    return error;
  }
  fail('expected an SdkException');
}
