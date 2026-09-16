import 'package:flutter/foundation.dart';
import 'package:flutter_sdk_base_example/core/error/app_failure.dart';
import 'package:flutter_sdk_base_example/core/observability/app_observability.dart';

/// Debug-only sink that prints allow-listed metadata without raw errors.
final class DebugAppObservability implements AppObservability {
  /// Creates a debug sink. [writer] is injectable for tests.
  DebugAppObservability([void Function(String message)? writer]) : _writer = writer ?? debugPrint;

  final void Function(String message) _writer;

  @override
  void recordSdkOperation(AppSdkOperation operation) {
    _writer(
      'sdk.operation name=${operation.operation} requestId=${operation.requestId} '
      'sdkVersion=${operation.sdkVersion} outcome=${operation.outcome.name} '
      'elapsedMs=${operation.elapsed.inMilliseconds} status=${operation.statusCode} '
      'failureCode=${operation.failureCode} retryable=${operation.isRetryable}',
    );
  }

  @override
  void reportFailure(AppFailure failure, AppFailureReportKind kind) {
    _writer(
      'app.failure kind=${kind.name} code=${failure.code} requestId=${failure.requestId} '
      'status=${failure.statusCode} retryable=${failure.isRetryable}',
    );
  }

  @override
  void reportUnhandled(AppUnhandledError error) {
    _writer(
      'app.unhandled source=${error.source.name} errorType=${error.errorType} '
      'stackLineCount=${error.stackLineCount}',
    );
  }
}
