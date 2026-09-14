import 'package:flutter/material.dart';
import 'package:flutter_sdk_base/core/extensions/context_extensions.dart';
import 'package:flutter_sdk_base/core/theme/app_semantic_colors.dart';
import 'package:flutter_sdk_base/core/theme/app_spacing.dart';

/// Centralized modal bottom sheet: rounded top corners, drag handle, an
/// optional icon/title header with a close action, and keyboard-safe
/// padding — so every sheet in the app looks and behaves the same way.
abstract class AppBottomSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    String? title,
    IconData? icon,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXL)),
      ),
      builder: (sheetContext) => _SheetChrome(title: title, icon: icon, child: builder(sheetContext)),
    );
  }
}

class _SheetChrome extends StatelessWidget {
  const _SheetChrome({required this.title, required this.icon, required this.child});

  final String? title;
  final IconData? icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _DragHandle(),
              const SizedBox(height: AppSpacing.m),
              if (title != null) ...[
                _SheetHeader(title: title!, icon: icon),
                const SizedBox(height: AppSpacing.m),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: AppSpacing.xl,
        height: AppSpacing.xs,
        decoration: BoxDecoration(
          color: context.colors.border,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.title, required this.icon});

  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 22, color: context.colors.brandAccent),
          const SizedBox(width: AppSpacing.s),
        ],
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: context.l10n.closeButton,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
