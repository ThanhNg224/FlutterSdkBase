import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sdk_base/app/app.dart';
import 'package:flutter_sdk_base/app/observers/app_provider_observer.dart';
import 'package:flutter_sdk_base/core/logging/logging.dart';
import 'package:flutter_sdk_base/core/storage/storage_providers.dart';
import 'package:flutter_sdk_base/core/widgets/app_error_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _log = AppLogger('App');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Install resilient UI error boundary
  ErrorWidget.builder = (details) => AppErrorWidget(details: details);

  // Log uncaught async errors (silent in release by logger policy)
  PlatformDispatcher.instance.onError = (error, stack) {
    _log.error('uncaught async error', error: error, stackTrace: stack);
    return !kDebugMode;
  };

  // Initialize async core infrastructure before runApp
  final sharedPrefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      observers: [
        AppProviderObserver(),
      ],
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
      ],
      child: const FlutterSdkBaseApp(),
    ),
  );
}
