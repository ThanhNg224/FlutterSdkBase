import 'package:flutter/material.dart';
import 'package:flutter_sdk_base/core/errors/failure.dart';
import 'package:flutter_sdk_base/core/errors/failure_l10n.dart';
import 'package:flutter_sdk_base/core/extensions/context_extensions.dart';
import 'package:flutter_sdk_base/core/logging/logging.dart';
import 'package:flutter_sdk_base/core/theme/app_colors.dart';
import 'package:flutter_sdk_base/core/theme/app_spacing.dart';
import 'package:flutter_sdk_base/core/theme/app_typography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _log = AppLogger('AsyncValueWidget');

/// Reusable helper to render [AsyncValue] cleanly with loading, error, and data states
class AsyncValueWidget<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget Function(Object error, StackTrace stackTrace)? error;
  final Widget Function()? loading;

  const AsyncValueWidget({
    super.key,
    required this.value,
    required this.data,
    this.error,
    this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      error:
          error ??
          (err, st) {
            final message = switch (err) {
              Failure() => err.localizedMessage(context.l10n),
              _ => context.l10n.somethingWentWrongMessage,
            };
            if (err is! Failure) {
              _log.error('unexpected AsyncValue error', data: {'errorType': Redacted.type(err)});
            }

            return Center(
              child: Padding(
                padding: AppSpacing.pagePadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                    const SizedBox(height: AppSpacing.m),
                    Text(
                      context.l10n.somethingWentWrongMessage,
                      style: AppTypography.titleMedium.copyWith(color: AppColors.error),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Text(
                      message,
                      style: AppTypography.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
      loading:
          loading ??
          () => const Center(
            child: CircularProgressIndicator(),
          ),
    );
  }
}
