/// Whether an SDK operation completed successfully or failed.
enum SdkOperationOutcome {
  /// The operation returned its decoded value.
  succeeded,

  /// The operation threw an `SdkException`.
  failed,
}

/// A safe, terminal observation of one public SDK operation.
///
/// Events intentionally contain no request URI, headers, body, raw exception,
/// or stack trace. On success [failureCode] and [isRetryable] are null. On
/// failure both are populated from the thrown `SdkFailure`.
final class SdkOperationEvent {
  /// Creates an operation event.
  const SdkOperationEvent({
    required this.operation,
    required this.requestId,
    required this.sdkVersion,
    required this.outcome,
    required this.elapsed,
    this.statusCode,
    this.failureCode,
    this.isRetryable,
  });

  /// Static operation identifier, such as `health.check`.
  final String operation;

  /// The per-request correlation identifier.
  final String requestId;

  /// The package version used for the request.
  final String sdkVersion;

  /// Whether the operation succeeded or failed.
  final SdkOperationOutcome outcome;

  /// Time spent executing the operation.
  final Duration elapsed;

  /// HTTP response status, when a response existed.
  final int? statusCode;

  /// Stable failure code for a failed operation; null on success.
  final String? failureCode;

  /// Retry advice for a failed operation; null on success.
  final bool? isRetryable;
}
