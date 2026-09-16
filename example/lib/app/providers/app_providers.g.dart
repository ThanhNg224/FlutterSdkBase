// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the immutable configuration for the reference host.

@ProviderFor(appConfig)
final appConfigProvider = AppConfigProvider._();

/// Provides the immutable configuration for the reference host.

final class AppConfigProvider extends $FunctionalProvider<AppConfig, AppConfig, AppConfig> with $Provider<AppConfig> {
  /// Provides the immutable configuration for the reference host.
  AppConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appConfigProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appConfigHash();

  @$internal
  @override
  $ProviderElement<AppConfig> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  AppConfig create(Ref ref) {
    return appConfig(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppConfig value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppConfig>(value),
    );
  }
}

String _$appConfigHash() => r'65f31b42750ad7f4f9001feabaa7ef5f438d4f16';

/// Provides the response scenario used by the offline demo transport.

@ProviderFor(demoHealthScenario)
final demoHealthScenarioProvider = DemoHealthScenarioProvider._();

/// Provides the response scenario used by the offline demo transport.

final class DemoHealthScenarioProvider
    extends $FunctionalProvider<DemoHealthScenario, DemoHealthScenario, DemoHealthScenario>
    with $Provider<DemoHealthScenario> {
  /// Provides the response scenario used by the offline demo transport.
  DemoHealthScenarioProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'demoHealthScenarioProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$demoHealthScenarioHash();

  @$internal
  @override
  $ProviderElement<DemoHealthScenario> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DemoHealthScenario create(Ref ref) {
    return demoHealthScenario(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DemoHealthScenario value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DemoHealthScenario>(value),
    );
  }
}

String _$demoHealthScenarioHash() => r'3e3cc786a359f5709e13562c22c9d423956e60ce';

/// Provides the host-only adapter around the SDK's testing transport.

@ProviderFor(demoTransport)
final demoTransportProvider = DemoTransportProvider._();

/// Provides the host-only adapter around the SDK's testing transport.

final class DemoTransportProvider
    extends $FunctionalProvider<DemoSdkHttpTransport, DemoSdkHttpTransport, DemoSdkHttpTransport>
    with $Provider<DemoSdkHttpTransport> {
  /// Provides the host-only adapter around the SDK's testing transport.
  DemoTransportProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'demoTransportProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$demoTransportHash();

  @$internal
  @override
  $ProviderElement<DemoSdkHttpTransport> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DemoSdkHttpTransport create(Ref ref) {
    return demoTransport(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DemoSdkHttpTransport value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DemoSdkHttpTransport>(value),
    );
  }
}

String _$demoTransportHash() => r'35aabdb83aa02347eb9789c6b8cfad249802ca72';

/// Provides the host observability sink. Release builds are silent by default.

@ProviderFor(appObservability)
final appObservabilityProvider = AppObservabilityProvider._();

/// Provides the host observability sink. Release builds are silent by default.

final class AppObservabilityProvider extends $FunctionalProvider<AppObservability, AppObservability, AppObservability>
    with $Provider<AppObservability> {
  /// Provides the host observability sink. Release builds are silent by default.
  AppObservabilityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appObservabilityProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appObservabilityHash();

  @$internal
  @override
  $ProviderElement<AppObservability> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  AppObservability create(Ref ref) {
    return appObservability(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppObservability value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppObservability>(value),
    );
  }
}

String _$appObservabilityHash() => r'88d080e71472cb7936ae71cef0f6e04407c51fa1';

/// Provides the adapter that passes safe SDK events to host observability.

@ProviderFor(sdkObserver)
final sdkObserverProvider = SdkObserverProvider._();

/// Provides the adapter that passes safe SDK events to host observability.

final class SdkObserverProvider extends $FunctionalProvider<SdkObserver, SdkObserver, SdkObserver>
    with $Provider<SdkObserver> {
  /// Provides the adapter that passes safe SDK events to host observability.
  SdkObserverProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sdkObserverProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sdkObserverHash();

  @$internal
  @override
  $ProviderElement<SdkObserver> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  SdkObserver create(Ref ref) {
    return sdkObserver(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SdkObserver value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SdkObserver>(value),
    );
  }
}

String _$sdkObserverHash() => r'9a7f1900c3572ca82025a486c6e5b87856d33038';

/// Provides the reporter used by host repositories for mapped SDK failures.

@ProviderFor(appErrorReporter)
final appErrorReporterProvider = AppErrorReporterProvider._();

/// Provides the reporter used by host repositories for mapped SDK failures.

final class AppErrorReporterProvider extends $FunctionalProvider<AppErrorReporter, AppErrorReporter, AppErrorReporter>
    with $Provider<AppErrorReporter> {
  /// Provides the reporter used by host repositories for mapped SDK failures.
  AppErrorReporterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appErrorReporterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appErrorReporterHash();

  @$internal
  @override
  $ProviderElement<AppErrorReporter> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  AppErrorReporter create(Ref ref) {
    return appErrorReporter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppErrorReporter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppErrorReporter>(value),
    );
  }
}

String _$appErrorReporterHash() => r'a84791c79b7ac404807314e21fdedda3a957c74a';

/// Provides and owns the SDK client used by the host.

@ProviderFor(sdkClient)
final sdkClientProvider = SdkClientProvider._();

/// Provides and owns the SDK client used by the host.

final class SdkClientProvider extends $FunctionalProvider<SdkClient, SdkClient, SdkClient> with $Provider<SdkClient> {
  /// Provides and owns the SDK client used by the host.
  SdkClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sdkClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sdkClientHash();

  @$internal
  @override
  $ProviderElement<SdkClient> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  SdkClient create(Ref ref) {
    return sdkClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SdkClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SdkClient>(value),
    );
  }
}

String _$sdkClientHash() => r'01750649d65e4950c4f4dfcefca943e125423386';
