import 'package:flutter_sdk_base/src/logging/sdk_log_level.dart';

/// Receives diagnostic records from the SDK.
///
/// The SDK redacts credentials and omits headers and bodies before calling
/// this, so an implementation may forward records anywhere the host wants.
abstract interface class SdkLogger {
  /// Handles one record.
  void log(
    SdkLogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  });
}
