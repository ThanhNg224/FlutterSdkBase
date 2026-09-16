import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sdk_base_example/app/router/app_router.dart';
import 'package:flutter_sdk_base_example/core/theme/app_theme.dart';

/// The root widget for the reference host application.
final class HostApp extends ConsumerWidget {
  /// Creates the host application.
  const HostApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'flutter_sdk_base example',
    theme: AppTheme.light,
    routerConfig: ref.watch(appRouterProvider),
  );
}
