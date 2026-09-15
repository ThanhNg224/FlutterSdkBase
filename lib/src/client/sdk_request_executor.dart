import 'dart:async';
import 'dart:math';

import 'package:flutter_sdk_base/src/client/sdk_cancel_token.dart';
import 'package:flutter_sdk_base/src/client/sdk_config.dart';
import 'package:flutter_sdk_base/src/errors/sdk_error_codes.dart';
import 'package:flutter_sdk_base/src/errors/sdk_exception.dart';
import 'package:flutter_sdk_base/src/errors/sdk_failure.dart';
import 'package:flutter_sdk_base/src/logging/sdk_log_level.dart';
import 'package:flutter_sdk_base/src/logging/sdk_logger.dart';
import 'package:flutter_sdk_base/src/logging/sdk_redaction.dart';
import 'package:flutter_sdk_base/src/transport/sdk_http_call.dart';
import 'package:flutter_sdk_base/src/transport/sdk_http_request.dart';
import 'package:flutter_sdk_base/src/transport/sdk_http_response.dart';
import 'package:flutter_sdk_base/src/transport/sdk_http_transport.dart';
import 'package:flutter_sdk_base/src/version/sdk_version.dart';
import 'package:meta/meta.dart';

/// The response and correlation ID for one internal SDK operation.
@internal
final class SdkRequestResult {
  const SdkRequestResult({required this.response, required this.requestId});

  final SdkHttpResponse response;
  final String requestId;
}

/// Runs every SDK request through one place, so authentication, timeout,
/// cancellation, logging, and failure mapping cannot diverge per call site.
///
/// Internal: not exported from any public barrel.
@internal
final class SdkRequestExecutor {
  /// Creates an executor that owns [transport].
  SdkRequestExecutor({
    required SdkConfig config,
    required SdkHttpTransport transport,
    required SdkLogger logger,
  }) : this._(config, transport, logger);

  SdkRequestExecutor._(this._config, this._transport, this._logger);

  final SdkConfig _config;
  final SdkHttpTransport _transport;
  final SdkLogger _logger;
  final Set<_ActiveCall> _active = <_ActiveCall>{};

  bool _closed = false;

  /// Whether [close] has run.
  bool get isClosed => _closed;

  /// Headers every SDK request carries before request observability headers.
  Map<String, String> authHeaders() => <String, String>{
    'Accept': 'application/json',
    'X-Api-Key': _config.apiKey,
  };

  /// Sends [request], applying the configured timeout and optional cancellation.
  ///
  /// Throws [StateError] if the client was closed — that is host misuse, not a
  /// recoverable failure. Throws [SdkException] for everything else.
  Future<SdkRequestResult> send(
    SdkHttpRequest request, {
    SdkCancelToken? cancelToken,
  }) async {
    if (_closed) {
      throw StateError('This SdkClient has been closed. Create a new client to make further calls.');
    }

    final String requestId = _newRequestId();
    final SdkHttpRequest outgoingRequest = SdkHttpRequest(
      method: request.method,
      uri: request.uri,
      headers: <String, String>{
        ...request.headers,
        'X-Sdk-Version': sdkVersion,
        'X-Request-Id': requestId,
      },
      body: request.body,
    );

    _logger.log(SdkLogLevel.debug, '${request.method} ${request.uri.path}');

    if (cancelToken?.isCancelled ?? false) {
      throw SdkException(_cancelledFailure(requestId));
    }

    _ActiveCall? entry;
    void Function()? removeCancellationListener;
    try {
      final SdkHttpCall call = _transport.open(outgoingRequest);
      entry = _ActiveCall(call: call, requestId: requestId);
      _active.add(entry);
      final _ActiveCall activeEntry = entry;
      if (cancelToken != null) {
        removeCancellationListener = cancelToken.addListener(() {
          activeEntry.cancelCode = SdkErrorCodes.cancelled;
          _cancelCallBestEffort(activeEntry);
        });
      }

      final SdkHttpResponse response = await activeEntry.call.response.timeout(
        _config.requestTimeout,
        onTimeout: () {
          activeEntry.cancelCode = SdkErrorCodes.timeout;
          _cancelCallBestEffort(activeEntry);
          throw TimeoutException('SDK request timed out', _config.requestTimeout);
        },
      );

      if (response.statusCode == 401 || response.statusCode == 403) {
        _logger.log(
          SdkLogLevel.warn,
          'auth rejected (HTTP ${response.statusCode}) for apiKey=${SdkRedaction.secret(_config.apiKey)}',
        );
      }

      return SdkRequestResult(response: response, requestId: requestId);
    } on TimeoutException {
      final SdkFailure failure = SdkFailure(
        code: SdkErrorCodes.timeout,
        message: 'The request exceeded the configured timeout.',
        isRetryable: true,
        requestId: requestId,
      );
      _logger.log(SdkLogLevel.error, 'request failed with code ${failure.code}');
      throw SdkException(failure);
    } on Object catch (error, stackTrace) {
      final SdkFailure failure = entry?.cancelCode == SdkErrorCodes.cancelled
          ? _cancelledFailure(requestId)
          : SdkFailure(
              code: SdkErrorCodes.transport,
              message: 'The request did not reach the API.',
              isRetryable: true,
              requestId: requestId,
              cause: error,
            );
      _logger.log(
        SdkLogLevel.error,
        'request failed with code ${failure.code}',
        stackTrace: stackTrace,
      );
      throw SdkException(failure);
    } finally {
      removeCancellationListener?.call();
      if (entry != null) {
        _active.remove(entry);
      }
    }
  }

  /// Cancels every in-flight call, releases the transport, and blocks further
  /// sends. Safe to call more than once.
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;

    final List<_ActiveCall> pending = List<_ActiveCall>.of(_active);
    for (final _ActiveCall entry in pending) {
      entry.cancelCode = SdkErrorCodes.cancelled;
    }
    try {
      await Future.wait<void>(pending.map((_ActiveCall entry) => entry.call.cancel()));
    } finally {
      // A transport that fails while cancelling must still be released, or the
      // host leaks it. The cancellation error is rethrown rather than swallowed.
      await _transport.close();
    }
  }
}

SdkFailure _cancelledFailure(String requestId) => SdkFailure(
  code: SdkErrorCodes.cancelled,
  message: 'The request was cancelled.',
  isRetryable: false,
  requestId: requestId,
);

void _cancelCallBestEffort(_ActiveCall entry) {
  try {
    // A host transport is allowed to throw synchronously before returning its
    // cancellation future. Cancellation remains best-effort, so that failure
    // must not prevent a shared token from notifying its other operations.
    unawaited(entry.call.cancel().catchError((Object _) {}));
  } catch (_) {
    // The operation's response future still determines its final outcome.
  }
}

String _newRequestId() {
  final Random random = Random.secure();
  final StringBuffer id = StringBuffer();
  for (var index = 0; index < 16; index++) {
    id.write(random.nextInt(256).toRadixString(16).padLeft(2, '0'));
  }
  return id.toString();
}

final class _ActiveCall {
  _ActiveCall({required this.call, required this.requestId});

  final SdkHttpCall call;
  final String requestId;

  String? cancelCode;
}
