class News {
  final int maTinTuc;  // ĐỔI String -> int
  final String tieuDe;
  final String noiDung;
  final String? hinhAnh;
  final bool trangThaiHienThi;
  final DateTime ngayDang;

  News({
    required this.maTinTuc,
    required this.tieuDe,
    required this.noiDung,
    this.hinhAnh,
    required this.trangThaiHienThi,
    required this.ngayDang,
  });

  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      maTinTuc: json['ma_tin_tuc'] as int,  // ĐỔI
      tieuDe: json['tieu_de'] as String,
      noiDung: json['noi_dung'] as String,
      hinhAnh: json['hinh_anh'] as String?,
      trangThaiHienThi: json['trang_thai_hien_thi'] as bool,
      ngayDang: DateTime.parse(json['ngay_dang']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ma_tin_tuc': maTinTuc,
      'tieu_de': tieuDe,
      'noi_dung': noiDung,
      'hinh_anh': hinhAnh,
      'trang_thai_hien_thi': trangThaiHienThi,
      'ngay_dang': ngayDang.toIso8601String(),
    };
  }
}