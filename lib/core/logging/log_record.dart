import 'package:flutter_sdk_base/core/logging/log_level.dart';
import 'package:flutter_sdk_base/core/logging/redacted.dart';

/// One immutable log event, plus the single place its text layout is decided.
///
/// Keeping formatting here rather than in the sink means a test can assert on
/// exactly what would reach logcat without touching `debugPrint`.
final class LogRecord {
  const LogRecord({
    required this.level,
    required this.scope,
    required this.message,
    this.data = const {},
    this.error,
    this.stackTrace,
  });

  /// A raw stack trace is hundreds of lines of framework noise; the frames that
  /// matter are at the top.
  static const _maxStackFrames = 12;

  final LogLevel level;

  /// Feature or subsystem this came from — `HTTP`, `Riverpod`, `Errors`.
  final String scope;

  /// Static description of what happened. Keep runtime values out of here and
  /// in [data], where the [Redacted] type can vouch for them.
  final String message;

  final Map<String, Redacted> data;
  final Object? error;
  final StackTrace? stackTrace;

  /// `🐛 D/HTTP · ➡️ request · url=https://…`
  String format() {
    final buffer = StringBuffer('${level.glyph} ${level.label}/$scope · $message');
    for (final entry in data.entries) {
      buffer.write(' · ${entry.key}=${entry.value}');
    }
    final failure = error;
    if (failure != null) {
      buffer.write('\n     ↳ ${_describeError(failure)}');
    }
    final trace = stackTrace;
    if (trace != null) {
      buffer.write(_formatStackTrace(trace));
    }
    return buffer.toString();
  }

  /// Most exceptions already name their own type in `toString()`; adding it
  /// again reads as `NetworkException: NetworkException: …`.
  String _describeError(Object failure) {
    final text = failure.toString();
    final typeName = failure.runtimeType.toString();
    return text.startsWith(typeName) ? text : '$typeName: $text';
  }

  String _formatStackTrace(StackTrace trace) {
    final frames = trace.toString().trimRight().split('\n');
    final buffer = StringBuffer();
    for (final frame in frames.take(_maxStackFrames)) {
      buffer.write('\n       $frame');
    }
    final hidden = frames.length - _maxStackFrames;
    if (hidden > 0) {
      buffer.write('\n       … +$hidden more frames');
    }
    return buffer.toString();
  }
}
