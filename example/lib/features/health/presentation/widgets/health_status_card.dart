import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sdk_base_example/core/error/app_error_copy.dart';
import 'package:flutter_sdk_base_example/features/health/domain/models/health_snapshot.dart';

/// Renders the current Health request state without owning feature state.
final class HealthStatusCard extends StatelessWidget {
  /// Creates a status card for [state].
  const HealthStatusCard({required this.state, super.key});

  /// The controller state to render.
  final AsyncValue<HealthSnapshot?> state;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: state.when(
        data: (HealthSnapshot? snapshot) {
          if (snapshot == null) {
            return const Text('Tap check to call the SDK.');
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(snapshot.isHealthy ? 'Healthy' : 'Unhealthy'),
              Text('Status: ${snapshot.status}'),
              Text('Checked at: ${snapshot.checkedAt}'),
            ],
          );
        },
        error: (Object error, StackTrace stackTrace) => Text(AppErrorCopy.messageFor(error)),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    ),
  );
}
