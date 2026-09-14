import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_sdk_base/core/config/app_config.dart';
import 'package:flutter_sdk_base/core/logging/logging.dart';

const _log = AppLogger('HTTP.Auth');

/// Adds runtime credentials to outgoing requests and clears overrides on 401.
class AuthInterceptor extends Interceptor {
  final AppConfig Function() readConfig;
  final Future<void> Function() clearCredentialOverrides;
  final Uri baseUri;

  AuthInterceptor({
    required this.readConfig,
    required this.clearCredentialOverrides,
    required this.baseUri,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final config = readConfig();
    if (config.appToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer ${config.appToken}';
    }
    if (config.clientKey.isNotEmpty) {
      options.headers['X-Client-Key'] = config.clientKey;
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode != 401 || !_isCurrentApiRequest(err.requestOptions.uri)) {
      handler.next(err);
      return;
    }

    unawaited(_clearCredentialsThenForward(err, handler));
  }

  bool _isCurrentApiRequest(Uri requestUri) {
    if (requestUri.scheme != baseUri.scheme || requestUri.host != baseUri.host || requestUri.port != baseUri.port) {
      return false;
    }

    final basePath = baseUri.path.endsWith('/') ? baseUri.path.substring(0, baseUri.path.length - 1) : baseUri.path;
    return basePath.isEmpty ||
        basePath == '/' ||
        requestUri.path == basePath ||
        requestUri.path.startsWith('$basePath/');
  }

  Future<void> _clearCredentialsThenForward(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    try {
      await clearCredentialOverrides();
    } catch (exception, stackTrace) {
      _log.error(
        'failed to clear credential overrides after unauthorized response',
        error: exception,
        stackTrace: stackTrace,
        data: {'errorType': Redacted.type(exception)},
      );
    } finally {
      handler.next(error);
    }
  }
}
