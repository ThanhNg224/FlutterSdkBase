import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sdk_base/core/theme/app_colors.dart';
import 'package:flutter_sdk_base/core/theme/app_spacing.dart';

/// Replaces Flutter's default red/grey box when a subtree fails to build.
///
/// Deliberately not localized and dependency-free: this is installed as
/// [ErrorWidget.builder], which receives no [BuildContext].
/// In debug mode the exception details are shown; release builds show a friendly panel.
class AppErrorWidget extends StatelessWidget {
  final FlutterErrorDetails details;

  const AppErrorWidget({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: AppColors.error.withValues(alpha: 0.04),
        child: Center(
          child: Padding(
            padding: AppSpacing.dialogPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 40, color: AppColors.error),
                const SizedBox(height: AppSpacing.m),
                const Text(
                  'Something went wrong',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    '${details.exception}',
                    textAlign: TextAlign.center,
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.errorOnLight),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
