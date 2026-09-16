import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_sdk_base/flutter_sdk_base.dart';
import 'package:flutter_sdk_base_example/core/error/app_failure.dart';
import 'package:flutter_sdk_base_example/core/observability/app_error_bindings.dart';
import 'package:flutter_sdk_base_example/core/observability/app_observability.dart';
import 'package:flutter_sdk_base_example/core/observability/debug_app_observability.dart';
import 'package:flutter_sdk_base_example/core/observability/host_sdk_observer.dart';
import 'package:flutter_sdk_base_example/core/observability/noop_app_observability.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppFailure', () {
    test('contains only support metadata and never renders diagnostic text', () {
      const AppFailure failure = AppFailure(
        code: SdkErrorCodes.transport,
        isRetryable: true,
        requestId: 'request-1',
        statusCode: 503,
      );

      expect(failure.code, SdkErrorCodes.transport);
      expect(failure.statusCode, 503);
      expect(failure.toString(), 'AppFailure(transport, status: 503)');
      expect(failure.toString(), isNot(contains('diagnostic')));
    });
  });

  group('HostSdkObserver', () {
    test('forwards only the safe SDK event contract', () {
      final _RecordingObservability sink = _RecordingObservability();
      const SdkOperationEvent event = SdkOperationEvent(
        operation: 'health.check',
        requestId: 'request-1',
        sdkVersion: '0.1.0',
        outcome: SdkOperationOutcome.failed,
        elapsed: Duration(milliseconds: 12),
        statusCode: 401,
        failureCode: SdkErrorCodes.unauthorized,
        isRetryable: false,
      );

      HostSdkObserver(sink).onOperation(event);

      expect(sink.operations, hasLength(1));
      expect(sink.operations.single.operation, 'health.check');
      expect(sink.operations.single.statusCode, 401);
      expect(sink.operations.single.failureCode, SdkErrorCodes.unauthorized);
    });
  });

  group('AppFailure reporting policy', () {
    test('does not report cancelled failures', () {
      final _RecordingObservability sink = _RecordingObservability();

      reportAppFailure(sink, _failure(SdkErrorCodes.cancelled));

      expect(sink.failures, isEmpty);
    });

    test('reports operational failures as breadcrumbs', () {
      final _RecordingObservability sink = _RecordingObservability();

      reportAppFailure(sink, _failure(SdkErrorCodes.timeout));
      reportAppFailure(sink, _failure(SdkErrorCodes.transport));
      reportAppFailure(sink, _failure(SdkErrorCodes.rateLimited));

      expect(sink.failures.map((record) => record.kind), <AppFailureReportKind>[
        AppFailureReportKind.operational,
        AppFailureReportKind.operational,
        AppFailureReportKind.operational,
      ]);
    });

    test('reports user and server failures as non-fatal events', () {
      final _RecordingObservability sink = _RecordingObservability();

      for (final String code in <String>[
        SdkErrorCodes.unauthorized,
        SdkErrorCodes.client,
        SdkErrorCodes.server,
        SdkErrorCodes.invalidResponse,
      ]) {
        reportAppFailure(sink, _failure(code));
      }

      expect(sink.failures.map((record) => record.kind), <AppFailureReportKind>[
        AppFailureReportKind.nonFatal,
        AppFailureReportKind.nonFatal,
        AppFailureReportKind.nonFatal,
        AppFailureReportKind.nonFatal,
      ]);
    });
  });

  group('DebugAppObservability and NoopAppObservability', () {
    test('debug output is made from safe metadata only', () {
      final List<String> output = <String>[];
      final DebugAppObservability observability = DebugAppObservability(output.add);
      const AppSdkOperation operation = AppSdkOperation(
        operation: 'health.check',
        requestId: 'request-1',
        sdkVersion: '0.1.0',
        outcome: SdkOperationOutcome.succeeded,
        elapsed: Duration(milliseconds: 8),
      );

      observability.recordSdkOperation(operation);
      observability.reportFailure(_failure(SdkErrorCodes.transport), AppFailureReportKind.operational);
      observability.reportUnhandled(
        const AppUnhandledError(
          source: AppUnhandledSource.flutter,
          errorType: 'StateError',
          stackLineCount: 3,
        ),
      );

      expect(output, hasLength(3));
      expect(output.join('\n'), contains('health.check'));
      expect(output.join('\n'), isNot(contains('https://')));
      expect(output.join('\n'), isNot(contains('api-key')));
      expect(output.join('\n'), isNot(contains('payload')));
    });

    test('noop observability accepts safe records without output', () {
      const NoopAppObservability observability = NoopAppObservability();

      expect(() {
        observability.recordSdkOperation(
          const AppSdkOperation(
            operation: 'health.check',
            requestId: 'request-1',
            sdkVersion: '0.1.0',
            outcome: SdkOperationOutcome.succeeded,
            elapsed: Duration.zero,
          ),
        );
        observability.reportFailure(_failure(SdkErrorCodes.server), AppFailureReportKind.nonFatal);
        observability.reportUnhandled(
          const AppUnhandledError(
            source: AppUnhandledSource.platform,
            errorType: 'Exception',
            stackLineCount: 1,
          ),
        );
      }, returnsNormally);
    });
  });

  group('AppErrorBindings', () {
    late void Function(FlutterErrorDetails details)? previousFlutterHandler;
    late ErrorCallback? previousPlatformHandler;

    setUp(() {
      previousFlutterHandler = FlutterError.onError;
      previousPlatformHandler = PlatformDispatcher.instance.onError;
    });

    tearDown(() {
      FlutterError.onError = previousFlutterHandler;
      PlatformDispatcher.instance.onError = previousPlatformHandler;
    });

    test('reports safe Flutter metadata and preserves default presentation', () {
      final _RecordingObservability sink = _RecordingObservability();
      final AppErrorBindings bindings = AppErrorBindings(reporter: sink);
      bindings.install();
      addTearDown(bindings.restore);

      FlutterError.onError!(
        FlutterErrorDetails(
          exception: StateError('secret payload'),
          stack: StackTrace.fromString('#0      first (file.dart:1:1)\n#1      second (file.dart:2:1)'),
        ),
      );

      expect(sink.unhandled, hasLength(1));
      expect(sink.unhandled.single.source, AppUnhandledSource.flutter);
      expect(sink.unhandled.single.errorType, 'StateError');
      expect(sink.unhandled.single.stackLineCount, 2);
    });

    test('reports platform metadata and returns false for engine handling', () {
      final _RecordingObservability sink = _RecordingObservability();
      final AppErrorBindings bindings = AppErrorBindings(reporter: sink);
      bindings.install();
      addTearDown(bindings.restore);

      final bool handled = PlatformDispatcher.instance.onError!(
        StateError('secret payload'),
        StackTrace.fromString('#0      first (file.dart:1:1)'),
      );

      expect(handled, isFalse);
      expect(sink.unhandled, hasLength(1));
      expect(sink.unhandled.single.source, AppUnhandledSource.platform);
      expect(sink.unhandled.single.errorType, 'StateError');
      expect(sink.unhandled.single.stackLineCount, 1);
    });

    test('restores handlers that were installed before the binding', () {
      void priorFlutter(FlutterErrorDetails details) {}
      bool priorPlatform(Object error, StackTrace stack) => true;
      FlutterError.onError = priorFlutter;
      PlatformDispatcher.instance.onError = priorPlatform;
      final AppErrorBindings bindings = AppErrorBindings(reporter: _RecordingObservability());

      bindings.install();
      bindings.restore();

      expect(FlutterError.onError, same(priorFlutter));
      expect(PlatformDispatcher.instance.onError, same(priorPlatform));
    });
  });
}

AppFailure _failure(String code) => AppFailure(
  code: code,
  isRetryable: code == SdkErrorCodes.timeout || code == SdkErrorCodes.transport,
  requestId: 'request-1',
);

final class _RecordingObservability implements AppObservability {
  final List<AppSdkOperation> operations = <AppSdkOperation>[];
  final List<({AppFailure failure, AppFailureReportKind kind})> failures =
      <({AppFailure failure, AppFailureReportKind kind})>[];
  final List<AppUnhandledError> unhandled = <AppUnhandledError>[];

  @override
  void recordSdkOperation(AppSdkOperation operation) => operations.add(operation);

  @override
  void reportFailure(AppFailure failure, AppFailureReportKind kind) => failures.add((failure: failure, kind: kind));

  @override
  void reportUnhandled(AppUnhandledError error) => unhandled.add(error);
}
