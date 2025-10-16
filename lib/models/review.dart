import 'review_image.dart';

class Review {
  final int maDanhGia;  // ĐỔI String -> int
  final int maSanPham;  // ĐỔI String -> int
  final int maNguoiDung;  // ĐỔI String -> int
  final String tenNguoiDung;
  final String? avatarNguoiDung;
  final int diemDanhGia;
  final String noiDungDanhGia;
  final DateTime ngayTao;
  final DateTime? ngaySua;
  final bool trangThaiHienThi;
  final List<ReviewImage>? hinhAnh;
  final int? maDanhGiaCha;  // ĐỔI String? -> int?
  final List<Review>? replies;

  Review({
    required this.maDanhGia,
    required this.maSanPham,
    required this.maNguoiDung,
    required this.tenNguoiDung,
    this.avatarNguoiDung,
    required this.diemDanhGia,
    required this.noiDungDanhGia,
    required this.ngayTao,
    this.ngaySua,
    required this.trangThaiHienThi,
    this.hinhAnh,
    this.maDanhGiaCha,
    this.replies,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    List<ReviewImage>? images;
    if (json['review_images'] != null) {
      final raw = json['review_images'];
      if (raw is List) {
        images = raw.map((img) => ReviewImage.fromJson(img as Map<String, dynamic>)).toList();
      }
    }

    List<Review>? replies;
    if (json['replies'] != null && json['replies'] is List) {
      replies = (json['replies'] as List)
          .map((reply) => Review.fromJson(reply as Map<String, dynamic>))
          .toList();
    }

    final maDanhGia = json['ma_danh_gia'] as int;  // ĐỔI
    final maSanPham = json['ma_san_pham'] as int;  // ĐỔI
    final maNguoiDung = json['ma_nguoi_dung'] as int;  // ĐỔI
    
    final userInfo = json['users'] as Map<String, dynamic>?;
    final tenNguoiDung = userInfo?['ten_nguoi_dung']?.toString() ?? 
                        json['ten_nguoi_dung']?.toString() ?? 
                        'Người dùng';
    final avatarNguoiDung = userInfo?['avatar']?.toString();
    
    final noiDung = (json['noi_dung_danh_gia'] ?? '').toString();
    final diem = (json['diem_danh_gia'] is num)
        ? (json['diem_danh_gia'] as num).toInt()
        : int.tryParse((json['diem_danh_gia'] ?? '0').toString()) ?? 0;

    final createdStr = (json['thoi_gian_tao'] ?? json['created_at'])?.toString();
    final updatedStr = (json['thoi_gian_cap_nhat'] ?? json['ngay_sua'])?.toString();
    final maDanhGiaCha = json['ma_danh_gia_cha'] as int?;  // ĐỔI

    return Review(
      maDanhGia: maDanhGia,
      maSanPham: maSanPham,
      maNguoiDung: maNguoiDung,
      tenNguoiDung: tenNguoiDung,
      avatarNguoiDung: avatarNguoiDung,
      diemDanhGia: diem,
      noiDungDanhGia: noiDung,
      ngayTao: createdStr != null && createdStr.isNotEmpty
          ? DateTime.parse(createdStr)
          : DateTime.now(),
      ngaySua: (updatedStr != null && updatedStr.isNotEmpty) ? DateTime.parse(updatedStr) : null,
      trangThaiHienThi: (json['trang_thai_hien_thi'] as bool?) ?? true,
      hinhAnh: images,
      maDanhGiaCha: maDanhGiaCha,
      replies: replies,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ma_danh_gia': maDanhGia,
      'ma_san_pham': maSanPham,
      'ma_nguoi_dung': maNguoiDung,
      'ten_nguoi_dung': tenNguoiDung,
      'avatar_nguoi_dung': avatarNguoiDung,
      'diem_danh_gia': diemDanhGia,
      'noi_dung_danh_gia': noiDungDanhGia,
      'ngay_tao': ngayTao.toIso8601String(),
      'ngay_sua': ngaySua?.toIso8601String(),
      'trang_thai_hien_thi': trangThaiHienThi,
      'ma_danh_gia_cha': maDanhGiaCha,
    };
  }

  bool get isReply => maDanhGiaCha != null;
  String get displayName => tenNguoiDung.isNotEmpty ? tenNguoiDung : 'Người dùng';
}