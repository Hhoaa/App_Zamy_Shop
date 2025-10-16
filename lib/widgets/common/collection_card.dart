import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_colors.dart';
import '../../models/collection.dart';

class CollectionCard extends StatelessWidget {
  final Collection collection;
  final VoidCallback onTap;
  final double? width; // Thêm tham số width

  const CollectionCard({
    super.key,
    required this.collection,
    required this.onTap,
    this.width = 280, // Giá trị mặc định
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width, // Đặt width cố định
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool hasBoundedHeight = constraints.hasBoundedHeight;

              Widget imageWidget = ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: collection.hinhAnh.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: collection.hinhAnh.first,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppColors.accentRed.withOpacity(0.1),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.accentRed.withOpacity(0.1),
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              size: 40,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        color: AppColors.accentRed.withOpacity(0.1),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.collections,
                                size: 40,
                                color: AppColors.textSecondary,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Không có hình ảnh',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              );

              // Nếu có chiều cao giới hạn (ví dụ trong thẻ cao cố định), giới hạn chiều cao ảnh để tránh tràn
              if (hasBoundedHeight) {
                imageWidget = SizedBox(
                  height: constraints.maxHeight * 0.6, // 60% chiều cao cho ảnh
                  child: imageWidget,
                );
              } else {
                // Nếu không có giới hạn chiều cao (trong ListView), dùng tỷ lệ để co giãn tự nhiên
                imageWidget = AspectRatio(
                  aspectRatio: 16 / 9,
                  child: imageWidget,
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: hasBoundedHeight ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  // Hình ảnh bộ sưu tập
                  imageWidget,

                  // Thông tin bộ sưu tập
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          collection.tenBoSuuTap,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (collection.moTa != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            collection.moTa!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}