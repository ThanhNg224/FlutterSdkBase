import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sdk_base_example/features/settings/presentation/settings_view_data.dart';
import 'package:flutter_sdk_base_example/features/settings/presentation/widgets/diagnostic_tile.dart';

/// Displays read-only diagnostics for the configured demo host.
final class SettingsPage extends ConsumerWidget {
  /// Creates the Settings page.
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SettingsViewData diagnostics = ref.watch(settingsViewDataProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: <Widget>[
            const Text('Host diagnostics'),
            const SizedBox(height: 16),
            DiagnosticTile(label: 'Environment', value: diagnostics.environmentName),
            DiagnosticTile(label: 'API base URL', value: diagnostics.apiBaseUrl),
            DiagnosticTile(label: 'SDK version', value: diagnostics.sdkVersion),
            DiagnosticTile(label: 'Transport', value: diagnostics.transportDescription),
          ],
        ),
      ),
    );
  }
}
