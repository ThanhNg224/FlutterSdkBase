import 'package:flutter_sdk_base/src/logging/sdk_log_level.dart';
import 'package:flutter_sdk_base/src/logging/sdk_logger.dart';

/// The default logger: discards every record.
///
/// An SDK must be silent unless its host asks for output.
final class SilentSdkLogger implements SdkLogger {
  /// Creates the silent logger.
  const SilentSdkLogger();

  @override
  void log(
    SdkLogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {}
}
