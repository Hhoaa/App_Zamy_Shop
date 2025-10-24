import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../models/review.dart';
import '../config/supabase_config.dart';

class SupabaseReviewService {
  static SupabaseClient get _client => SupabaseConfig.client;
  static const String _bucket = 'review-images';

  // =============================
  // LẤY DANH SÁCH BÌNH LUẬN THEO SẢN PHẨM
  // =============================
  static Future<List<Review>> getProductReviews(
    int productId, {
    int? ratingFilter,
  }) async {
    try {
      print('[DEBUG] Getting reviews for product: $productId, filter: $ratingFilter');

      var query = _client
          .from('reviews')
          .select('''
            *,
            users!inner(ten_nguoi_dung, avatar),
            review_images(*)
          ''')
          .eq('ma_san_pham', productId)
          .eq('trang_thai', 1)
          .filter('ma_danh_gia_cha', 'is', null);

      // Lọc theo số sao nếu có
      if (ratingFilter != null && ratingFilter > 0) {
        query = query.eq('diem_danh_gia', ratingFilter);
      }

      final reviewsResponse = await query.order('thoi_gian_tao', ascending: false);
      print('[DEBUG] Found ${reviewsResponse.length} parent reviews');

      final List<Review> result = [];

      for (final reviewData in reviewsResponse) {
        final parentReview = Review.fromJson(reviewData);

        // Lấy phản hồi (reply)
        final repliesResponse = await _client
            .from('reviews')
            .select('''
              *,
              users!inner(ten_nguoi_dung, avatar),
              review_images(*)
            ''')
            .eq('ma_danh_gia_cha', parentReview.maDanhGia)
            .eq('trang_thai', 1)
            .order('thoi_gian_tao', ascending: true);

        final replies =
            repliesResponse.map((replyData) => Review.fromJson(replyData)).toList();

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

  // =============================
  // LẤY THỐNG KÊ ĐÁNH GIÁ SẢN PHẨM (TÍNH CẢ ĐÁNH GIÁ CON)
  // =============================
  static Future<Map<String, dynamic>> getProductReviewStats(int productId) async {
    try {
      // Lấy tất cả review có trạng_thai = 1
      final allReviews = await _client
          .from('reviews')
          .select('diem_danh_gia, trang_thai, ma_danh_gia_cha')
          .eq('ma_san_pham', productId)
          .eq('trang_thai', 1);

      if (allReviews.isEmpty) {
        return {
          'averageRating': 0.0,
          'totalReviews': 0,
          'ratingDistribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        };
      }

      // Lọc riêng đánh giá cha để tính sao trung bình
      final parentReviews =
          allReviews.where((r) => r['ma_danh_gia_cha'] == null).toList();

      // Tổng tất cả review (cha + con)
      final totalReviews = allReviews.length;

      // Nếu không có đánh giá cha thì trung bình = 0
      if (parentReviews.isEmpty) {
        return {
          'averageRating': 0.0,
          'totalReviews': totalReviews,
          'ratingDistribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        };
      }

      final ratings = parentReviews
          .map<int>((data) => (data['diem_danh_gia'] as num).toInt())
          .toList();

      final averageRating =
          ratings.isNotEmpty ? ratings.reduce((a, b) => a + b) / ratings.length : 0.0;

      final ratingDistribution = <int, int>{};
      for (int i = 1; i <= 5; i++) {
        ratingDistribution[i] = ratings.where((r) => r == i).length;
      }

      return {
        'averageRating': averageRating,
        'totalReviews': totalReviews, // Đếm cả bình luận con
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

  // =============================
  // THÊM BÌNH LUẬN MỚI
  // =============================
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
        'trang_thai': 1,
        if (parentReviewId != null) 'ma_danh_gia_cha': parentReviewId,
      };

      if (parentReviewId == null) {
        reviewData['diem_danh_gia'] = rating;
      }

      final response = await _client.from('reviews').insert(reviewData).select();
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

  // =============================
  // UPLOAD HÌNH ẢNH REVIEW
  // =============================
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

  // =============================
  // CẬP NHẬT BÌNH LUẬN
  // =============================
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

  // =============================
  // ẨN (XOÁ MỀM) BÌNH LUẬN
  // =============================
  static Future<bool> deleteReview(int reviewId) async {
    try {
      await _client
          .from('reviews')
          .update({'trang_thai': 0})
          .eq('ma_danh_gia', reviewId);

      return true;
    } catch (e) {
      print('Error deleting review: $e');
      return false;
    }
  }
}
