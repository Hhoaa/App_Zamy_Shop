import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_colors.dart';
import '../../models/review.dart';
import '../../models/review_image.dart';

class ReviewItemWidget extends StatelessWidget {
  final Review review;
  final VoidCallback? onReply;
  final bool isReply;
  final int replyLevel;

  const ReviewItemWidget({
    super.key, 
    required this.review,
    this.onReply,
    this.isReply = false,
    this.replyLevel = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        bottom: 12,
        left: isReply ? 16.0 + (replyLevel * 16.0) : 0,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isReply ? const Color(0xFFFAFAFA) : Colors.white,
        borderRadius: BorderRadius.circular(0),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFEEEEEE),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFE0E0E0),
                backgroundImage: review.avatarNguoiDung != null && review.avatarNguoiDung!.isNotEmpty
                    ? CachedNetworkImageProvider(review.avatarNguoiDung!)
                    : null,
                child: review.avatarNguoiDung == null || review.avatarNguoiDung!.isEmpty
                    ? Text(
                        review.displayName.isNotEmpty 
                            ? review.displayName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.displayName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Rating stars for parent reviews
                    if (!isReply) 
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < review.diemDanhGia 
                                ? Icons.star 
                                : Icons.star_border,
                            color: const Color(0xFFEE4D2D),
                            size: 14,
                          );
                        }),
                      ),
                  ],
                ),
              ),
              // Date
              Text(
                _formatDate(review.ngayTao),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF999999),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Review content
          Text(
            review.noiDungDanhGia,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF222222),
              height: 1.5,
            ),
          ),
          
          // Review images
          if (review.hinhAnh != null && review.hinhAnh!.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: review.hinhAnh!.length,
                itemBuilder: (context, index) {
                  final image = review.hinhAnh![index];
                  return GestureDetector(
                    onTap: () => _showImageDialog(context, image.duongDanAnh),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFEEEEEE)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: CachedNetworkImage(
                          imageUrl: image.duongDanAnh,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: const Color(0xFFF5F5F5),
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEE4D2D)),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.image_outlined,
                            color: Color(0xFFCCCCCC),
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          // Reply button
          if (!isReply && onReply != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onReply,
              icon: const Icon(
                Icons.chat_bubble_outline,
                size: 16,
                color: Color(0xFF555555),
              ),
              label: const Text(
                'Phản hồi',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF555555),
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],

          // Replies section
          if (review.replies != null && review.replies!.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...review.replies!.map((reply) => ReviewItemWidget(
              review: reply,
              isReply: true,
              replyLevel: replyLevel + 1,
            )),
          ],
        ],
      ),
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  errorWidget: (context, url, error) {
                    return Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Không thể tải hình ảnh',
                            style: TextStyle(color: Colors.black87),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }
}