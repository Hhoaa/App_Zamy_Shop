class ReviewImage {
  final int maHinhAnh;  // ĐỔI String -> int
  final int maDanhGia;  // ĐỔI String -> int
  final String duongDanAnh;
  final DateTime thoiGianTao;
  final DateTime? thoiGianCapNhat;

  ReviewImage({
    required this.maHinhAnh,
    required this.maDanhGia,
    required this.duongDanAnh,
    required this.thoiGianTao,
    this.thoiGianCapNhat,
  });

  factory ReviewImage.fromJson(Map<String, dynamic> json) {
    return ReviewImage(
      maHinhAnh: json['ma_hinh_anh'] as int,  // ĐỔI
      maDanhGia: json['ma_danh_gia'] as int,  // ĐỔI
      duongDanAnh: json['duong_dan_anh'] as String,
      thoiGianTao: DateTime.parse(json['thoi_gian_tao']),
      thoiGianCapNhat: json['thoi_gian_cap_nhat'] != null 
          ? DateTime.parse(json['thoi_gian_cap_nhat']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ma_hinh_anh': maHinhAnh,
      'ma_danh_gia': maDanhGia,
      'duong_dan_anh': duongDanAnh,
      'thoi_gian_tao': thoiGianTao.toIso8601String(),
      'thoi_gian_cap_nhat': thoiGianCapNhat?.toIso8601String(),
    };
  }
}
