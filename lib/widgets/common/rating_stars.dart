import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../theme/app_colors.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final double itemSize;
  final bool readOnly;
  final void Function(double)? onRatingUpdate;
  final Color? color;

  const RatingStars({
    super.key,
    required this.rating,
    this.itemSize = 20,
    this.readOnly = true,
    this.onRatingUpdate,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (readOnly) {
      // Non-interactive display
      return RatingBarIndicator(
        rating: rating,
        itemCount: 5,
        itemSize: itemSize,
        itemBuilder: (context, _) => Icon(
          Icons.star,
          color: color ?? AppColors.goldYellow,
        ),
      );
    }
    // Interactive mode
    return RatingBar.builder(
      initialRating: rating,
      minRating: 0,
      direction: Axis.horizontal,
      allowHalfRating: true,
      itemCount: 5,
      itemSize: itemSize,
      itemPadding: const EdgeInsets.symmetric(horizontal: 2),
      itemBuilder: (context, _) => Icon(
        Icons.star,
        color: color ?? AppColors.goldYellow,
      ),
      onRatingUpdate: (newRating) {
        onRatingUpdate?.call(newRating);
      },
    );
  }
}

class RatingDisplay extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final double itemSize;
  final bool showCount;

  const RatingDisplay({
    super.key,
    required this.rating,
    this.reviewCount = 0,
    this.itemSize = 16,
    this.showCount = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        RatingStars(
          rating: rating,
          itemSize: itemSize,
        ),
        if (showCount) ...[
          const SizedBox(width: 8),
          Text(
            '($reviewCount)',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
