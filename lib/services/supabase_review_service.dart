import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../models/review.dart';
import '../config/supabase_config.dart';

class SupabaseReviewService {
  static SupabaseClient get _client => SupabaseConfig.client;
  static const String _bucket = 'review-images';

  // Lấy danh sách bình luận cho một sản phẩm với filter theo sao
  static Future<List<Review>> getProductReviews(
    int productId, {
    int? ratingFilter,
  }) async {
    try {
      print(
        '[DEBUG] Getting reviews for product: $productId, filter: $ratingFilter',
      );

      var query = _client
          .from('reviews')
          .select('''
            *,
            users!inner(ten_nguoi_dung, avatar),
            review_images(*)
          ''')
          .eq('ma_san_pham', productId)
          .eq('trang_thai', 1) // ✅ chỉ lấy đánh giá đang hiển thị
          .filter('ma_danh_gia_cha', 'is', null); // chỉ lấy đánh giá cha

      // Lọc theo sao nếu có
      if (ratingFilter != null && ratingFilter > 0) {
        query = query.eq('diem_danh_gia', ratingFilter);
      }

      final reviewsResponse =
          await query.order('thoi_gian_tao', ascending: false);
      print('[DEBUG] Found ${reviewsResponse.length} parent reviews');

      final List<Review> result = [];
      for (final reviewData in reviewsResponse) {
        final parentReview = Review.fromJson(reviewData);

        // Lấy phản hồi con (reply)
        final repliesResponse = await _client
            .from('reviews')
            .select('''
              *,
              users!inner(ten_nguoi_dung, avatar),
              review_images(*)
            ''')
            .eq('ma_danh_gia_cha', parentReview.maDanhGia)
            .eq('trang_thai', 1) // ✅ chỉ lấy phản hồi hiển thị
            .order('thoi_gian_tao', ascending: true);

        final replies = repliesResponse
            .map((replyData) => Review.fromJson(replyData))
            .toList();

        result.add(
          Review(
            maDanhGia: parentReview.maDanhGia,
            maSanPham: parentReview.maSanPham,
            maNguoiDung: parentReview.maNguoiDung,
            tenNguoiDung: parentReview.tenNguoiDung,
            avatarNguoiDung: parentReview.avatarNguoiDung,
            diemDanhGia: parentReview.diemDanhGia,
            noiDungDanhGia: parentReview.noiDungDanhGia,
            ngayTao: parentReview.ngayTao,
            ngaySua: parentReview.ngaySua,
            trangThaiHienThi: parentReview.trangThaiHienThi,
            hinhAnh: parentReview.hinhAnh,
            maDanhGiaCha: parentReview.maDanhGiaCha,
            replies: replies,
          ),
        );
      }

      return result;
    } catch (e, stackTrace) {
      print('[DEBUG] Error getting product reviews: $e');
      print('[DEBUG] Stack trace: $stackTrace');
      return [];
    }
  }

  // Lấy thống kê đánh giá cho một sản phẩm
  static Future<Map<String, dynamic>> getProductReviewStats(
    int productId,
  ) async {
    try {
      final response = await _client
          .from('reviews')
          .select('diem_danh_gia')
          .eq('ma_san_pham', productId)
          .eq('trang_thai', 1) // ✅ chỉ tính review đang hiển thị
          .filter('ma_danh_gia_cha', 'is', null);

      if (response.isEmpty) {
        return {
          'averageRating': 0.0,
          'totalReviews': 0,
          'ratingDistribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        };
      }

      final ratings = response
          .map<int>((data) => (data['diem_danh_gia'] as num).toInt())
          .toList();
      final totalReviews = ratings.length;
      final averageRating = ratings.reduce((a, b) => a + b) / totalReviews;

      final ratingDistribution = <int, int>{};
      for (int i = 1; i <= 5; i++) {
        ratingDistribution[i] = ratings.where((r) => r == i).length;
      }

      return {
        'averageRating': averageRating,
        'totalReviews': totalReviews,
        'ratingDistribution': ratingDistribution,
      };
    } catch (e) {
      print('Error getting product review stats: $e');
      return {
        'averageRating': 0.0,
        'totalReviews': 0,
        'ratingDistribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      };
    }
  }

  // Thêm bình luận mới
  static Future<bool> addReview({
    required int productId,
    required int userId,
    required int rating,
    required String comment,
    List<XFile>? images,
    int? parentReviewId,
  }) async {
    try {
      print('[DEBUG] Adding review for product: $productId');
      print('[DEBUG] User: $userId');
      print('[DEBUG] Rating: $rating, Comment: $comment');
      print('[DEBUG] Images count: ${images?.length ?? 0}');

      final reviewData = <String, dynamic>{
        'ma_san_pham': productId,
        'ma_nguoi_dung': userId,
        'noi_dung_danh_gia': comment,
        'trang_thai': 1, // ✅ khi thêm mới, trạng thái mặc định = 1
        if (parentReviewId != null) 'ma_danh_gia_cha': parentReviewId,
      };

      if (parentReviewId == null) {
        reviewData['diem_danh_gia'] = rating;
      }

      final response =
          await _client.from('reviews').insert(reviewData).select();
      print('[DEBUG] Review insert response: $response');

      if (response.isNotEmpty && images != null && images.isNotEmpty) {
        final reviewId = response.first['ma_danh_gia'] as int;
        await _uploadReviewImages(reviewId, images);
      }

      return true;
    } catch (e, stackTrace) {
      print('[DEBUG] Error adding review: $e');
      print('[DEBUG] Stack trace: $stackTrace');
      return false;
    }
  }

  // Upload hình ảnh
  static Future<void> _uploadReviewImages(
    int reviewId,
    List<XFile> images,
  ) async {
    try {
      print('[DEBUG] Uploading ${images.length} images for review: $reviewId');

      for (int i = 0; i < images.length; i++) {
        final image = images[i];
        final fileName =
            'review_${reviewId}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final filePath = 'reviews/$fileName';

        final fileBytes = await image.readAsBytes();
        final uploadRes = await _client.storage.from(_bucket).uploadBinary(
              filePath,
              fileBytes,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: true,
              ),
            );
        print('[DEBUG] Storage upload result: $uploadRes');

        final imageUrl = _client.storage.from(_bucket).getPublicUrl(filePath);
        print('[DEBUG] Public URL: $imageUrl');

        final insertImg = await _client.from('review_images').insert({
          'ma_danh_gia': reviewId,
          'duong_dan_anh': imageUrl,
        }).select();
        print('[DEBUG] Image $i inserted: $insertImg');
      }
    } catch (e, stackTrace) {
      print('[DEBUG] Error uploading review images: $e');
      print('[DEBUG] Stack trace: $stackTrace');
    }
  }

  // Cập nhật bình luận
  static Future<bool> updateReview({
    required int reviewId,
    required int rating,
    required String comment,
  }) async {
    try {
      await _client
          .from('reviews')
          .update({
            'diem_danh_gia': rating,
            'noi_dung_danh_gia': comment,
            'ngay_sua': DateTime.now().toIso8601String(),
          })
          .eq('ma_danh_gia', reviewId);

      return true;
    } catch (e) {
      print('Error updating review: $e');
      return false;
    }
  }

  // Ẩn bình luận (xóa mềm)
  static Future<bool> deleteReview(int reviewId) async {
    try {
      await _client
          .from('reviews')
          .update({'trang_thai': 0}) // ✅ ẩn review
          .eq('ma_danh_gia', reviewId);

      return true;
    } catch (e) {
      print('Error deleting review: $e');
      return false;
    }
  }
}
