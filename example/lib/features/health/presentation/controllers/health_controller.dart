import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_sdk_base_example/features/health/data/health_repository_provider.dart';
import 'package:flutter_sdk_base_example/features/health/domain/models/health_snapshot.dart';

part 'health_controller.g.dart';

/// Owns the asynchronous state of the Health feature.
@riverpod
class HealthController extends _$HealthController {
  @override
  FutureOr<HealthSnapshot?> build() {
    ref.watch(healthRepositoryProvider);
    return null;
  }

  /// Checks health and exposes loading, data, or error state to the UI.
  Future<void> check() async {
    state = const AsyncLoading<HealthSnapshot?>();
    try {
      final HealthSnapshot snapshot = await ref.read(healthRepositoryProvider).check();
      if (ref.mounted) {
        state = AsyncData<HealthSnapshot?>(snapshot);
      }
    } catch (error, stackTrace) {
      if (ref.mounted) {
        state = AsyncError<HealthSnapshot?>(error, stackTrace);
      }
    }
  }
}
