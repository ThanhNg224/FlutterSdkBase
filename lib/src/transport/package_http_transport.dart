import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_sdk_base/src/transport/sdk_http_call.dart';
import 'package:flutter_sdk_base/src/transport/sdk_http_request.dart';
import 'package:flutter_sdk_base/src/transport/sdk_http_response.dart';
import 'package:flutter_sdk_base/src/transport/sdk_http_transport.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

/// The default transport, backed by `package:http`.
///
/// This is the only file in `lib/` that references an HTTP library. Nothing it
/// exposes reaches a public signature, so the library can be replaced without
/// a breaking change.
///
/// Cancellation is best-effort. `package:http` cannot abort a single request;
/// [SdkHttpCall.cancel] therefore stops the SDK waiting and discards the
/// result while the socket may run to completion. The alternative — one client
/// per request — was rejected because it costs a TCP and TLS handshake on
/// every call.
@internal
final class PackageHttpTransport implements SdkHttpTransport {
  /// Creates a transport, optionally over a supplied client (tests only).
  PackageHttpTransport({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  SdkHttpCall open(SdkHttpRequest request) => _PackageHttpCall(_client, request);

  @override
  Future<void> close() async => _client.close();
}

final class _PackageHttpCall implements SdkHttpCall {
  _PackageHttpCall(this._client, this._request) {
    unawaited(_start());
  }

  final http.Client _client;
  final SdkHttpRequest _request;
  final Completer<SdkHttpResponse> _completer = Completer<SdkHttpResponse>();

  bool _cancelled = false;

  @override
  Future<SdkHttpResponse> get response => _completer.future;

  @override
  Future<void> cancel() async {
    if (_completer.isCompleted) {
      return;
    }
    _cancelled = true;
    _completer.completeError(const SdkCallCancelled());
  }

  Future<void> _start() async {
    try {
      final http.Request outgoing = http.Request(_request.method, _request.uri)..headers.addAll(_request.headers);
      final Uint8List? body = _request.body;
      if (body != null) {
        outgoing.bodyBytes = body;
      }

      final http.StreamedResponse streamed = await _client.send(outgoing);
      final Uint8List bytes = await streamed.stream.toBytes();

      if (_cancelled || _completer.isCompleted) {
        return;
      }
      _completer.complete(
        SdkHttpResponse(
          statusCode: streamed.statusCode,
          headers: streamed.headers,
          body: bytes,
        ),
      );
    } on Object catch (error, stackTrace) {
      if (!_completer.isCompleted) {
        _completer.completeError(error, stackTrace);
      }
    }
  }
}
