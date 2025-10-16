import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/app_colors.dart';
import 'app_card.dart';

class LoadingWidget extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const LoadingWidget({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.lightGray,
      highlightColor: AppColors.mediumGray,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.lightGray,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LoadingWidget(
            width: double.infinity,
            height: 200,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 12),
          LoadingWidget(
            width: double.infinity,
            height: 16,
          ),
          const SizedBox(height: 8),
          LoadingWidget(
            width: 100,
            height: 14,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              LoadingWidget(
                width: 80,
                height: 12,
              ),
              const Spacer(),
              LoadingWidget(
                width: 60,
                height: 12,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ListSkeleton extends StatelessWidget {
  final int itemCount;

  const ListSkeleton({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: LoadingWidget(
            width: double.infinity,
            height: 80,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      },
    );
  }
}
