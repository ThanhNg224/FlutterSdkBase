import 'package:flutter_sdk_base/flutter_sdk_base.dart';
import 'package:flutter_sdk_base/flutter_sdk_base_testing.dart';
import 'package:flutter_sdk_base_example/core/demo/demo_health_scenario.dart';

/// An offline host transport that adapts the SDK's deterministic fake.
final class DemoSdkHttpTransport implements SdkHttpTransport {
  /// Creates a transport whose next response is selected by [scenarioReader].
  DemoSdkHttpTransport({required DemoHealthScenario Function() scenarioReader}) : this._(scenarioReader);

  DemoSdkHttpTransport._(this._scenarioReader);

  final DemoHealthScenario Function() _scenarioReader;
  final FakeSdkHttpTransport _delegate = FakeSdkHttpTransport();

  /// Whether the SDK client has closed this transport.
  bool get isClosed => _delegate.isClosed;

  @override
  SdkHttpCall open(SdkHttpRequest request) {
    switch (_scenarioReader()) {
      case DemoHealthScenario.healthy:
        _delegate.enqueueJson('{"status":"ok"}');
      case DemoHealthScenario.unauthorized:
        _delegate.enqueueJson('{}', statusCode: 401);
    }
    return _delegate.open(request);
  }

  @override
  Future<void> close() => _delegate.close();
}
