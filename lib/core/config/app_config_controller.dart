import 'package:flutter_sdk_base/core/config/app_config.dart';
import 'package:flutter_sdk_base/core/constants/api_endpoints.dart';
import 'package:flutter_sdk_base/core/constants/storage_keys.dart';
import 'package:flutter_sdk_base/core/errors/error_handler.dart';
import 'package:flutter_sdk_base/core/errors/failure.dart';
import 'package:flutter_sdk_base/core/storage/local_storage_service.dart';
import 'package:flutter_sdk_base/core/storage/secure_storage_service.dart';
import 'package:flutter_sdk_base/core/storage/storage_providers.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_config_controller.g.dart';

@Riverpod(keepAlive: true)
class AppConfigController extends _$AppConfigController {
  @override
  Future<AppConfig> build() async {
    final storage = ref.watch(localStorageServiceProvider);
    final secureStorage = ref.watch(secureStorageServiceProvider);
    final useDev = storage.getBool(StorageKeys.useDevEnvironment) ?? false;
    final mockSdk = storage.getBool(StorageKeys.mockSdkMode) ?? false;
    final credentials = await _readCredentialOverrides(storage, secureStorage);

    final env = useDev ? Environment.development : Environment.production;
    final baseUrl = useDev ? ApiEndpoints.devUrl : ApiEndpoints.prodUrl;

    return AppConfig(
      environment: env,
      mockSdkEnabled: mockSdk,
      baseUrl: baseUrl,
      appToken: credentials.appToken ?? _defaultTokenFor(useDev),
      clientKey: credentials.clientKey ?? _defaultClientKeyFor(useDev),
    );
  }

  String _defaultTokenFor(bool useDev) => useDev ? ApiEndpoints.defaultDevToken : ApiEndpoints.defaultProdToken;
  String _defaultClientKeyFor(bool useDev) =>
      useDev ? ApiEndpoints.defaultDevClientKey : ApiEndpoints.defaultProdClientKey;

  Future<void> toggleEnvironment(bool useDev) async {
    final storage = ref.read(localStorageServiceProvider);
    await storage.setBool(StorageKeys.useDevEnvironment, useDev);

    final env = useDev ? Environment.development : Environment.production;
    final baseUrl = useDev ? ApiEndpoints.devUrl : ApiEndpoints.prodUrl;
    final current = state.value;
    if (current == null) return;
    final secureStorage = ref.read(secureStorageServiceProvider);
    final token = await secureStorage.read(StorageKeys.secureAppToken) ?? _defaultTokenFor(useDev);
    final clientKey = await secureStorage.read(StorageKeys.secureClientKey) ?? _defaultClientKeyFor(useDev);

    state = AsyncData(current.copyWith(environment: env, baseUrl: baseUrl, appToken: token, clientKey: clientKey));
  }

  Future<void> toggleMockSdk(bool enabled) async {
    final storage = ref.read(localStorageServiceProvider);
    await storage.setBool(StorageKeys.mockSdkMode, enabled);
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(mockSdkEnabled: enabled));
    }
  }

  Future<Either<Failure, void>> clearCredentialOverrides() {
    return ErrorHandler.guard(() async {
      final secureStorage = ref.read(secureStorageServiceProvider);
      await secureStorage.delete(StorageKeys.secureAppToken);
      await secureStorage.delete(StorageKeys.secureClientKey);

      final current = state.value;
      if (current != null) {
        final useDev = current.environment == Environment.development;
        state = AsyncData(
          current.copyWith(
            appToken: _defaultTokenFor(useDev),
            clientKey: _defaultClientKeyFor(useDev),
          ),
        );
      }
    });
  }

  Future<Either<Failure, void>> updateCredentials({String? appToken, String? clientKey}) {
    return ErrorHandler.guard(() async {
      final secureStorage = ref.read(secureStorageServiceProvider);
      if (appToken != null) {
        await secureStorage.write(key: StorageKeys.secureAppToken, value: appToken);
      }
      if (clientKey != null) {
        await secureStorage.write(key: StorageKeys.secureClientKey, value: clientKey);
      }

      final current = state.value;
      if (current != null) {
        state = AsyncData(
          current.copyWith(
            appToken: appToken ?? current.appToken,
            clientKey: clientKey ?? current.clientKey,
          ),
        );
      }
    });
  }

  Future<({String? appToken, String? clientKey})> _readCredentialOverrides(
    ILocalStorageService storage,
    ISecureStorageService secureStorage,
  ) async {
    var appToken = await secureStorage.read(StorageKeys.secureAppToken);
    var clientKey = await secureStorage.read(StorageKeys.secureClientKey);
    final legacyAppToken = storage.getString(StorageKeys.legacyAppToken);
    final legacyClientKey = storage.getString(StorageKeys.legacyClientKey);

    if (appToken == null && legacyAppToken != null) {
      await secureStorage.write(key: StorageKeys.secureAppToken, value: legacyAppToken);
      appToken = legacyAppToken;
    }
    if (clientKey == null && legacyClientKey != null) {
      await secureStorage.write(key: StorageKeys.secureClientKey, value: legacyClientKey);
      clientKey = legacyClientKey;
    }

    if (legacyAppToken != null) {
      await storage.remove(StorageKeys.legacyAppToken);
    }
    if (legacyClientKey != null) {
      await storage.remove(StorageKeys.legacyClientKey);
    }

    return (appToken: appToken, clientKey: clientKey);
  }
}
