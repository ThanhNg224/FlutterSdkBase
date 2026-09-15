import 'dart:async';

import 'package:flutter_sdk_base/src/client/sdk_config.dart';
import 'package:flutter_sdk_base/src/client/sdk_request_executor.dart';
import 'package:flutter_sdk_base/src/errors/sdk_error_codes.dart';
import 'package:flutter_sdk_base/src/errors/sdk_exception.dart';
import 'package:flutter_sdk_base/src/transport/fake_sdk_http_transport.dart';
import 'package:flutter_sdk_base/src/transport/sdk_http_call.dart';
import 'package:flutter_sdk_base/src/transport/sdk_http_request.dart';
import 'package:flutter_sdk_base/src/transport/sdk_http_response.dart';
import 'package:flutter_sdk_base/src/transport/sdk_http_transport.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/recording_sdk_logger.dart';

const String _apiKey = 'sk_live_5f2b9c7e4a1d';

SdkConfig _config({Duration timeout = const Duration(seconds: 15)}) => SdkConfig(
  baseUri: Uri.parse('https://api.example.com'),
  apiKey: _apiKey,
  requestTimeout: timeout,
);

SdkHttpRequest _request() => SdkHttpRequest(
  method: 'GET',
  uri: Uri.parse('https://api.example.com/health'),
  headers: const <String, String>{},
);

void main() {
  group('SdkRequestExecutor', () {
    test('returns the transport response unchanged on success', () async {
      final transport = FakeSdkHttpTransport()..enqueueJson('{"status":"ok"}');
      final executor = SdkRequestExecutor(config: _config(), transport: transport, logger: RecordingSdkLogger());

      final response = await executor.send(_request());

      expect(response.statusCode, 200);
    });

    test('authHeaders carries the api key and a JSON accept header', () {
      final executor = SdkRequestExecutor(
        config: _config(),
        transport: FakeSdkHttpTransport(),
        logger: RecordingSdkLogger(),
      );

      expect(executor.authHeaders()['X-Api-Key'], _apiKey);
      expect(executor.authHeaders()['Accept'], 'application/json');
    });

    test('maps a transport error to a retryable transport failure', () async {
      final transport = FakeSdkHttpTransport()..enqueueError(Exception('socket down'));
      final executor = SdkRequestExecutor(config: _config(), transport: transport, logger: RecordingSdkLogger());

      final SdkException error = await _captureSdkException(() => executor.send(_request()));

      expect(error.failure.code, SdkErrorCodes.transport);
      expect(error.failure.isRetryable, isTrue);
      expect(error.failure.cause, isNotNull);
    });

    test('fails with timeout and cancels the call when the deadline passes', () async {
      final transport = FakeSdkHttpTransport()..enqueueNeverCompletes();
      final executor = SdkRequestExecutor(
        config: _config(timeout: const Duration(milliseconds: 30)),
        transport: transport,
        logger: RecordingSdkLogger(),
      );

      final SdkException error = await _captureSdkException(() => executor.send(_request()));

      expect(error.failure.code, SdkErrorCodes.timeout);
      expect(error.failure.isRetryable, isTrue);
      expect(transport.hasPendingCancellation, isTrue);
    });

    test('close cancels an in-flight call, which fails as cancelled', () async {
      final transport = FakeSdkHttpTransport()..enqueueNeverCompletes();
      final executor = SdkRequestExecutor(config: _config(), transport: transport, logger: RecordingSdkLogger());

      final Future<SdkException> pending = _captureSdkException(() => executor.send(_request()));
      await Future<void>.delayed(Duration.zero);
      await executor.close();

      final SdkException error = await pending;
      expect(error.failure.code, SdkErrorCodes.cancelled);
      expect(error.failure.isRetryable, isFalse);
      expect(transport.isClosed, isTrue);
    });

    test('close is idempotent', () async {
      final executor = SdkRequestExecutor(
        config: _config(),
        transport: FakeSdkHttpTransport(),
        logger: RecordingSdkLogger(),
      );

      await executor.close();
      await expectLater(executor.close(), completes);
      expect(executor.isClosed, isTrue);
    });

    test('send after close throws StateError, not SdkException', () async {
      final executor = SdkRequestExecutor(
        config: _config(),
        transport: FakeSdkHttpTransport(),
        logger: RecordingSdkLogger(),
      );
      await executor.close();

      expect(() => executor.send(_request()), throwsStateError);
    });

    test(
      'never logs the api key verbatim across success, HTTP error, timeout, cancellation, or transport failure',
      () async {
        final logger = RecordingSdkLogger();

        final success = SdkRequestExecutor(
          config: _config(),
          transport: FakeSdkHttpTransport()..enqueueJson('{"status":"ok"}'),
          logger: logger,
        );
        await success.send(_request());

        final httpError = SdkRequestExecutor(
          config: _config(),
          transport: FakeSdkHttpTransport()..enqueueJson('{}', statusCode: 401),
          logger: logger,
        );
        await httpError.send(_request());

        final timeout = SdkRequestExecutor(
          config: _config(timeout: const Duration(milliseconds: 30)),
          transport: FakeSdkHttpTransport()..enqueueNeverCompletes(),
          logger: logger,
        );
        await _captureSdkException(() => timeout.send(_request()));

        final cancellationTransport = FakeSdkHttpTransport()..enqueueNeverCompletes();
        final cancelled = SdkRequestExecutor(config: _config(), transport: cancellationTransport, logger: logger);
        final Future<SdkException> cancelledResult = _captureSdkException(() => cancelled.send(_request()));
        await Future<void>.delayed(Duration.zero);
        await cancelled.close();
        await cancelledResult;

        final transportFailure = SdkRequestExecutor(
          config: _config(),
          transport: FakeSdkHttpTransport()..enqueueError(Exception('request failed for $_apiKey')),
          logger: logger,
        );
        await _captureSdkException(() => transportFailure.send(_request()));

        expect(logger.combined, isNot(contains(_apiKey)));
        expect(logger.combined, contains('sk_l…4a1d'));
      },
    );

    test('close releases the transport even when a call cancel fails', () async {
      final transport = _FailingCancelTransport();
      final executor = SdkRequestExecutor(config: _config(), transport: transport, logger: RecordingSdkLogger());

      final Future<SdkException> pending = _captureSdkException(() => executor.send(_request()));
      await Future<void>.delayed(Duration.zero);

      await expectLater(executor.close(), throwsA(isA<StateError>()));
      await pending;

      expect(transport.isClosed, isTrue, reason: 'a failing cancel must not leak the transport');
    });
  });
}

/// A transport whose calls fail while being cancelled, to prove `close()` still
/// releases the transport instead of leaking it.
final class _FailingCancelTransport implements SdkHttpTransport {
  bool isClosed = false;

  @override
  SdkHttpCall open(SdkHttpRequest request) => _FailingCancelCall();

  @override
  Future<void> close() async {
    isClosed = true;
  }
}

final class _FailingCancelCall implements SdkHttpCall {
  final Completer<SdkHttpResponse> _completer = Completer<SdkHttpResponse>();

  @override
  Future<SdkHttpResponse> get response => _completer.future;

  @override
  Future<void> cancel() async {
    if (!_completer.isCompleted) {
      _completer.completeError(const SdkCallCancelled());
    }
    throw StateError('cancel failed');
  }
}

Future<SdkException> _captureSdkException(Future<void> Function() action) async {
  try {
    await action();
  } on SdkException catch (error) {
    return error;
  }
  fail('expected an SdkException');
}
