import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Provides the host scaffold and navigation for feature branches.
final class HostShell extends StatelessWidget {
  /// Creates the host shell around [navigationShell].
  const HostShell({required this.navigationShell, super.key});

  /// The stateful shell that owns each branch's navigation stack.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: navigationShell,
    bottomNavigationBar: NavigationBar(
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: navigationShell.goBranch,
      destinations: const <NavigationDestination>[
        NavigationDestination(icon: Icon(Icons.health_and_safety_outlined), label: 'Health'),
        NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
      ],
    ),
  );
}
