import 'package:flutter/foundation.dart';
import 'package:flutter_sdk_base/core/logging/log_record.dart';

/// Destination for records that passed the policy gate.
abstract interface class LogSink {
  void write(LogRecord record);
}

/// Sink for log output.
final class DebugPrintSink implements LogSink {
  const DebugPrintSink();

  @override
  void write(LogRecord record) => debugPrint(record.format());
}

/// Discards all log records.
final class SilentSink implements LogSink {
  const SilentSink();

  @override
  void write(LogRecord record) {}
}
