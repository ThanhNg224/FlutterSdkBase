import 'package:flutter_sdk_base/flutter_sdk_base.dart';
import 'package:flutter_sdk_base_example/core/error/app_failure.dart';
import 'package:flutter_sdk_base_example/core/observability/app_observability.dart';
import 'package:flutter_sdk_base_example/features/health/domain/health_repository.dart';
import 'package:flutter_sdk_base_example/features/health/domain/models/health_snapshot.dart';

/// Adapts the public SDK health capability to the host domain.
final class HealthRepositoryImpl implements HealthRepository {
  /// Creates a repository backed by [sdkClient].
  HealthRepositoryImpl({required SdkClient sdkClient, required AppErrorReporter errorReporter})
    : this._(sdkClient, errorReporter);

  HealthRepositoryImpl._(this._sdkClient, this._errorReporter);

  final SdkClient _sdkClient;
  final AppErrorReporter _errorReporter;

  @override
  Future<HealthSnapshot> check() async {
    try {
      final SdkHealth health = await _sdkClient.health.check();
      return HealthSnapshot(
        isHealthy: health.isHealthy,
        status: health.status,
        checkedAt: health.checkedAt,
      );
    } on SdkException catch (error) {
      final AppFailure failure = AppFailure.fromSdkException(error);
      try {
        reportAppFailure(_errorReporter, failure);
      } on Object {
        // A reporting adapter cannot replace the host domain failure.
      }
      throw failure;
    }
  }
}
