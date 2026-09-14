import 'package:flutter_sdk_base/core/config/app_config.dart';
import 'package:flutter_sdk_base/core/config/app_config_controller.dart';
import 'package:flutter_sdk_base/core/constants/storage_keys.dart';
import 'package:flutter_sdk_base/core/storage/secure_storage_service.dart';
import 'package:flutter_sdk_base/core/storage/storage_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeSecureStorageService implements ISecureStorageService {
  final values = <String, String>{};

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write({required String key, required String value}) async {
    values[key] = value;
  }
}

void main() {
  late SharedPreferences preferences;
  late FakeSecureStorageService secureStorage;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      StorageKeys.legacyAppToken: 'legacy-token',
      StorageKeys.legacyClientKey: 'legacy-client-key',
    });
    preferences = await SharedPreferences.getInstance();
    secureStorage = FakeSecureStorageService();
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        secureStorageServiceProvider.overrideWithValue(secureStorage),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('migrates plaintext credential overrides to secure storage', () async {
    final config = await container.read(appConfigControllerProvider.future);

    expect(config.appToken, 'legacy-token');
    expect(config.clientKey, 'legacy-client-key');
    expect(secureStorage.values[StorageKeys.secureAppToken], 'legacy-token');
    expect(secureStorage.values[StorageKeys.secureClientKey], 'legacy-client-key');
    expect(preferences.getString(StorageKeys.legacyAppToken), isNull);
    expect(preferences.getString(StorageKeys.legacyClientKey), isNull);
  });

  test('updates and clears secure credential overrides', () async {
    await container.read(appConfigControllerProvider.future);
    final controller = container.read(appConfigControllerProvider.notifier);

    final update = await controller.updateCredentials(appToken: 'updated-token');
    expect(update.isRight(), isTrue);
    expect(secureStorage.values[StorageKeys.secureAppToken], 'updated-token');
    expect(container.read(appConfigControllerProvider).value?.appToken, 'updated-token');

    final clear = await controller.clearCredentialOverrides();
    expect(clear.isRight(), isTrue);
    expect(secureStorage.values, isEmpty);
    expect(container.read(appConfigControllerProvider).value?.appToken, isEmpty);
    expect(container.read(appConfigControllerProvider).value?.environment, Environment.production);
  });

  test('does not expose credentials through string conversion', () {
    const config = AppConfig(appToken: 'private-token', clientKey: 'private-client-key');

    expect(config.toString(), isNot(contains('private-token')));
    expect(config.toString(), isNot(contains('private-client-key')));
  });
}
