import 'dart:async';

import 'package:flutter_sdk_base/flutter_sdk_base.dart';
import 'package:flutter_sdk_base/flutter_sdk_base_testing.dart';
import 'package:flutter_test/flutter_test.dart';

SdkConfig _config() => SdkConfig(
  baseUri: Uri.parse('https://api.example.com'),
  apiKey: 'test-key',
);

void main() {
  group('SdkCancelToken', () {
    test('is idempotent and reports cancellation', () {
      final token = SdkCancelToken();

      expect(token.isCancelled, isFalse);
      token.cancel();
      token.cancel();

      expect(token.isCancelled, isTrue);
    });

    test('cancelling before check fails without opening a request', () async {
      final token = SdkCancelToken()..cancel();
      final transport = FakeSdkHttpTransport();
      final client = SdkClient(config: _config(), transport: transport);

      final SdkException error = await _captureSdkException(
        () => client.health.check(cancelToken: token),
      );

      expect(error.failure.code, SdkErrorCodes.cancelled);
      expect(error.failure.requestId, isNotEmpty);
      expect(transport.requests, isEmpty);
      await client.close();
    });

    test('cancelling one operation keeps the client and independent work usable', () async {
      final token = SdkCancelToken();
      final transport = FakeSdkHttpTransport()
        ..enqueueNeverCompletes()
        ..enqueueJson('{"status":"ok"}');
      final client = SdkClient(config: _config(), transport: transport);

      final Future<SdkException> cancelled = _captureSdkException(
        () => client.health.check(cancelToken: token),
      );
      await Future<void>.delayed(Duration.zero);
      token.cancel();

      final SdkException error = await cancelled;
      expect(error.failure.code, SdkErrorCodes.cancelled);
      expect(error.failure.requestId, transport.requests.single.headers['X-Request-Id']);
      expect(transport.hasPendingCancellation, isTrue);
      expect(transport.isClosed, isFalse);

      final SdkHealth health = await client.health.check();
      expect(health.status, 'ok');
      await client.close();
    });

    test('reusing a token cancels every operation sharing it', () async {
      final token = SdkCancelToken();
      final transport = FakeSdkHttpTransport()
        ..enqueueNeverCompletes()
        ..enqueueNeverCompletes();
      final client = SdkClient(config: _config(), transport: transport);

      final Future<SdkException> first = _captureSdkException(
        () => client.health.check(cancelToken: token),
      );
      final Future<SdkException> second = _captureSdkException(
        () => client.health.check(cancelToken: token),
      );
      await Future<void>.delayed(Duration.zero);
      token.cancel();

      expect((await first).failure.code, SdkErrorCodes.cancelled);
      expect((await second).failure.code, SdkErrorCodes.cancelled);
      expect(transport.requests, hasLength(2));
      expect(transport.isClosed, isFalse);
      await client.close();
    });

    test('continues cancelling a shared token when one call throws synchronously', () async {
      final token = SdkCancelToken();
      final transport = _SynchronousThrowCancelTransport();
      final client = SdkClient(config: _config(), transport: transport);

      final Future<SdkException> first = _captureSdkException(
        () => client.health.check(cancelToken: token),
      );
      final Future<SdkException> second = _captureSdkException(
        () => client.health.check(cancelToken: token),
      );
      await Future<void>.delayed(Duration.zero);
      token.cancel();

      expect((await first).failure.code, SdkErrorCodes.cancelled);
      expect((await second).failure.code, SdkErrorCodes.cancelled);
      expect(transport.cancelCalls, 2);
      await client.close();
    });

    test('deregisters listeners and invokes late listeners immediately', () {
      final token = SdkCancelToken();
      var removedCalls = 0;
      final void Function() remove = token.addListener(() => removedCalls++);
      remove();
      token.cancel();
      expect(removedCalls, 0);

      var lateCalls = 0;
      token.addListener(() => lateCalls++);
      expect(lateCalls, 1);
      token.cancel();
      expect(lateCalls, 1);
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

final class _SynchronousThrowCancelTransport implements SdkHttpTransport {
  int cancelCalls = 0;
  int _openedCalls = 0;

  @override
  SdkHttpCall open(SdkHttpRequest request) {
    final bool shouldThrowSynchronously = _openedCalls++ == 0;
    return _SynchronousThrowCancelCall(
      shouldThrowSynchronously: shouldThrowSynchronously,
      onCancel: () => cancelCalls++,
    );
  }

  @override
  Future<void> close() async {}
}

final class _SynchronousThrowCancelCall implements SdkHttpCall {
  _SynchronousThrowCancelCall({required this.shouldThrowSynchronously, required this.onCancel});

  final bool shouldThrowSynchronously;
  final void Function() onCancel;
  final Completer<SdkHttpResponse> _response = Completer<SdkHttpResponse>();

  @override
  Future<SdkHttpResponse> get response => _response.future;

  @override
  Future<void> cancel() {
    onCancel();
    _response.completeError(StateError('cancelled by test transport'));
    if (shouldThrowSynchronously) {
      throw StateError('synchronous cancel failure');
    }
    return Future<void>.value();
  }
}
