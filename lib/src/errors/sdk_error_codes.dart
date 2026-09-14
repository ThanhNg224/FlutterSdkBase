/// Stable identifiers carried by [SdkFailure.code].
///
/// Adding a code is a non-breaking change. Changing or removing one is
/// breaking, because hosts branch on these values.
abstract final class SdkErrorCodes {
  /// The operation was cancelled because its client was closed.
  static const String cancelled = 'cancelled';

  /// The operation exceeded `SdkConfig.requestTimeout`.
  static const String timeout = 'timeout';

  /// The request never produced an HTTP response.
  static const String transport = 'transport';

  /// The API rejected the credential (HTTP 401 or 403).
  static const String unauthorized = 'unauthorized';

  /// The request was rejected as invalid (HTTP 4xx other than 401/403/429).
  static const String client = 'client';

  /// The API applied rate limiting (HTTP 429).
  static const String rateLimited = 'rate_limited';

  /// The API failed to serve the request (HTTP 5xx).
  static const String server = 'server';

  /// A successful response carried a body the SDK could not parse.
  static const String invalidResponse = 'invalid_response';
}
