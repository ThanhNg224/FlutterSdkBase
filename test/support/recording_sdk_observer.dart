import 'package:flutter_sdk_base/flutter_sdk_base.dart';

/// Captures structured operation events for assertions.
final class RecordingSdkObserver implements SdkObserver {
  final List<SdkOperationEvent> events = <SdkOperationEvent>[];

  @override
  void onOperation(SdkOperationEvent event) {
    events.add(event);
  }
}

final class ThrowingSdkObserver implements SdkObserver {
  @override
  void onOperation(SdkOperationEvent event) {
    throw StateError('observer failed');
  }
}
