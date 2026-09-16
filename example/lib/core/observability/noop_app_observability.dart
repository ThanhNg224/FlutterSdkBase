import 'package:flutter_sdk_base_example/core/observability/app_observability.dart';
import 'package:flutter_sdk_base_example/core/error/app_failure.dart';

/// Silent release-safe default for the reference host.
final class NoopAppObservability implements AppObservability {
  /// Creates a silent observability sink.
  const NoopAppObservability();

  @override
  void recordSdkOperation(AppSdkOperation operation) {}

  @override
  void reportFailure(AppFailure failure, AppFailureReportKind kind) {}

  @override
  void reportUnhandled(AppUnhandledError error) {}
}
