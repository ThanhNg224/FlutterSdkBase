import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_sdk_base_example/app/providers/app_providers.dart';
import 'package:flutter_sdk_base_example/features/health/data/health_repository_impl.dart';
import 'package:flutter_sdk_base_example/features/health/domain/health_repository.dart';

part 'health_repository_provider.g.dart';

/// Provides the Health domain repository backed by the app SDK client.
@riverpod
HealthRepository healthRepository(Ref ref) => HealthRepositoryImpl(
  sdkClient: ref.watch(sdkClientProvider),
  errorReporter: ref.watch(appErrorReporterProvider),
);
