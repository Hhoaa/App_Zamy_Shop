import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../theme/app_colors.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../models/review.dart';
import '../../services/supabase_review_service.dart';
import '../../services/supabase_auth_service.dart';
import '../../widgets/common/app_button.dart';

class ReviewScreen extends StatefulWidget {
  final Order order;
  final Review? parentReview; // For reply functionality

  const ReviewScreen({
    super.key, 
    required this.order,
    this.parentReview,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final Map<int, int> _ratings = {};
  final Map<int, TextEditingController> _commentControllers = {};
  final Map<int, List<XFile>> _selectedImages = {};
  final ImagePicker _imagePicker = ImagePicker();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers for each product
    for (final item in widget.order.orderItems) {
      if (item.product != null) {
        final productId = item.product!.maSanPham;
        _commentControllers[productId] = TextEditingController();
        _ratings[productId] = 5; // Default rating
        _selectedImages[productId] = []; // Initialize empty image list
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _commentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImages(int productId) async {
    try {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Chụp từ camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Chọn từ thư viện'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
      if (source == null) return;

      if (source == ImageSource.camera) {
        final XFile? captured = await _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 80);
        if (captured != null) {
          setState(() {
            _selectedImages[productId] = [..._selectedImages[productId] ?? [], captured];
          });
        }
      } else {
        final List<XFile> images = await _imagePicker.pickMultiImage(
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 80,
        );
        if (images.isNotEmpty) {
          setState(() {
            _selectedImages[productId] = images;
          });
        }
      }
    } catch (e) {
      print('Error picking images: $e');
      _showErrorSnackBar('Lỗi khi chọn hình ảnh');
    }
  }

  void _removeImage(int productId, int index) {
    setState(() {
      _selectedImages[productId]!.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        ),
        title: const Text(
          'Đánh giá sản phẩm',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đơn hàng #${widget.order.maDonHang}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ngày đặt: ${_formatDate(widget.order.ngayDatHang)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Review items
            const Text(
              'Đánh giá sản phẩm',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            
            ...widget.order.orderItems.map((item) => _buildReviewItem(item)),
            
            const SizedBox(height: 32),
            
            // Submit button
            AppButton(
              text: _isSubmitting ? 'Đang gửi...' : 'GỬI ĐÁNH GIÁ',
              type: AppButtonType.accent,
              size: AppButtonSize.large,
              onPressed: _isSubmitting ? null : _submitReviews,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItem(OrderDetail item) {
    if (item.product == null) return const SizedBox.shrink();
    
    final product = item.product!;
    final productId = product.maSanPham;
    final rating = _ratings[productId] ?? 5;
    final controller = _commentControllers[productId]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product info
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: product.hinhAnhDauTien != null
                      ? Image.network(
                          product.hinhAnhDauTien!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.image,
                              color: AppColors.mediumGray,
                              size: 30,
                            );
                          },
                        )
                      : const Icon(
                          Icons.image,
                          color: AppColors.mediumGray,
                          size: 30,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.tenSanPham,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Size: ${item.size ?? 'N/A'} | Màu: ${item.mauSac ?? 'N/A'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Rating
          const Text(
            'Đánh giá:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _ratings[productId] = index + 1;
                  });
                },
                child: Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 32,
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          
          // Comment
          const Text(
            'Nhận xét:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Chia sẻ trải nghiệm của bạn về sản phẩm...',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          
          // Image selection
          const Text(
            'Hình ảnh (tùy chọn):',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          
          // Selected images
          if (_selectedImages[productId]!.isNotEmpty)
            Container(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages[productId]!.length,
                itemBuilder: (context, index) {
                  final image = _selectedImages[productId]![index];
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(image.path),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeImage(productId, index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          
          // Add image button
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _pickImages(productId),
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.borderLight, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(8),
                color: AppColors.background,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate, color: AppColors.textSecondary),
                  SizedBox(width: 8),
                  Text(
                    'Thêm hình ảnh',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReviews() async {
    setState(() => _isSubmitting = true);

    try {
      final user = await SupabaseAuthService.getCurrentUser();
      if (user == null) {
        _showErrorSnackBar('Vui lòng đăng nhập để đánh giá');
        return;
      }

      bool allSuccess = true;
      
      for (final item in widget.order.orderItems) {
        if (item.product == null) continue;
        
        final productId = item.product!.maSanPham;
        final rating = _ratings[productId] ?? 5;
        final comment = _commentControllers[productId]!.text.trim();
        
        final success = await SupabaseReviewService.addReview(
          productId: productId,
          userId: user.maNguoiDung,
          rating: rating,
          comment: comment.isEmpty ? 'Không có nhận xét' : comment,
          images: _selectedImages[productId]!.isNotEmpty ? _selectedImages[productId] : null,
        );
        
        if (!success) {
          allSuccess = false;
        }
      }

      if (allSuccess) {
        _showSuccessSnackBar('Cảm ơn bạn đã đánh giá!');
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        _showErrorSnackBar('Có lỗi xảy ra khi gửi đánh giá');
      }
    } catch (e) {
      _showErrorSnackBar('Lỗi: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
