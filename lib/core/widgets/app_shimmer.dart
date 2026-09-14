import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_sdk_base/core/theme/app_semantic_colors.dart';
import 'package:flutter_sdk_base/core/theme/app_spacing.dart';

class AppShimmer extends StatelessWidget {
  const AppShimmer({super.key, required this.height, this.width, this.borderRadius = AppSpacing.radiusM});

  final double height;
  final double? width;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.colors.track,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    ).animate(onPlay: (controller) => controller.repeat()).shimmer(duration: 1200.ms, color: context.colors.surface);
  }
}

class AppShimmerList extends StatelessWidget {
  const AppShimmerList({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: AppSpacing.pagePadding,
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.m),
      itemBuilder: (_, _) => Row(
        children: [
          const AppShimmer(height: AppSpacing.xxl, width: AppSpacing.xxl),
          const SizedBox(width: AppSpacing.m),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppShimmer(height: AppSpacing.m),
                SizedBox(height: AppSpacing.s),
                AppShimmer(height: AppSpacing.s),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
