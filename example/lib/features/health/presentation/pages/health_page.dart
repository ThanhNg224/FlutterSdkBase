import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sdk_base_example/features/health/presentation/controllers/health_controller.dart';
import 'package:flutter_sdk_base_example/features/health/domain/models/health_snapshot.dart';
import 'package:flutter_sdk_base_example/features/health/presentation/widgets/health_status_card.dart';

/// Displays the Health feature and delegates work to its controller.
final class HealthPage extends ConsumerWidget {
  /// Creates the Health page.
  const HealthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<HealthSnapshot?> state = ref.watch(healthControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('SDK health')),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                HealthStatusCard(state: state),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: state.isLoading ? null : () => ref.read(healthControllerProvider.notifier).check(),
                  child: const Text('Check health'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
