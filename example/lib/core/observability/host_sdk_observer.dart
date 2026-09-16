import 'package:flutter_sdk_base/flutter_sdk_base.dart';
import 'package:flutter_sdk_base_example/core/observability/app_observability.dart';

/// Adapts the SDK's safe observer contract to host observability.
final class HostSdkObserver implements SdkObserver {
  /// Creates an observer backed by [observability].
  const HostSdkObserver(this.observability);

  /// The host-owned telemetry adapter.
  final AppObservability observability;

  @override
  void onOperation(SdkOperationEvent event) {
    observability.recordSdkOperation(AppSdkOperation.fromSdkEvent(event));
  }
}
