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

String _$sdkClientHash() => r'cbfe2b50e4e61260d78064f5a728e408cfce74be';
