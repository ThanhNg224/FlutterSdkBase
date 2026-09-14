import 'package:flutter/foundation.dart';
import 'package:flutter_sdk_base/core/logging/log_level.dart';
import 'package:flutter_sdk_base/core/logging/log_policy.dart';
import 'package:flutter_sdk_base/core/logging/log_record.dart';
import 'package:flutter_sdk_base/core/logging/log_sink.dart';
import 'package:flutter_sdk_base/core/logging/redacted.dart';

/// Application logger with structured data and level filtering.
/// Redaction is enforced via [Redacted] data mapping.
final class AppLogger {
  const AppLogger(this.scope);

  /// Feature or subsystem name shown in every line (e.g., `HTTP`, `Riverpod`).
  final String scope;

  static LogPolicy _policy = const LogPolicy(isDebugBuild: kDebugMode);
  static LogSink _sink = kDebugMode ? const DebugPrintSink() : const SilentSink();

  /// Current policy, for diagnostics and tests.
  static LogPolicy get policy => _policy;

  /// Adjusts verbosity or redirects output at runtime.
  static void configure({LogLevel? minimumLevel, LogSink? sink}) {
    if (minimumLevel != null) _policy = _policy.copyWith(minimumLevel: minimumLevel);
    if (sink != null) _sink = sink;
  }

  /// Installs an arbitrary policy — including a release-like one — so the
  /// "silent unless debug" rule is actually testable.
  @visibleForTesting
  static void installForTest({required LogPolicy policy, required LogSink sink}) {
    _policy = policy;
    _sink = sink;
  }

  @visibleForTesting
  static void restoreDefaults() {
    _policy = const LogPolicy(isDebugBuild: kDebugMode);
    _sink = kDebugMode ? const DebugPrintSink() : const SilentSink();
  }

  void trace(String message, {Map<String, Redacted>? data}) => _emit(LogLevel.trace, message, data: data);

  void debug(String message, {Map<String, Redacted>? data}) => _emit(LogLevel.debug, message, data: data);

  void info(String message, {Map<String, Redacted>? data}) => _emit(LogLevel.info, message, data: data);

  void warn(String message, {Map<String, Redacted>? data, Object? error, StackTrace? stackTrace}) =>
      _emit(LogLevel.warn, message, data: data, error: error, stackTrace: stackTrace);

  void error(String message, {Object? error, StackTrace? stackTrace, Map<String, Redacted>? data}) =>
      _emit(LogLevel.error, message, data: data, error: error, stackTrace: stackTrace);

  void _emit(
    LogLevel level,
    String message, {
    Map<String, Redacted>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_policy.allows(level)) return;
    _sink.write(
      LogRecord(
        level: level,
        scope: scope,
        message: message,
        data: data ?? const {},
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }
}
