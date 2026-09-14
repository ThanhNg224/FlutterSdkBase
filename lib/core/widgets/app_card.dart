import 'package:flutter/material.dart';
import 'package:flutter_sdk_base/core/theme/app_spacing.dart';

/// Reusable container card for the design system.
/// Takes its styling from `cardTheme`.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final BoxBorder? border;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final cardTheme = Theme.of(context).cardTheme;
    final shape = cardTheme.shape;
    final borderRadius = shape is RoundedRectangleBorder && shape.borderRadius is BorderRadius
        ? shape.borderRadius as BorderRadius
        : BorderRadius.circular(AppSpacing.radiusL);
    final themeSide = shape is RoundedRectangleBorder ? shape.side : BorderSide.none;

    final content = Container(
      padding: padding ?? AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: color ?? cardTheme.color,
        borderRadius: borderRadius,
        border: border ?? (themeSide == BorderSide.none ? null : Border.fromBorderSide(themeSide)),
      ),
      child: child,
    );

    if (onTap == null) return content;

    return InkWell(
      onTap: onTap,
      borderRadius: borderRadius,
      child: content,
    );
  }
}
