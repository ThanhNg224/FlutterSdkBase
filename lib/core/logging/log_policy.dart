import 'package:flutter_sdk_base/core/logging/log_level.dart';

/// Policy determining whether a log record can be emitted.
final class LogPolicy {
  const LogPolicy({required this.isDebugBuild, this.minimumLevel = LogLevel.debug});

  /// Release configuration that silences logging.
  const LogPolicy.release() : isDebugBuild = false, minimumLevel = LogLevel.error;

  final bool isDebugBuild;
  final LogLevel minimumLevel;

  bool allows(LogLevel level) => isDebugBuild && level.isAtLeast(minimumLevel);

  LogPolicy copyWith({LogLevel? minimumLevel}) =>
      LogPolicy(isDebugBuild: isDebugBuild, minimumLevel: minimumLevel ?? this.minimumLevel);
}
