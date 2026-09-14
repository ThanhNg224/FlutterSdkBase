import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sdk_base/core/logging/logging.dart';

import '../../support/recording_log_sink.dart';

void main() {
  late RecordingLogSink sink;

  setUp(() => sink = RecordingLogSink());
  tearDown(AppLogger.restoreDefaults);

  void install({required bool isDebugBuild, LogLevel minimumLevel = LogLevel.trace}) {
    AppLogger.installForTest(
      policy: LogPolicy(isDebugBuild: isDebugBuild, minimumLevel: minimumLevel),
      sink: sink,
    );
  }

  group('LogPolicy', () {
    test('a non-debug build allows nothing, at any level', () {
      const policy = LogPolicy(isDebugBuild: false, minimumLevel: LogLevel.trace);

      for (final level in LogLevel.values) {
        expect(policy.allows(level), isFalse, reason: '$level must be dropped in a release build');
      }
    });

    test('the release preset allows nothing', () {
      const policy = LogPolicy.release();

      for (final level in LogLevel.values) {
        expect(policy.allows(level), isFalse, reason: '$level must be dropped in a release build');
      }
    });

    test('a debug build drops records below the minimum level', () {
      const policy = LogPolicy(isDebugBuild: true, minimumLevel: LogLevel.warn);

      expect(policy.allows(LogLevel.trace), isFalse);
      expect(policy.allows(LogLevel.debug), isFalse);
      expect(policy.allows(LogLevel.info), isFalse);
      expect(policy.allows(LogLevel.warn), isTrue);
      expect(policy.allows(LogLevel.error), isTrue);
    });

    test('defaults to hiding trace-level churn', () {
      const policy = LogPolicy(isDebugBuild: true);

      expect(policy.allows(LogLevel.trace), isFalse);
      expect(policy.allows(LogLevel.debug), isTrue);
    });
  });

  group('AppLogger in a non-debug build', () {
    test('emits nothing, not even errors', () {
      install(isDebugBuild: false);
      const log = AppLogger('Test');

      log.trace('trace');
      log.debug('debug');
      log.info('info');
      log.warn('warn');
      log.error('error', error: StateError('boom'), stackTrace: StackTrace.current);

      expect(sink.records, isEmpty);
    });

    test('stays silent even if a printing sink is configured', () {
      AppLogger.installForTest(policy: const LogPolicy.release(), sink: sink);
      AppLogger.configure(sink: sink, minimumLevel: LogLevel.trace);

      const AppLogger('Test').error('should never appear');

      expect(sink.records, isEmpty);
    });
  });

  group('AppLogger in a debug build', () {
    test('emits every level once the threshold allows it', () {
      install(isDebugBuild: true);
      const log = AppLogger('Test');

      log.trace('a');
      log.debug('b');
      log.info('c');
      log.warn('d');
      log.error('e');

      expect(sink.records.map((record) => record.level), LogLevel.values);
    });

    test('carries the scope of the logger that emitted it', () {
      install(isDebugBuild: true);

      const AppLogger('HTTP').debug('request');

      expect(sink.records.single.scope, 'HTTP');
    });

    test('configure raises the threshold without touching the build mode', () {
      install(isDebugBuild: true);
      AppLogger.configure(minimumLevel: LogLevel.error);

      const log = AppLogger('Test');
      log.debug('dropped');
      log.error('kept');

      expect(sink.records.map((record) => record.message), ['kept']);
      expect(AppLogger.policy.isDebugBuild, isTrue);
    });
  });

  group('LogRecord.format', () {
    setUp(() => install(isDebugBuild: true));

    test('renders level, scope, message and redacted data', () {
      const AppLogger('Settings').info(
        'credentials saved',
        data: {'token': Redacted.secret('demo_live_SECRET_9f3a')},
      );

      final line = sink.formatted.single;
      expect(line, contains('I/Settings'));
      expect(line, contains('credentials saved'));
      expect(line, contains('token=demo…9f3a'));
      expect(line, isNot(contains('SECRET')));
    });

    test('appends the error type and message', () {
      const AppLogger('Errors').error('failed', error: StateError('boom'));

      expect(sink.formatted.single, contains('StateError: Bad state: boom'));
    });

    test('truncates a long stack trace instead of dumping every frame', () {
      final frames = List.generate(40, (index) => '#$index      some.frame ($index)').join('\n');

      const AppLogger('Errors').error('failed', stackTrace: StackTrace.fromString(frames));

      final line = sink.formatted.single;
      expect(line, contains('#11'));
      expect(line, isNot(contains('#12')));
      expect(line, contains('… +28 more frames'));
    });
  });
}
