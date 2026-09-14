import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_sdk_base/core/constants/api_endpoints.dart';

part 'app_config.freezed.dart';

enum Environment { development, production }

/// Cross-cutting runtime configuration (environment, credentials, mock mode, version).
/// Lives in `core` so any layer/feature can read it without cross-feature dependencies.
@Freezed(toStringOverride: false)
abstract class AppConfig with _$AppConfig {
  const factory AppConfig({
    @Default(Environment.production) Environment environment,
    @Default(ApiEndpoints.prodUrl) String baseUrl,
    @Default(ApiEndpoints.defaultProdToken) String appToken,
    @Default(ApiEndpoints.defaultProdClientKey) String clientKey,
    @Default(false) bool mockSdkEnabled,
    @Default(ApiEndpoints.placeholderSdkVersion) String sdkVersion,
  }) = _AppConfig;
}
