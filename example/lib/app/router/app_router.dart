import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_sdk_base_example/app/router/app_route_names.dart';
import 'package:flutter_sdk_base_example/app/widgets/host_shell.dart';
import 'package:flutter_sdk_base_example/features/health/presentation/pages/health_page.dart';
import 'package:flutter_sdk_base_example/features/settings/presentation/pages/settings_page.dart';

part 'app_router.g.dart';

/// Provides the host router and its stateful feature branches.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) => GoRouter(
  initialLocation: AppRouteNames.health,
  routes: <RouteBase>[
    GoRoute(path: '/', redirect: (BuildContext context, GoRouterState state) => AppRouteNames.health),
    StatefulShellRoute.indexedStack(
      builder: (BuildContext context, GoRouterState state, StatefulNavigationShell navigationShell) =>
          HostShell(navigationShell: navigationShell),
      branches: <StatefulShellBranch>[
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: AppRouteNames.health,
              builder: (BuildContext context, GoRouterState state) => const HealthPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: AppRouteNames.settings,
              builder: (BuildContext context, GoRouterState state) => const SettingsPage(),
            ),
          ],
        ),
      ],
    ),
  ],
);
