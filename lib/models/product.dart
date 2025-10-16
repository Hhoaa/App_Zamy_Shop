class Product {
  final int maSanPham;  // ĐỔI String -> int
  final String tenSanPham;
  final String? moTaSanPham;
  final double mucGiaGoc;
  final double giaBan;
  final int soLuongDatToiThieu;
  final bool trangThaiHienThi;
  final DateTime ngayTaoBanGhi;
  final DateTime? ngaySuaBanGhi;
  final int maDanhMuc;  // ĐỔI String -> int
  final int? maBoSuuTap;  // ĐỔI String? -> int?
  final int? maGiamGia;  // ĐỔI String? -> int? (THÊM - không có trong schema cũ)
  final List<String> hinhAnh;

  Product({
    required this.maSanPham,
    required this.tenSanPham,
    this.moTaSanPham,
    required this.mucGiaGoc,
    required this.giaBan,
    required this.soLuongDatToiThieu,
    required this.trangThaiHienThi,
    required this.ngayTaoBanGhi,
    this.ngaySuaBanGhi,
    required this.maDanhMuc,
    this.maBoSuuTap,
    this.maGiamGia,
    this.hinhAnh = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      maSanPham: json['ma_san_pham'] as int,
      tenSanPham: json['ten_san_pham'] as String,
      moTaSanPham: json['mo_ta_san_pham'] as String?,
      mucGiaGoc: (json['muc_gia_goc'] as num).toDouble(),
      giaBan: (json['gia_ban'] as num).toDouble(),
      soLuongDatToiThieu: json['so_luong_dat_toi_thieu'] as int,
      trangThaiHienThi: json['trang_thai_hien_thi'] as bool,
      ngayTaoBanGhi: DateTime.parse(json['ngay_tao_ban_ghi']),
      ngaySuaBanGhi: json['ngay_sua_ban_ghi'] != null 
          ? DateTime.parse(json['ngay_sua_ban_ghi']) : null,
      maDanhMuc: json['ma_danh_muc'] as int,
      maBoSuuTap: json['ma_bo_suu_tap'] as int?,
      maGiamGia: json['ma_giam_gia'] as int?,
      hinhAnh: json['product_images'] != null 
          ? (json['product_images'] as List)
              .map((img) => img['duong_dan_anh'] as String)
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ma_san_pham': maSanPham,
      'ten_san_pham': tenSanPham,
      'mo_ta_san_pham': moTaSanPham,
      'muc_gia_goc': mucGiaGoc,
      'gia_ban': giaBan,
      'so_luong_dat_toi_thieu': soLuongDatToiThieu,
      'trang_thai_hien_thi': trangThaiHienThi,
      'ngay_tao_ban_ghi': ngayTaoBanGhi.toIso8601String(),
      'ngay_sua_ban_ghi': ngaySuaBanGhi?.toIso8601String(),
      'ma_danh_muc': maDanhMuc,
      'ma_bo_suu_tap': maBoSuuTap,
      'ma_giam_gia': maGiamGia,
      'hinh_anh': hinhAnh,
    };
  }

  String? get hinhAnhDauTien => hinhAnh.isNotEmpty ? hinhAnh.first : null;
}