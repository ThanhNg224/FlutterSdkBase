import 'package:dio/dio.dart';
import 'package:flutter_sdk_base/core/logging/logging.dart';

const _log = AppLogger('HTTP');

/// Logging interceptor for Dio HTTP requests.
/// Logs request/response metadata without logging request/response bodies to protect PII.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _log.debug('➡️ ${options.method} request', data: {'url': _endpoint(options.uri)});
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    _log.debug(
      '⬅️ response ${response.statusCode}',
      data: {'url': _endpoint(response.requestOptions.uri)},
    );
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log.error(
      '✖ request failed',
      data: {
        'type': Redacted.unredacted(err.type.name, because: 'DioExceptionType enum name'),
        'url': _endpoint(err.requestOptions.uri),
        'reason': Redacted.unredacted(
          err.message ?? 'no message',
          because: 'Dio summary message',
        ),
      },
    );
    super.onError(err, handler);
  }

  static Redacted _endpoint(Uri uri) => Redacted.unredacted(uri.toString(), because: 'endpoint path without payload');
}
