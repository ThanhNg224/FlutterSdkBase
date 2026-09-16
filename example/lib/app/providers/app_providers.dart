import 'package:flutter/foundation.dart';
import 'package:flutter_sdk_base/flutter_sdk_base.dart';
import 'package:flutter_sdk_base_example/core/config/app_config.dart';
import 'package:flutter_sdk_base_example/core/demo/demo_health_scenario.dart';
import 'package:flutter_sdk_base_example/core/demo/demo_sdk_http_transport.dart';
import 'package:flutter_sdk_base_example/core/observability/app_observability.dart';
import 'package:flutter_sdk_base_example/core/observability/debug_app_observability.dart';
import 'package:flutter_sdk_base_example/core/observability/host_sdk_observer.dart';
import 'package:flutter_sdk_base_example/core/observability/noop_app_observability.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_providers.g.dart';

/// Provides the immutable configuration for the reference host.
@Riverpod(keepAlive: true)
AppConfig appConfig(Ref ref) => const AppConfig(
  environmentName: 'Demo',
  apiBaseUrl: 'https://api.example.com',
  apiKey: 'demo-key',
  transportDescription: 'Offline deterministic fake transport',
);

/// Provides the response scenario used by the offline demo transport.
@Riverpod(keepAlive: true)
DemoHealthScenario demoHealthScenario(Ref ref) => DemoHealthScenario.healthy;

/// Provides the host-only adapter around the SDK's testing transport.
@Riverpod(keepAlive: true)
DemoSdkHttpTransport demoTransport(Ref ref) => DemoSdkHttpTransport(
  scenarioReader: () => ref.read(demoHealthScenarioProvider),
);

/// Provides the host observability sink. Release builds are silent by default.
@Riverpod(keepAlive: true)
AppObservability appObservability(Ref ref) => kDebugMode ? DebugAppObservability() : const NoopAppObservability();

/// Provides the adapter that passes safe SDK events to host observability.
@Riverpod(keepAlive: true)
SdkObserver sdkObserver(Ref ref) => HostSdkObserver(ref.watch(appObservabilityProvider));

/// Provides the reporter used by host repositories for mapped SDK failures.
@Riverpod(keepAlive: true)
AppErrorReporter appErrorReporter(Ref ref) => ref.watch(appObservabilityProvider);

/// Provides and owns the SDK client used by the host.
@Riverpod(keepAlive: true)
SdkClient sdkClient(Ref ref) {
  final AppConfig config = ref.watch(appConfigProvider);
  final DemoSdkHttpTransport transport = ref.watch(demoTransportProvider);
  final SdkClient client = SdkClient(
    config: SdkConfig(
      baseUri: Uri.parse(config.apiBaseUrl),
      apiKey: config.apiKey,
    ),
    transport: transport,
    observer: ref.watch(sdkObserverProvider),
  );
  ref.onDispose(client.close);
  return client;
}
