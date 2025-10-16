class BannerModel {
  final int maBanner;  // ĐỔI String -> int
  final String hinhAnh;
  final bool trangThai;
  final DateTime ngayTao;
  final DateTime ngayCapNhat;

  BannerModel({
    required this.maBanner,
    required this.hinhAnh,
    required this.trangThai,
    required this.ngayTao,
    required this.ngayCapNhat,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      maBanner: json['ma_banner'] as int,  // ĐỔI
      hinhAnh: json['hinh_anh'] as String,
      trangThai: json['trang_thai'] as bool,
      ngayTao: DateTime.parse(json['ngay_tao']),
      ngayCapNhat: DateTime.parse(json['ngay_cap_nhat']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ma_banner': maBanner,
      'hinh_anh': hinhAnh,
      'trang_thai': trangThai,
      'ngay_tao': ngayTao.toIso8601String(),
      'ngay_cap_nhat': ngayCapNhat.toIso8601String(),
    };
  }
}