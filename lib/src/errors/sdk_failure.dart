/// A structured description of why an SDK operation did not succeed.
///
/// Hosts branch on [code] and map it to their own user-facing copy. [message]
/// is English diagnostic text for developers and is never localized.
final class SdkFailure {
  /// Creates a failure.
  const SdkFailure({
    required this.code,
    required this.message,
    required this.isRetryable,
    this.statusCode,
    required this.requestId,
    this.cause,
  }) : assert(requestId != '', 'requestId must not be empty');

  /// A stable identifier drawn from `SdkErrorCodes`.
  final String code;

  /// English diagnostic text for developers. Not for end-user UI.
  final String message;

  /// Whether retrying the same operation could plausibly succeed.
  ///
  /// Advice only — the SDK never retries on its own.
  final bool isRetryable;

  /// The HTTP status that produced this failure, when there was one.
  final int? statusCode;

  /// The non-empty correlation ID assigned to the request.
  final String requestId;

  /// The underlying error, for diagnostics only.
  ///
  /// Its type and contents carry no compatibility guarantee. Never branch on
  /// it, and never render it to an end user.
  final Object? cause;

  @override
  bool operator ==(Object other) =>
      other is SdkFailure &&
      other.code == code &&
      other.message == message &&
      other.isRetryable == isRetryable &&
      other.statusCode == statusCode &&
      other.requestId == requestId;

  @override
  int get hashCode => Object.hash(code, message, isRetryable, statusCode, requestId);

  @override
  String toString() => 'SdkFailure($code, status: $statusCode): $message';
}
