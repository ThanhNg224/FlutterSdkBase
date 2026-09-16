import 'package:flutter_sdk_base/flutter_sdk_base.dart';
import 'package:flutter_sdk_base_example/core/error/app_failure.dart';

/// The source category for an unhandled host error.
enum AppUnhandledSource {
  /// An error reported through Flutter's framework handler.
  flutter,

  /// An error reported through the platform dispatcher handler.
  platform,
}

/// The host reporting disposition for an SDK failure.
enum AppFailureReportKind {
  /// A low-severity operational breadcrumb or warning.
  operational,

  /// A non-fatal error suitable for an error-reporting backend.
  nonFatal,
}

/// Safe, host-owned operation metadata derived from [SdkOperationEvent].
final class AppSdkOperation {
  /// Creates a safe operation observation.
  const AppSdkOperation({
    required this.operation,
    required this.requestId,
    required this.sdkVersion,
    required this.outcome,
    required this.elapsed,
    this.statusCode,
    this.failureCode,
    this.isRetryable,
  });

  /// Creates host metadata from the SDK's already allow-listed event.
  factory AppSdkOperation.fromSdkEvent(SdkOperationEvent event) => AppSdkOperation(
    operation: event.operation,
    requestId: event.requestId,
    sdkVersion: event.sdkVersion,
    outcome: event.outcome,
    elapsed: event.elapsed,
    statusCode: event.statusCode,
    failureCode: event.failureCode,
    isRetryable: event.isRetryable,
  );

  /// Static SDK-owned operation identifier.
  final String operation;

  /// Request correlation ID.
  final String requestId;

  /// SDK version that produced the operation.
  final String sdkVersion;

  /// Operation outcome.
  final SdkOperationOutcome outcome;

  /// Elapsed operation duration.
  final Duration elapsed;

  /// Response status, when a response existed.
  final int? statusCode;

  /// Stable failure code on failed operations.
  final String? failureCode;

  /// Retryability on failed operations.
  final bool? isRetryable;
}

/// Safe metadata for one unhandled framework or platform error.
final class AppUnhandledError {
  /// Creates an unhandled-error observation from sanitized metadata.
  const AppUnhandledError({
    required this.source,
    required this.errorType,
    required this.stackLineCount,
  });

  /// Where the error was observed.
  final AppUnhandledSource source;

  /// Runtime type name only; the error object and message are excluded.
  final String errorType;

  /// Number of non-empty stack lines, without exposing stack content.
  final int stackLineCount;
}

/// Host-owned adapter boundary for SDK and app error reporting.
abstract interface class AppErrorReporter {
  /// Reports allow-listed SDK failure metadata at [kind]'s severity.
  void reportFailure(AppFailure failure, AppFailureReportKind kind);

  /// Reports sanitized metadata for an unhandled host error.
  void reportUnhandled(AppUnhandledError error);
}

/// Host observability sink used by both the SDK observer and error reporter.
abstract interface class AppObservability implements AppErrorReporter {
  /// Records one already-safe terminal SDK operation observation.
  void recordSdkOperation(AppSdkOperation operation);
}

/// Applies the fixed reporting policy to an SDK-derived host failure.
AppFailureReportKind? appFailureReportKind(AppFailure failure) => switch (failure.code) {
  SdkErrorCodes.cancelled => null,
  SdkErrorCodes.timeout || SdkErrorCodes.transport || SdkErrorCodes.rateLimited => AppFailureReportKind.operational,
  _ => AppFailureReportKind.nonFatal,
};

/// Reports [failure] according to the fixed host policy.
void reportAppFailure(AppErrorReporter reporter, AppFailure failure) {
  final AppFailureReportKind? kind = appFailureReportKind(failure);
  if (kind == null) {
    return;
  }
  reporter.reportFailure(failure, kind);
}
