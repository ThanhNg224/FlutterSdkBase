import 'package:flutter/material.dart';
import 'package:flutter_sdk_base/core/extensions/context_extensions.dart';
import 'package:flutter_sdk_base/core/theme/app_semantic_colors.dart';
import 'package:flutter_sdk_base/core/theme/app_spacing.dart';
import 'package:flutter_sdk_base/core/widgets/app_button.dart';

/// Modal dialog helper for displaying success, error, or confirmation.
abstract class AppDialog {
  static Future<void> showResultDialog({
    required BuildContext context,
    required String title,
    required String message,
    bool isSuccess = true,
    Widget? extraContent,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) {
        final textTheme = Theme.of(ctx).textTheme;
        final accent = isSuccess ? ctx.colors.statusSuccess : ctx.colors.statusError;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusL)),
          contentPadding: AppSpacing.dialogPadding,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _IconBadge(icon: isSuccess ? Icons.check_circle_rounded : Icons.error_rounded, color: accent),
              const SizedBox(height: AppSpacing.m),
              Text(title, style: textTheme.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.s),
              Text(message, style: textTheme.bodyMedium, textAlign: TextAlign.center),
              if (extraContent != null) ...[
                const SizedBox(height: AppSpacing.m),
                extraContent,
              ],
              const SizedBox(height: AppSpacing.l),
              AppButton(
                label: ctx.l10n.closeButton,
                width: double.infinity,
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<void> showActionDialog({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String message,
    required String primaryLabel,
    required VoidCallback onPrimary,
    required String secondaryLabel,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) {
        final textTheme = Theme.of(ctx).textTheme;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusL)),
          contentPadding: AppSpacing.dialogPadding,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _IconBadge(icon: icon, color: ctx.colors.statusWarning),
              const SizedBox(height: AppSpacing.m),
              Text(title, style: textTheme.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.s),
              Text(message, style: textTheme.bodyMedium, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.l),
              AppButton(
                label: primaryLabel,
                width: double.infinity,
                onPressed: () {
                  Navigator.of(ctx).pop();
                  onPrimary();
                },
              ),
              const SizedBox(height: AppSpacing.s),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(secondaryLabel),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 36),
    );
  }
}
