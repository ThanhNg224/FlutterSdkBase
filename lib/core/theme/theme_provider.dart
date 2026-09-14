import 'package:flutter/material.dart';
import 'package:flutter_sdk_base/core/constants/storage_keys.dart';
import 'package:flutter_sdk_base/core/storage/storage_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_provider.g.dart';

/// Provider for dynamic ThemeMode toggle (Light, Dark, System)
@Riverpod(keepAlive: true)
class ThemeModeNotifier extends _$ThemeModeNotifier {
  @override
  ThemeMode build() {
    final storage = ref.watch(localStorageServiceProvider);
    final savedMode = storage.getString(StorageKeys.themeMode);
    if (savedMode == 'dark') return ThemeMode.dark;
    if (savedMode == 'light') return ThemeMode.light;
    return ThemeMode.system;
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    final storage = ref.read(localStorageServiceProvider);
    storage.setString(StorageKeys.themeMode, mode.name);
  }

  void toggle() {
    if (state == ThemeMode.dark) {
      setThemeMode(ThemeMode.light);
    } else {
      setThemeMode(ThemeMode.dark);
    }
  }
}
