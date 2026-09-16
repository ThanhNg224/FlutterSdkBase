import 'package:flutter_sdk_base/flutter_sdk_base.dart';
import 'package:flutter_sdk_base_example/app/providers/app_providers.dart';
import 'package:flutter_sdk_base_example/core/config/app_config.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_view_data.g.dart';

/// Read-only host diagnostics presented by the Settings feature.
final class SettingsViewData {
  /// Creates diagnostics without retaining the API key.
  const SettingsViewData({
    required this.environmentName,
    required this.apiBaseUrl,
    required this.sdkVersion,
    required this.transportDescription,
  });

  /// The configured environment label.
  final String environmentName;

  /// The configured API root.
  final String apiBaseUrl;

  /// The SDK version used by the host.
  final String sdkVersion;

  /// The description of the deterministic transport fixture.
  final String transportDescription;
}

/// Provides read-only diagnostics without exposing the configured API key.
@riverpod
SettingsViewData settingsViewData(Ref ref) {
  final AppConfig config = ref.watch(appConfigProvider);
  return SettingsViewData(
    environmentName: config.environmentName,
    apiBaseUrl: config.apiBaseUrl,
    sdkVersion: sdkVersion,
    transportDescription: config.transportDescription,
  );
}
