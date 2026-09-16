// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_view_data.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides read-only diagnostics without exposing the configured API key.

@ProviderFor(settingsViewData)
final settingsViewDataProvider = SettingsViewDataProvider._();

/// Provides read-only diagnostics without exposing the configured API key.

final class SettingsViewDataProvider
    extends
        $FunctionalProvider<
          SettingsViewData,
          SettingsViewData,
          SettingsViewData
        >
    with $Provider<SettingsViewData> {
  /// Provides read-only diagnostics without exposing the configured API key.
  SettingsViewDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsViewDataProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsViewDataHash();

  @$internal
  @override
  $ProviderElement<SettingsViewData> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SettingsViewData create(Ref ref) {
    return settingsViewData(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SettingsViewData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SettingsViewData>(value),
    );
  }
}

String _$settingsViewDataHash() => r'd69b0150ab5e08f54986ac8681a900eae9a52f81';
