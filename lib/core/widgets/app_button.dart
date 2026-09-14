import 'package:flutter/material.dart';
import 'package:flutter_sdk_base/core/theme/app_colors.dart';
import 'package:flutter_sdk_base/core/theme/app_spacing.dart';

enum ButtonVariant { primary, secondary, outline, danger }

/// Reusable Design System Button with loading indicator support.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonVariant variant;
  final IconData? icon;
  final double? width;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;
    final foreground = switch (variant) {
      ButtonVariant.outline =>
        Theme.of(context).outlinedButtonTheme.style?.foregroundColor?.resolve(const {}) ?? AppColors.primaryDark,
      ButtonVariant.primary || ButtonVariant.danger => AppColors.onLightFill,
      ButtonVariant.secondary => Colors.white,
    };

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: foreground),
          ),
          const SizedBox(width: AppSpacing.s),
        ] else if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: AppSpacing.s),
        ],
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
    );

    final button = switch (variant) {
      ButtonVariant.primary => ElevatedButton(
        onPressed: effectiveOnPressed,
        style: _filledStyle(AppColors.primary, foreground),
        child: child,
      ),
      ButtonVariant.secondary => ElevatedButton(
        onPressed: effectiveOnPressed,
        style: _filledStyle(AppColors.secondary, foreground),
        child: child,
      ),
      ButtonVariant.danger => ElevatedButton(
        onPressed: effectiveOnPressed,
        style: _filledStyle(AppColors.error, foreground),
        child: child,
      ),
      ButtonVariant.outline => OutlinedButton(
        onPressed: effectiveOnPressed,
        style: isLoading
            ? OutlinedButton.styleFrom(
                disabledForegroundColor: foreground,
                side: BorderSide(color: foreground),
              )
            : null,
        child: child,
      ),
    };

    return width == null ? button : SizedBox(width: width, child: button);
  }

  ButtonStyle _filledStyle(Color background, Color foreground) {
    return ElevatedButton.styleFrom(
      backgroundColor: background,
      foregroundColor: foreground,
      disabledBackgroundColor: isLoading ? background : null,
      disabledForegroundColor: isLoading ? foreground : null,
    );
  }
}
