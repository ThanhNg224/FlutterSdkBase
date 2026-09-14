import 'package:flutter_sdk_base/src/errors/sdk_error_codes.dart';
import 'package:flutter_sdk_base/src/errors/sdk_failure.dart';

/// Maps a non-success HTTP status onto the single failure table defined by the
/// design spec, so no call site decides `code` or `isRetryable` on its own.
SdkFailure failureForStatus(int statusCode, {String? message}) {
  final (String code, bool isRetryable, String defaultMessage) = switch (statusCode) {
    401 || 403 => (
      SdkErrorCodes.unauthorized,
      false,
      'The API rejected the supplied credential.',
    ),
    429 => (
      SdkErrorCodes.rateLimited,
      true,
      'The API applied rate limiting.',
    ),
    >= 400 && < 500 => (
      SdkErrorCodes.client,
      false,
      'The API rejected the request as invalid.',
    ),
    _ => (
      SdkErrorCodes.server,
      true,
      'The API failed to serve the request.',
    ),
  };

  return SdkFailure(
    code: code,
    message: message ?? defaultMessage,
    isRetryable: isRetryable,
    statusCode: statusCode,
  );
}
