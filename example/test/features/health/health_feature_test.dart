import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sdk_base/flutter_sdk_base.dart';
import 'package:flutter_sdk_base/flutter_sdk_base_testing.dart';
import 'package:flutter_sdk_base_example/core/error/app_error_copy.dart';
import 'package:flutter_sdk_base_example/core/error/app_failure.dart';
import 'package:flutter_sdk_base_example/core/observability/app_observability.dart';
import 'package:flutter_sdk_base_example/core/observability/noop_app_observability.dart';
import 'package:flutter_sdk_base_example/features/health/data/health_repository_impl.dart';
import 'package:flutter_sdk_base_example/features/health/data/health_repository_provider.dart';
import 'package:flutter_sdk_base_example/features/health/domain/health_repository.dart';
import 'package:flutter_sdk_base_example/features/health/domain/models/health_snapshot.dart';
import 'package:flutter_sdk_base_example/features/health/presentation/controllers/health_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HealthRepositoryImpl', () {
    test('maps SDK health data to the host domain snapshot', () async {
      final FakeSdkHttpTransport transport = FakeSdkHttpTransport()..enqueueJson('{"status":"ok"}');
      final SdkClient sdk = _createClient(transport);
      addTearDown(sdk.close);

      final HealthSnapshot snapshot = await HealthRepositoryImpl(
        sdkClient: sdk,
        errorReporter: const NoopAppObservability(),
      ).check();

      expect(snapshot.isHealthy, isTrue);
      expect(snapshot.status, 'ok');
      expect(snapshot.checkedAt, isA<DateTime>());
    });

    test('maps SDK exceptions to host failures without losing support metadata', () async {
      final FakeSdkHttpTransport transport = FakeSdkHttpTransport()..enqueueJson('{}', statusCode: 401);
      final SdkClient sdk = _createClient(transport);
      addTearDown(sdk.close);

      expect(
        () => HealthRepositoryImpl(
          sdkClient: sdk,
          errorReporter: const NoopAppObservability(),
        ).check(),
        throwsA(
          isA<AppFailure>()
              .having((AppFailure error) => error.code, 'code', SdkErrorCodes.unauthorized)
              .having((AppFailure error) => error.isRetryable, 'retryability', isFalse)
              .having((AppFailure error) => error.requestId, 'request ID', isNotEmpty),
        ),
      );
    });

    test('reports one mapped SDK failure before rethrowing the host failure', () async {
      final FakeSdkHttpTransport transport = FakeSdkHttpTransport()..enqueueJson('{}', statusCode: 503);
      final SdkClient sdk = _createClient(transport);
      addTearDown(sdk.close);
      final _RecordingReporter reporter = _RecordingReporter();

      await expectLater(
        HealthRepositoryImpl(sdkClient: sdk, errorReporter: reporter).check(),
        throwsA(isA<AppFailure>()),
      );

      expect(reporter.failures, hasLength(1));
      expect(reporter.failures.single.failure.code, SdkErrorCodes.server);
      expect(reporter.failures.single.failure.statusCode, 503);
      expect(reporter.failures.single.kind, AppFailureReportKind.nonFatal);
    });
  });

  test('HealthSnapshot has value equality over its three domain fields', () {
    final DateTime checkedAt = DateTime.utc(2026, 9, 16, 12);
    final HealthSnapshot first = HealthSnapshot(isHealthy: true, status: 'ok', checkedAt: checkedAt);
    final HealthSnapshot second = HealthSnapshot(isHealthy: true, status: 'ok', checkedAt: checkedAt);

    expect(first, second);
    expect(first.hashCode, second.hashCode);
  });

  group('AppErrorCopy', () {
    final List<MapEntry<String, String>> knownCopies = <MapEntry<String, String>>[
      const MapEntry<String, String>(SdkErrorCodes.cancelled, 'The request was cancelled.'),
      const MapEntry<String, String>(SdkErrorCodes.timeout, 'That took too long. Check your connection.'),
      const MapEntry<String, String>(SdkErrorCodes.transport, 'We could not reach the service.'),
      const MapEntry<String, String>(SdkErrorCodes.unauthorized, 'Your API key was rejected.'),
      const MapEntry<String, String>(SdkErrorCodes.client, 'The request was not accepted.'),
      const MapEntry<String, String>(SdkErrorCodes.rateLimited, 'Too many requests — try again shortly.'),
      const MapEntry<String, String>(SdkErrorCodes.server, 'The service is having trouble. Try again.'),
      const MapEntry<String, String>(SdkErrorCodes.invalidResponse, 'The service returned an invalid response.'),
    ];

    for (final MapEntry<String, String> entry in knownCopies) {
      test('maps ${entry.key} to host-owned copy', () {
        final AppFailure failure = AppFailure(
          code: entry.key,
          isRetryable: false,
          requestId: 'request-1',
        );

        expect(AppErrorCopy.messageFor(failure), entry.value);
      });
    }

    test('uses a safe generic copy for unknown errors', () {
      expect(AppErrorCopy.messageFor(StateError('secret diagnostic')), 'Something went wrong. Please try again.');
    });

    test('uses a safe generic copy for an unknown AppFailure code', () {
      final AppFailure failure = AppFailure(
        code: 'future_code',
        isRetryable: true,
        requestId: 'request-1',
      );

      expect(AppErrorCopy.messageFor(failure), 'Something went wrong. Please try again.');
    });
  });

  group('HealthController', () {
    test('starts idle with a null data value', () {
      final ProviderContainer container = _containerWith(_SequenceHealthRepository());
      addTearDown(container.dispose);

      expect(container.read(healthControllerProvider), const AsyncData<HealthSnapshot?>(null));
    });

    test('transitions through loading to success', () async {
      final Completer<HealthSnapshot> completer = Completer<HealthSnapshot>();
      final DateTime checkedAt = DateTime.utc(2026, 9, 16, 12);
      final _SequenceHealthRepository repository = _SequenceHealthRepository(
        responses: <Future<HealthSnapshot> Function()>[
          () => completer.future,
        ],
      );
      final ProviderContainer container = _containerWith(repository);
      addTearDown(container.dispose);
      final HealthController controller = container.read(healthControllerProvider.notifier);

      final Future<void> check = controller.check();
      expect(container.read(healthControllerProvider), isA<AsyncLoading<HealthSnapshot?>>());

      completer.complete(HealthSnapshot(isHealthy: true, status: 'ok', checkedAt: checkedAt));
      await check;

      final AsyncValue<HealthSnapshot?> state = container.read(healthControllerProvider);
      expect(state, isA<AsyncData<HealthSnapshot?>>());
      expect(state.value, HealthSnapshot(isHealthy: true, status: 'ok', checkedAt: checkedAt));
    });

    test('transitions through loading to error and can retry successfully', () async {
      final DateTime checkedAt = DateTime.utc(2026, 9, 16, 12);
      final AppFailure failure = AppFailure(
        code: SdkErrorCodes.transport,
        isRetryable: true,
        requestId: 'request-1',
      );
      final _SequenceHealthRepository repository = _SequenceHealthRepository(
        responses: <Future<HealthSnapshot> Function()>[
          () => Future<HealthSnapshot>.error(failure),
          () async => HealthSnapshot(isHealthy: true, status: 'ok', checkedAt: checkedAt),
        ],
      );
      final ProviderContainer container = _containerWith(repository);
      addTearDown(container.dispose);
      final HealthController controller = container.read(healthControllerProvider.notifier);

      final Future<void> firstCheck = controller.check();
      expect(container.read(healthControllerProvider), isA<AsyncLoading<HealthSnapshot?>>());
      await firstCheck;

      final AsyncValue<HealthSnapshot?> errorState = container.read(healthControllerProvider);
      expect(errorState.hasError, isTrue);
      expect(errorState.error, same(failure));

      final Future<void> retry = controller.check();
      expect(container.read(healthControllerProvider), isA<AsyncLoading<HealthSnapshot?>>());
      await retry;

      expect(
        container.read(healthControllerProvider),
        AsyncData<HealthSnapshot?>(HealthSnapshot(isHealthy: true, status: 'ok', checkedAt: checkedAt)),
      );
    });
  });
}

SdkClient _createClient(FakeSdkHttpTransport transport) => SdkClient(
  config: SdkConfig(
    baseUri: Uri.parse('https://api.example.com'),
    apiKey: 'test-key',
  ),
  transport: transport,
);

ProviderContainer _containerWith(HealthRepository repository) => ProviderContainer(
  overrides: [
    healthRepositoryProvider.overrideWithValue(repository),
  ],
);

final class _RecordingReporter implements AppErrorReporter {
  final List<({AppFailure failure, AppFailureReportKind kind})> failures =
      <({AppFailure failure, AppFailureReportKind kind})>[];

  @override
  void reportFailure(AppFailure failure, AppFailureReportKind kind) => failures.add((failure: failure, kind: kind));

  @override
  void reportUnhandled(AppUnhandledError error) {}
}

final class _SequenceHealthRepository implements HealthRepository {
  _SequenceHealthRepository({List<Future<HealthSnapshot> Function()>? responses})
    : _responses = List<Future<HealthSnapshot> Function()>.from(responses ?? <Future<HealthSnapshot> Function()>[]);

  final List<Future<HealthSnapshot> Function()> _responses;

  @override
  Future<HealthSnapshot> check() => _responses.removeAt(0)();
}
