import 'package:flutter_sdk_base_example/features/health/domain/models/health_snapshot.dart';

/// Reads health data for the host application.
abstract interface class HealthRepository {
  /// Checks the service health.
  Future<HealthSnapshot> check();
}
