import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_sdk_base/core/config/app_config_controller.dart';
import 'package:flutter_sdk_base/core/constants/app_constants.dart';
import 'package:flutter_sdk_base/core/extensions/context_extensions.dart';
import 'package:flutter_sdk_base/core/routing/route_paths.dart';
import 'package:flutter_sdk_base/core/theme/app_colors.dart';
import 'package:flutter_sdk_base/core/theme/app_semantic_colors.dart';
import 'package:flutter_sdk_base/core/theme/app_spacing.dart';
import 'package:flutter_sdk_base/core/theme/app_typography.dart';
import 'package:flutter_sdk_base/core/widgets/app_button.dart';
import 'package:flutter_sdk_base/core/widgets/app_card.dart';

/// Clean starter home screen for Flutter SDK Base.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configState = ref.watch(appConfigControllerProvider);
    final envName = configState.value?.environment.name.toUpperCase() ?? '';
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settingsTooltip,
            onPressed: () => context.push(RoutePaths.settings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.s),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.rocket_launch_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.m),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppConstants.appName,
                              style: AppTypography.titleLarge,
                            ),
                            if (envName.isNotEmpty)
                              Text(
                                envName,
                                style: AppTypography.labelMedium.copyWith(
                                  color: context.colors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.m),
                  Text(
                    'Starter base initialized successfully. Build new feature modules inside lib/features/.',
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.l),
                  AppButton(
                    label: l10n.developerSdkSettingsTitle,
                    icon: Icons.settings_outlined,
                    onPressed: () => context.push(RoutePaths.settings),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
