import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_sdk_base_example/core/observability/app_observability.dart';

/// Installs and restores safe framework error-reporting bindings.
final class AppErrorBindings {
  /// Creates bindings backed by the host's [reporter].
  AppErrorBindings({required this.reporter});

  /// The host-owned reporter receiving only sanitized metadata.
  final AppErrorReporter reporter;
  void Function(FlutterErrorDetails details)? _previousFlutterHandler;
  ErrorCallback? _previousPlatformHandler;
  bool _installed = false;

  /// Installs handlers once and remembers the handlers that must be restored.
  void install() {
    if (_installed) {
      return;
    }

    _previousFlutterHandler = FlutterError.onError;
    _previousPlatformHandler = PlatformDispatcher.instance.onError;
    FlutterError.onError = _handleFlutterError;
    PlatformDispatcher.instance.onError = _handlePlatformError;
    _installed = true;
  }

  /// Restores the handlers that were active before [install].
  void restore() {
    if (!_installed) {
      return;
    }

    FlutterError.onError = _previousFlutterHandler;
    PlatformDispatcher.instance.onError = _previousPlatformHandler;
    _installed = false;
  }

  void _handleFlutterError(FlutterErrorDetails details) {
    // Keep Flutter's standard console/presentation behavior independent of
    // whether a host reporter is configured or healthy.
    FlutterError.presentError(details);
    _reportUnhandled(
      AppUnhandledError(
        source: AppUnhandledSource.flutter,
        errorType: details.exception.runtimeType.toString(),
        stackLineCount: _stackLineCount(details.stack),
      ),
    );
  }

  bool _handlePlatformError(Object error, StackTrace stack) {
    _reportUnhandled(
      AppUnhandledError(
        source: AppUnhandledSource.platform,
        errorType: error.runtimeType.toString(),
        stackLineCount: _stackLineCount(stack),
      ),
    );
    // Returning false delegates unhandled-error presentation to the engine.
    return false;
  }

  void _reportUnhandled(AppUnhandledError error) {
    try {
      reporter.reportUnhandled(error);
    } on Object {
      // Reporting must never replace Flutter's own error handling.
    }
  }
}

int _stackLineCount(StackTrace? stack) {
  if (stack == null) {
    return 0;
  }
  final String text = stack.toString();
  if (text.trim().isEmpty) {
    return 0;
  }
  return text.split('\n').where((String line) => line.trim().isNotEmpty).length;
}
