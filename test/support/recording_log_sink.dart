import 'package:flutter_sdk_base/core/logging/logging.dart';

/// Test sink that records log entries in memory.
final class RecordingLogSink implements LogSink {
  final List<LogRecord> records = [];

  @override
  void write(LogRecord record) => records.add(record);

  Iterable<String> get formatted => records.map((record) => record.format());

  void clear() => records.clear();
}
