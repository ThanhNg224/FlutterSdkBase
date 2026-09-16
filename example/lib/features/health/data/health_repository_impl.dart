import 'package:flutter_sdk_base/flutter_sdk_base.dart';
import 'package:flutter_sdk_base_example/core/error/app_failure.dart';
import 'package:flutter_sdk_base_example/features/health/domain/health_repository.dart';
import 'package:flutter_sdk_base_example/features/health/domain/models/health_snapshot.dart';

/// Adapts the public SDK health capability to the host domain.
final class HealthRepositoryImpl implements HealthRepository {
  /// Creates a repository backed by [sdkClient].
  HealthRepositoryImpl({required SdkClient sdkClient}) : this._(sdkClient);

  HealthRepositoryImpl._(this._sdkClient);

  final SdkClient _sdkClient;

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
      throw AppFailure.fromSdkException(error);
    }
  }
}
