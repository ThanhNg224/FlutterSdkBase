import 'package:flutter_sdk_base/src/client/sdk_config.dart';
import 'package:flutter_sdk_base/src/client/sdk_request_executor.dart';
import 'package:flutter_sdk_base/src/health/sdk_health_service.dart';
import 'package:flutter_sdk_base/src/logging/sdk_observer.dart';
import 'package:flutter_sdk_base/src/logging/sdk_operation_event.dart';
import 'package:flutter_sdk_base/src/transport/package_http_transport.dart';
import 'package:flutter_sdk_base/src/transport/sdk_http_transport.dart';

/// The entry point to the SDK.
///
/// Create one per configuration, use it, then [close] it. The SDK holds no
/// global state, so several clients may run at once with different
/// configuration, transports, and observers.
///
/// ```dart
/// final sdk = SdkClient(
///   config: SdkConfig(baseUri: apiRoot, apiKey: key),
/// );
/// final health = await sdk.health.check();
/// await sdk.close();
/// ```
final class SdkClient {
  /// Creates a client.
  ///
  /// [transport] defaults to the SDK's own `package:http` implementation.
  /// [observer] defaults to a silent observer. A supplied transport is owned by
  /// this client and is closed by [close]; do not share one between clients.
  SdkClient({
    required SdkConfig config,
    SdkHttpTransport? transport,
    SdkObserver? observer,
  }) : this._(
         config: config,
         transport: transport ?? PackageHttpTransport(),
         observer: observer ?? const _NoopSdkObserver(),
         clock: DateTime.now,
       );

  SdkClient._({
    required SdkConfig config,
    required SdkHttpTransport transport,
    required SdkObserver observer,
    required SdkClock clock,
  }) : _executor = SdkRequestExecutor(config: config, transport: transport, observer: observer) {
    _health = SdkHealthService(executor: _executor, config: config, clock: clock);
  }

  final SdkRequestExecutor _executor;

  late final SdkHealthService _health;

  /// The reference health capability.
  SdkHealthService get health => _health;

  /// Cancels in-flight work, releases the transport, and blocks further calls.
  ///
  /// Idempotent. Any operation attempted afterwards throws [StateError].
  /// In-flight operations fail with `SdkErrorCodes.cancelled`; cancellation is
  /// best-effort, so a request already delivered may still be processed by the
  /// server.
  Future<void> close() => _executor.close();
}

final class _NoopSdkObserver implements SdkObserver {
  const _NoopSdkObserver();

  @override
  void onOperation(SdkOperationEvent event) {}
}
