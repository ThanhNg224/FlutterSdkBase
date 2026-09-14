import 'dart:async';

import 'package:flutter_sdk_base/src/transport/package_http_transport.dart';
import 'package:flutter_sdk_base/src/transport/sdk_http_request.dart';
import 'package:flutter_sdk_base/src/transport/sdk_http_response.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

SdkHttpRequest _request() => SdkHttpRequest(
  method: 'GET',
  uri: Uri.parse('https://api.example.com/health'),
  headers: const <String, String>{'X-Api-Key': 'key'},
);

void main() {
  group('PackageHttpTransport', () {
    test('forwards method, uri and headers, and returns status and body', () async {
      late http.Request seen;
      final transport = PackageHttpTransport(
        client: MockClient((http.Request request) async {
          seen = request;
          return http.Response('{"status":"ok"}', 200);
        }),
      );

      final SdkHttpResponse response = await transport.open(_request()).response;

      expect(seen.method, 'GET');
      expect(seen.url.toString(), 'https://api.example.com/health');
      expect(seen.headers['X-Api-Key'], 'key');
      expect(response.statusCode, 200);
      expect(response.bodyAsString, '{"status":"ok"}');
    });

    test('surfaces a client error through the response future', () async {
      final transport = PackageHttpTransport(
        client: MockClient((http.Request request) async => throw http.ClientException('boom')),
      );

      await expectLater(transport.open(_request()).response, throwsA(isA<http.ClientException>()));
    });

    test('cancel completes the pending response with an error', () async {
      final Completer<http.Response> never = Completer<http.Response>();
      final transport = PackageHttpTransport(client: MockClient((http.Request request) => never.future));

      final call = transport.open(_request());
      final Future<void> pending = expectLater(call.response, throwsA(anything));
      await call.cancel();
      await pending;
    });

    test('close releases the underlying client', () async {
      final transport = PackageHttpTransport(
        client: MockClient((http.Request request) async => http.Response('{}', 200)),
      );

      await expectLater(transport.close(), completes);
    });
  });
}
