import 'package:flutter/material.dart';
import 'package:flutter_sdk_base/core/theme/app_semantic_colors.dart';
import 'package:flutter_sdk_base/core/theme/app_spacing.dart';

abstract class AppSnackbar {
  static void showSuccess(BuildContext context, String message) {
    _show(context, message: message, icon: Icons.check_circle_rounded, accentColor: context.colors.statusSuccess);
  }

  static void showError(BuildContext context, String message) {
    _show(context, message: message, icon: Icons.error_rounded, accentColor: context.colors.statusError);
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message: message, icon: Icons.info_rounded, accentColor: context.colors.brandAccent);
  }

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color accentColor,
  }) {
    final textTheme = Theme.of(context).textTheme;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: context.colors.surface,
          margin: const EdgeInsets.all(AppSpacing.m),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusM),
            side: BorderSide(color: accentColor),
          ),
          content: Row(
            children: [
              Icon(icon, color: accentColor),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: Text(
                  message,
                  style: textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      );
  }
}
