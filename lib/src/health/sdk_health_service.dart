import 'dart:convert';

import 'package:flutter_sdk_base/src/client/sdk_cancel_token.dart';
import 'package:flutter_sdk_base/src/client/sdk_config.dart';
import 'package:flutter_sdk_base/src/client/sdk_request_executor.dart';
import 'package:flutter_sdk_base/src/errors/sdk_error_codes.dart';
import 'package:flutter_sdk_base/src/errors/sdk_exception.dart';
import 'package:flutter_sdk_base/src/errors/sdk_failure.dart';
import 'package:flutter_sdk_base/src/errors/sdk_status_mapping.dart';
import 'package:flutter_sdk_base/src/health/sdk_health.dart';
import 'package:flutter_sdk_base/src/transport/sdk_http_request.dart';
import 'package:flutter_sdk_base/src/transport/sdk_http_response.dart';
import 'package:flutter_sdk_base/src/util/sdk_uri.dart';
import 'package:meta/meta.dart';

/// Supplies the current time. Internal seam so tests can freeze the clock.
typedef SdkClock = DateTime Function();

/// The reference capability: a single `GET /health` call.
final class SdkHealthService {
  /// Creates the service.
  @internal
  SdkHealthService({
    required SdkRequestExecutor executor,
    required SdkConfig config,
    required SdkClock clock,
  }) : this._(executor, config, clock);

  SdkHealthService._(this._executor, this._config, this._clock);

  final SdkRequestExecutor _executor;
  final SdkConfig _config;
  final SdkClock _clock;

  /// Asks the API whether it is healthy.
  ///
  /// [cancelToken] provides best-effort per-operation cancellation. It stops
  /// the SDK waiting for a response but cannot prove the server did not
  /// receive or process the request. Throws [SdkException] for runtime
  /// failures.
  Future<SdkHealth> check({SdkCancelToken? cancelToken}) async {
    final SdkRequestResult result = await _executor.send(
      SdkHttpRequest(
        method: 'GET',
        uri: SdkUri.join(_config.baseUri, 'health'),
        headers: _executor.authHeaders(),
      ),
      cancelToken: cancelToken,
    );
    final SdkHttpResponse response = result.response;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SdkException(failureForStatus(response.statusCode, requestId: result.requestId));
    }

    final Object? decoded = _decode(response.bodyAsString);
    if (decoded is! Map<String, Object?>) {
      throw SdkException(
        SdkFailure(
          code: SdkErrorCodes.invalidResponse,
          message: 'The health endpoint did not return a JSON object.',
          isRetryable: false,
          requestId: result.requestId,
        ),
      );
    }

    final Object? status = decoded['status'];
    if (status is! String) {
      throw SdkException(
        SdkFailure(
          code: SdkErrorCodes.invalidResponse,
          message: 'The health response did not contain a string "status" field.',
          isRetryable: false,
          requestId: result.requestId,
        ),
      );
    }

    return SdkHealth(
      isHealthy: status == 'ok',
      status: status,
      checkedAt: _clock(),
    );
  }

  static Object? _decode(String body) {
    try {
      return jsonDecode(body);
    } on FormatException {
      return null;
    }
  }
}
