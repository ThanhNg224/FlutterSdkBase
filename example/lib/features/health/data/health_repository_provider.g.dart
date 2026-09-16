// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the Health domain repository backed by the app SDK client.

@ProviderFor(healthRepository)
final healthRepositoryProvider = HealthRepositoryProvider._();

/// Provides the Health domain repository backed by the app SDK client.

final class HealthRepositoryProvider extends $FunctionalProvider<HealthRepository, HealthRepository, HealthRepository>
    with $Provider<HealthRepository> {
  /// Provides the Health domain repository backed by the app SDK client.
  HealthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'healthRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$healthRepositoryHash();

  @$internal
  @override
  $ProviderElement<HealthRepository> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  HealthRepository create(Ref ref) {
    return healthRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HealthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HealthRepository>(value),
    );
  }
}

String _$healthRepositoryHash() => r'723f31bfa31a3e3b4e9693365dd4e0745d16cb71';
