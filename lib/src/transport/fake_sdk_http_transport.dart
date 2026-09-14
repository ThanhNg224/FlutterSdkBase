import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_sdk_base/src/transport/sdk_http_call.dart';
import 'package:flutter_sdk_base/src/transport/sdk_http_request.dart';
import 'package:flutter_sdk_base/src/transport/sdk_http_response.dart';
import 'package:flutter_sdk_base/src/transport/sdk_http_transport.dart';

/// A deterministic transport for host tests and for the bundled example.
///
/// Queue an outcome per expected call, then assert against [requests]. This is
/// a supported testing helper, never a production transport.
final class FakeSdkHttpTransport implements SdkHttpTransport {
  /// Creates an empty fake. Queue outcomes before use.
  FakeSdkHttpTransport();

  /// Every request the SDK issued, in order.
  final List<SdkHttpRequest> requests = <SdkHttpRequest>[];

  /// Whether the owning client closed this transport.
  bool isClosed = false;

  final List<FutureOr<SdkHttpResponse> Function(SdkHttpRequest request)> _outcomes =
      <FutureOr<SdkHttpResponse> Function(SdkHttpRequest request)>[];
  final List<_FakeSdkHttpCall> _calls = <_FakeSdkHttpCall>[];

  /// Whether any call was cancelled.
  bool get hasPendingCancellation => _calls.any((_FakeSdkHttpCall call) => call.wasCancelled);

  /// Queues a JSON response.
  void enqueueJson(String body, {int statusCode = 200}) {
    _outcomes.add(
      (SdkHttpRequest _) => SdkHttpResponse(
        statusCode: statusCode,
        headers: const <String, String>{'content-type': 'application/json'},
        body: Uint8List.fromList(utf8.encode(body)),
      ),
    );
  }

  /// Queues a transport-level failure.
  void enqueueError(Object error) {
    _outcomes.add((SdkHttpRequest _) => Future<SdkHttpResponse>.error(error));
  }

  /// Queues a call that never completes, so a test can exercise timeout or
  /// cancellation.
  void enqueueNeverCompletes() {
    _outcomes.add((SdkHttpRequest _) => Completer<SdkHttpResponse>().future);
  }

  @override
  SdkHttpCall open(SdkHttpRequest request) {
    requests.add(request);
    if (_outcomes.isEmpty) {
      throw StateError(
        'FakeSdkHttpTransport received ${requests.length} request(s) but no outcome was queued.',
      );
    }
    final call = _FakeSdkHttpCall(_outcomes.removeAt(0)(request));
    _calls.add(call);
    return call;
  }

  @override
  Future<void> close() async {
    isClosed = true;
  }
}

final class _FakeSdkHttpCall implements SdkHttpCall {
  _FakeSdkHttpCall(FutureOr<SdkHttpResponse> outcome) {
    Future<SdkHttpResponse>.value(outcome).then(
      (SdkHttpResponse value) {
        if (!_completer.isCompleted) {
          _completer.complete(value);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!_completer.isCompleted) {
          _completer.completeError(error, stackTrace);
        }
      },
    );
  }

  final Completer<SdkHttpResponse> _completer = Completer<SdkHttpResponse>();

  bool wasCancelled = false;

  @override
  Future<SdkHttpResponse> get response => _completer.future;

  @override
  Future<void> cancel() async {
    wasCancelled = true;
    if (!_completer.isCompleted) {
      _completer.completeError(const SdkCallCancelled());
    }
  }
}
