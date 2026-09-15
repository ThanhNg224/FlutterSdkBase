@TestOn('vm')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_sdk_base/flutter_sdk_base.dart';
import 'package:flutter_sdk_base/src/transport/package_http_transport.dart';
import 'package:flutter_test/flutter_test.dart';

/// Exercises the real network path over a loopback server.
///
/// Every other test in this package injects a transport, so nothing else ever
/// constructs the default `package:http` implementation or opens a socket.
/// These tests deliberately omit `transport:` so the path a host actually uses
/// is the one under test.
void main() {
  late HttpServer server;
  late Uri baseUri;
  late Future<void> Function(HttpRequest request) handler;

  String? seenPath;
  String? seenApiKey;
  String? seenAccept;

  setUp(() async {
    seenPath = null;
    seenApiKey = null;
    seenAccept = null;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    baseUri = Uri.parse('http://${server.address.address}:${server.port}');
    unawaited(
      server.forEach((HttpRequest request) async {
        seenPath = request.uri.path;
        seenApiKey = request.headers.value('X-Api-Key');
        seenAccept = request.headers.value('Accept');
        try {
          await handler(request);
        } on Object {
          // The client may have walked away; the test asserts on the SDK, not
          // on the server's ability to finish writing.
        }
      }),
    );
  });

  tearDown(() async {
    await server.close(force: true);
  });

  Future<void> respond(HttpRequest request, {int status = 200, String body = '{"status":"ok"}'}) async {
    request.response.statusCode = status;
    request.response.headers.contentType = ContentType.json;
    request.response.write(body);
    await request.response.close();
  }

  SdkConfig config({String path = '', Duration timeout = const Duration(seconds: 10)}) => SdkConfig(
    baseUri: path.isEmpty ? baseUri : baseUri.replace(path: path),
    apiKey: 'sk_live_5f2b9c7e4a1d',
    requestTimeout: timeout,
  );

  group('default transport over a real socket', () {
    test('a client built without a transport completes a health check', () async {
      handler = (HttpRequest request) => respond(request);
      final client = SdkClient(config: config());

      final SdkHealth health = await client.health.check();

      expect(health.isHealthy, isTrue);
      expect(health.status, 'ok');
      await client.close();
    });

    test('the auth and accept headers actually arrive at the server', () async {
      handler = (HttpRequest request) => respond(request);
      final client = SdkClient(config: config());

      await client.health.check();

      expect(seenApiKey, 'sk_live_5f2b9c7e4a1d');
      expect(seenAccept, 'application/json');
      await client.close();
    });

    test('a base path is preserved on the wire', () async {
      handler = (HttpRequest request) => respond(request);
      final client = SdkClient(config: config(path: '/v1'));

      await client.health.check();

      expect(seenPath, '/v1/health');
      await client.close();
    });

    test('a real 401 maps to unauthorized', () async {
      handler = (HttpRequest request) => respond(request, status: 401, body: '{}');
      final client = SdkClient(config: config());

      await expectLater(
        client.health.check(),
        throwsA(
          isA<SdkException>().having(
            (SdkException error) => error.failure.code,
            'code',
            SdkErrorCodes.unauthorized,
          ),
        ),
      );
      await client.close();
    });

    test('a non-JSON 2xx body maps to invalidResponse', () async {
      handler = (HttpRequest request) => respond(request, body: '<html>oops</html>');
      final client = SdkClient(config: config());

      await expectLater(
        client.health.check(),
        throwsA(
          isA<SdkException>().having(
            (SdkException error) => error.failure.code,
            'code',
            SdkErrorCodes.invalidResponse,
          ),
        ),
      );
      await client.close();
    });

    test('the timeout fires against real latency', () async {
      handler = (HttpRequest request) async {
        await Future<void>.delayed(const Duration(seconds: 2));
        await respond(request);
      };
      final client = SdkClient(config: config(timeout: const Duration(milliseconds: 80)));

      await expectLater(
        client.health.check(),
        throwsA(
          isA<SdkException>().having(
            (SdkException error) => error.failure.code,
            'code',
            SdkErrorCodes.timeout,
          ),
        ),
      );
      await client.close();
    });

    test('close blocks further work on a client that owns the default transport', () async {
      handler = (HttpRequest request) => respond(request);
      final client = SdkClient(config: config());
      await client.health.check();

      await client.close();

      expect(client.health.check, throwsStateError);
    });
  });

  test('the default PackageHttpTransport creates and then releases its own client', () async {
    handler = (HttpRequest request) => respond(request);
    final transport = PackageHttpTransport();
    final SdkHttpRequest request = SdkHttpRequest(
      method: 'GET',
      uri: baseUri.replace(path: '/health'),
      headers: const <String, String>{'Accept': 'application/json'},
    );

    final SdkHttpResponse response = await transport.open(request).response;
    expect(response.statusCode, 200);
    expect(jsonDecode(response.bodyAsString), isA<Map<String, Object?>>());

    await transport.close();

    // A released client refuses further work with a specific message. Matching
    // it — rather than accepting any error — is what stops this test passing
    // for an unrelated reason such as the server having gone away.
    await expectLater(
      transport.open(request).response,
      throwsA(
        predicate<Object>(
          (Object error) => error.toString().contains('Client is already closed'),
          'a ClientException reporting the client is already closed',
        ),
      ),
    );
  });
}
