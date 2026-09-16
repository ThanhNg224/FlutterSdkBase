import 'dart:async';
import 'dart:math';

import 'package:flutter_sdk_base/src/client/sdk_cancel_token.dart';
import 'package:flutter_sdk_base/src/client/sdk_config.dart';
import 'package:flutter_sdk_base/src/errors/sdk_error_codes.dart';
import 'package:flutter_sdk_base/src/errors/sdk_exception.dart';
import 'package:flutter_sdk_base/src/errors/sdk_failure.dart';
import 'package:flutter_sdk_base/src/errors/sdk_status_mapping.dart';
import 'package:flutter_sdk_base/src/logging/sdk_observer.dart';
import 'package:flutter_sdk_base/src/logging/sdk_operation_event.dart';
import 'package:flutter_sdk_base/src/transport/sdk_http_call.dart';
import 'package:flutter_sdk_base/src/transport/sdk_http_request.dart';
import 'package:flutter_sdk_base/src/transport/sdk_http_response.dart';
import 'package:flutter_sdk_base/src/transport/sdk_http_transport.dart';
import 'package:flutter_sdk_base/src/version/sdk_version.dart';
import 'package:meta/meta.dart';

/// Runs every SDK operation through one place, including its terminal event.
///
/// Internal: not exported from any public barrel.
@internal
final class SdkRequestExecutor {
  /// Creates an executor that owns [transport].
  SdkRequestExecutor({
    required SdkConfig config,
    required SdkHttpTransport transport,
    required SdkObserver observer,
  }) : this._(config, transport, observer);

  SdkRequestExecutor._(this._config, this._transport, this._observer);

  final SdkConfig _config;
  final SdkHttpTransport _transport;
  final SdkObserver _observer;
  final Set<_ActiveCall> _active = <_ActiveCall>{};

  bool _closed = false;

  /// Whether [close] has run.
  bool get isClosed => _closed;

  /// Headers every SDK request carries before observability headers.
  Map<String, String> authHeaders() => <String, String>{
    'Accept': 'application/json',
    'X-Api-Key': _config.apiKey,
  };

  /// Executes one public SDK operation and emits exactly one terminal event.
  ///
  /// The [decode] callback is called only for a 2xx response. Non-2xx
  /// responses are mapped by the central status table. Decoder exceptions are
  /// mapped to `invalid_response` while preserving the response status.
  Future<T> execute<T>({
    required String operation,
    required SdkHttpRequest request,
    SdkCancelToken? cancelToken,
    required FutureOr<T> Function(SdkHttpResponse response, String requestId) decode,
  }) async {
    if (_closed) {
      throw StateError('This SdkClient has been closed. Create a new client to make further calls.');
    }

    final Stopwatch stopwatch = Stopwatch()..start();
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

    _ActiveCall? entry;
    void Function()? removeCancellationListener;
    SdkFailure? terminalFailure;
    SdkOperationOutcome? terminalOutcome;
    int? responseStatusCode;

    try {
      if (cancelToken?.isCancelled ?? false) {
        terminalFailure = _cancelledFailure(requestId);
        throw SdkException(terminalFailure);
      }

      final SdkHttpCall call = _transport.open(outgoingRequest);
      entry = _ActiveCall(call: call);
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
      responseStatusCode = response.statusCode;

      if (activeEntry.cancelCode != null) {
        terminalFailure = _failureForCancellation(
          activeEntry.cancelCode!,
          requestId,
          statusCode: responseStatusCode,
        );
        throw SdkException(terminalFailure);
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        terminalFailure = failureForStatus(response.statusCode, requestId: requestId);
        throw SdkException(terminalFailure);
      }

      try {
        final T result = await decode(response, requestId);
        terminalOutcome = SdkOperationOutcome.succeeded;
        return result;
      } on SdkException {
        rethrow;
      } on Object catch (error) {
        terminalFailure = SdkFailure(
          code: SdkErrorCodes.invalidResponse,
          message: 'The response could not be decoded.',
          isRetryable: false,
          statusCode: responseStatusCode,
          requestId: requestId,
          cause: error,
        );
        throw SdkException(terminalFailure);
      }
    } on SdkException catch (error) {
      terminalFailure ??= error.failure;
      rethrow;
    } on TimeoutException {
      terminalFailure = SdkFailure(
        code: SdkErrorCodes.timeout,
        message: 'The request exceeded the configured timeout.',
        isRetryable: true,
        statusCode: responseStatusCode,
        requestId: requestId,
      );
      throw SdkException(terminalFailure);
    } on Object catch (error) {
      terminalFailure = entry?.cancelCode == SdkErrorCodes.cancelled
          ? _cancelledFailure(requestId, statusCode: responseStatusCode)
          : entry?.cancelCode == SdkErrorCodes.timeout
          ? SdkFailure(
              code: SdkErrorCodes.timeout,
              message: 'The request exceeded the configured timeout.',
              isRetryable: true,
              statusCode: responseStatusCode,
              requestId: requestId,
            )
          : SdkFailure(
              code: SdkErrorCodes.transport,
              message: 'The request did not reach the API.',
              isRetryable: true,
              statusCode: responseStatusCode,
              requestId: requestId,
              cause: error,
            );
      throw SdkException(terminalFailure);
    } finally {
      stopwatch.stop();
      removeCancellationListener?.call();
      if (entry != null) {
        _active.remove(entry);
      }
      final SdkFailure? failure = terminalFailure;
      final SdkOperationOutcome? outcome = terminalOutcome ?? (failure == null ? null : SdkOperationOutcome.failed);
      if (outcome != null) {
        _observe(
          SdkOperationEvent(
            operation: operation,
            requestId: requestId,
            sdkVersion: sdkVersion,
            outcome: outcome,
            elapsed: stopwatch.elapsed,
            statusCode: responseStatusCode,
            failureCode: failure?.code,
            isRetryable: failure?.isRetryable,
          ),
        );
      }
    }
  }

  /// Cancels every in-flight call, releases the transport, and blocks sends.
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
      await _transport.close();
    }
  }

  void _observe(SdkOperationEvent event) {
    try {
      _observer.onOperation(event);
    } catch (_) {
      // Observability must never alter the public operation result.
    }
  }
}

SdkFailure _cancelledFailure(String requestId, {int? statusCode}) => SdkFailure(
  code: SdkErrorCodes.cancelled,
  message: 'The request was cancelled.',
  isRetryable: false,
  statusCode: statusCode,
  requestId: requestId,
);

SdkFailure _failureForCancellation(String code, String requestId, {int? statusCode}) => code == SdkErrorCodes.timeout
    ? SdkFailure(
        code: SdkErrorCodes.timeout,
        message: 'The request exceeded the configured timeout.',
        isRetryable: true,
        statusCode: statusCode,
        requestId: requestId,
      )
    : _cancelledFailure(requestId, statusCode: statusCode);

void _cancelCallBestEffort(_ActiveCall entry) {
  try {
    unawaited(entry.call.cancel().catchError((Object _) {}));
  } catch (_) {
    // A synchronous cancellation failure must not stop token listeners.
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
  _ActiveCall({required this.call});

  final SdkHttpCall call;
  String? cancelCode;
}
