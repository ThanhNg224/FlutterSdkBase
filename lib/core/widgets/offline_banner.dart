import 'package:flutter/material.dart';
import 'package:flutter_sdk_base/core/extensions/context_extensions.dart';
import 'package:flutter_sdk_base/core/network/connectivity_provider.dart';
import 'package:flutter_sdk_base/core/theme/app_semantic_colors.dart';
import 'package:flutter_sdk_base/core/theme/app_spacing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref
        .watch(isOnlineProvider)
        .when(data: (value) => value, error: (_, _) => true, loading: () => true);
    if (isOnline) return const SizedBox.shrink();

    return SafeArea(
      bottom: false,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(AppSpacing.s),
        padding: const EdgeInsets.all(AppSpacing.s),
        decoration: BoxDecoration(
          color: context.colors.statusWarning.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(AppSpacing.radiusM),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, color: context.colors.statusWarning),
            const SizedBox(width: AppSpacing.s),
            Expanded(child: Text(context.l10n.offlineBannerMessage)),
          ],
        ),
      ),
    );
  }
}
