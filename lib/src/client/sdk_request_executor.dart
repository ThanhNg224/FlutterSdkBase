import 'dart:async';

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
import 'package:meta/meta.dart';

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

  /// Headers every SDK request carries.
  Map<String, String> authHeaders() => <String, String>{
    'Accept': 'application/json',
    'X-Api-Key': _config.apiKey,
  };

  /// Sends [request], applying the configured timeout.
  ///
  /// Throws [StateError] if the client was closed — that is host misuse, not a
  /// recoverable failure. Throws [SdkException] for everything else.
  Future<SdkHttpResponse> send(SdkHttpRequest request) async {
    if (_closed) {
      throw StateError('This SdkClient has been closed. Create a new client to make further calls.');
    }

    _logger.log(SdkLogLevel.debug, '${request.method} ${request.uri.path}');

    final _ActiveCall entry = _ActiveCall(_transport.open(request));
    _active.add(entry);

    try {
      final SdkHttpResponse response = await entry.call.response.timeout(
        _config.requestTimeout,
        onTimeout: () {
          entry.cancelCode = SdkErrorCodes.timeout;
          unawaited(entry.call.cancel());
          throw TimeoutException('SDK request timed out', _config.requestTimeout);
        },
      );

      if (response.statusCode == 401 || response.statusCode == 403) {
        _logger.log(
          SdkLogLevel.warn,
          'auth rejected (HTTP ${response.statusCode}) for apiKey=${SdkRedaction.secret(_config.apiKey)}',
        );
      }

      return response;
    } on TimeoutException {
      const SdkFailure failure = SdkFailure(
        code: SdkErrorCodes.timeout,
        message: 'The request exceeded the configured timeout.',
        isRetryable: true,
      );
      _logger.log(SdkLogLevel.error, 'request failed with code ${failure.code}');
      throw const SdkException(failure);
    } on Object catch (error, stackTrace) {
      final SdkFailure failure = entry.cancelCode == SdkErrorCodes.cancelled
          ? const SdkFailure(
              code: SdkErrorCodes.cancelled,
              message: 'The request was cancelled because the client was closed.',
              isRetryable: false,
            )
          : SdkFailure(
              code: SdkErrorCodes.transport,
              message: 'The request did not reach the API.',
              isRetryable: true,
              cause: error,
            );
      _logger.log(
        SdkLogLevel.error,
        'request failed with code ${failure.code}',
        stackTrace: stackTrace,
      );
      throw SdkException(failure);
    } finally {
      _active.remove(entry);
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
    await Future.wait<void>(pending.map((_ActiveCall entry) => entry.call.cancel()));
    await _transport.close();
  }
}

final class _ActiveCall {
  _ActiveCall(this.call);

  final SdkHttpCall call;

  String? cancelCode;
}
