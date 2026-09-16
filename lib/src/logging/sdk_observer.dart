import 'package:flutter_sdk_base/src/logging/sdk_operation_event.dart';

/// Receives one safe terminal event for each public SDK operation.
abstract interface class SdkObserver {
  /// Handles [event]. Exceptions thrown by an observer are ignored by the SDK.
  void onOperation(SdkOperationEvent event);
}
