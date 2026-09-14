import 'package:flutter_sdk_base/src/transport/fake_sdk_http_transport.dart';
import 'package:flutter_sdk_base/src/transport/sdk_http_request.dart';
import 'package:flutter_test/flutter_test.dart';

SdkHttpRequest _request() => SdkHttpRequest(
  method: 'GET',
  uri: Uri.parse('https://api.example.com/health'),
  headers: const <String, String>{},
);

void main() {
  group('FakeSdkHttpTransport', () {
    test('serves queued responses in order and records requests', () async {
      final transport = FakeSdkHttpTransport()
        ..enqueueJson('{"status":"ok"}')
        ..enqueueJson('{"status":"degraded"}', statusCode: 503);

      final first = await transport.open(_request()).response;
      final second = await transport.open(_request()).response;

      expect(first.statusCode, 200);
      expect(first.bodyAsString, '{"status":"ok"}');
      expect(second.statusCode, 503);
      expect(transport.requests, hasLength(2));
    });

    test('surfaces an enqueued error', () async {
      final transport = FakeSdkHttpTransport()..enqueueError(const SocketFailure());

      await expectLater(transport.open(_request()).response, throwsA(isA<SocketFailure>()));
    });

    test('cancel completes a never-completing call with an error', () async {
      final transport = FakeSdkHttpTransport()..enqueueNeverCompletes();
      final call = transport.open(_request());

      final pending = expectLater(call.response, throwsA(anything));
      await call.cancel();
      await pending;

      expect(transport.hasPendingCancellation, isTrue);
    });

    test('throws a clear error when nothing is queued', () {
      final transport = FakeSdkHttpTransport();

      expect(() => transport.open(_request()), throwsStateError);
    });

    test('close marks the transport closed', () async {
      final transport = FakeSdkHttpTransport();
      await transport.close();

      expect(transport.isClosed, isTrue);
    });
  });
}

final class SocketFailure implements Exception {
  const SocketFailure();
}
