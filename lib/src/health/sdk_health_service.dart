import 'dart:convert';

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
  Future<SdkHealth> check() async {
    final SdkHttpResponse response = await _executor.send(
      SdkHttpRequest(
        method: 'GET',
        uri: SdkUri.join(_config.baseUri, 'health'),
        headers: _executor.authHeaders(),
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SdkException(failureForStatus(response.statusCode));
    }

    final Object? decoded = _decode(response.bodyAsString);
    if (decoded is! Map<String, Object?>) {
      throw const SdkException(
        SdkFailure(
          code: SdkErrorCodes.invalidResponse,
          message: 'The health endpoint did not return a JSON object.',
          isRetryable: false,
        ),
      );
    }

    final Object? status = decoded['status'];
    if (status is! String) {
      throw const SdkException(
        SdkFailure(
          code: SdkErrorCodes.invalidResponse,
          message: 'The health response did not contain a string "status" field.',
          isRetryable: false,
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
