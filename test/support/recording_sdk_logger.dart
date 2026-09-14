import 'package:flutter_sdk_base/src/logging/sdk_log_level.dart';
import 'package:flutter_sdk_base/src/logging/sdk_logger.dart';

/// Captures every record so tests can assert on what the SDK emitted.
final class RecordingSdkLogger implements SdkLogger {
  final List<String> lines = <String>[];

  /// Every record joined, for substring assertions.
  String get combined => lines.join('\n');

  @override
  void log(
    SdkLogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    lines.add('${level.name}: $message${error == null ? '' : ' error=$error'}');
  }
}
