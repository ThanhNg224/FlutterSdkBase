import 'package:flutter/material.dart';
import 'package:flutter_sdk_base/core/constants/storage_keys.dart';
import 'package:flutter_sdk_base/core/storage/storage_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'locale_provider.g.dart';

/// Provider for the active app [Locale]. `null` means follow the device locale.
@Riverpod(keepAlive: true)
class LocaleNotifier extends _$LocaleNotifier {
  @override
  Locale? build() {
    final storage = ref.watch(localStorageServiceProvider);
    final savedCode = storage.getString(StorageKeys.localeCode);
    return savedCode == null ? null : Locale(savedCode);
  }

  void setLocale(Locale? locale) {
    state = locale;
    final storage = ref.read(localStorageServiceProvider);
    if (locale == null) {
      storage.remove(StorageKeys.localeCode);
    } else {
      storage.setString(StorageKeys.localeCode, locale.languageCode);
    }
  }
}
