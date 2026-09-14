import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_sdk_base/src/transport/sdk_http_request.dart';
import 'package:flutter_sdk_base/src/transport/sdk_http_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SdkHttpRequest carries method, uri, headers and an optional body', () {
    final request = SdkHttpRequest(
      method: 'GET',
      uri: Uri.parse('https://api.example.com/health'),
      headers: const <String, String>{'accept': 'application/json'},
    );

    expect(request.method, 'GET');
    expect(request.uri.path, '/health');
    expect(request.headers['accept'], 'application/json');
    expect(request.body, isNull);
  });

  test('SdkHttpResponse decodes its body as UTF-8', () {
    final response = SdkHttpResponse(
      statusCode: 200,
      headers: const <String, String>{},
      body: Uint8List.fromList(utf8.encode('{"status":"ok"}')),
    );

    expect(response.bodyAsString, '{"status":"ok"}');
  });

  test('SdkHttpResponse.bodyAsString tolerates malformed UTF-8', () {
    final response = SdkHttpResponse(
      statusCode: 200,
      headers: const <String, String>{},
      body: Uint8List.fromList(<int>[0xC3, 0x28]),
    );

    expect(response.bodyAsString, isNotEmpty);
  });
}
