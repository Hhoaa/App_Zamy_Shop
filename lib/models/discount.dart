class Discount {
  final int maGiamGia;  // ĐỔI String -> int
  final String noiDung;
  final String? code;
  final String? moTa;
  final String loaiGiamGia;
  final double mucGiamGia;
  final DateTime ngayBatDau;
  final DateTime ngayKetThuc;
  final bool trangThaiKichHoat;
  final int soLuongBanDau;
  final int soLuongDaDung;
  final double? donGiaToiThieu;

  Discount({
    required this.maGiamGia,
    required this.noiDung,
    this.code,
    this.moTa,
    required this.loaiGiamGia,
    required this.mucGiamGia,
    required this.ngayBatDau,
    required this.ngayKetThuc,
    required this.trangThaiKichHoat,
    required this.soLuongBanDau,
    required this.soLuongDaDung,
    this.donGiaToiThieu,
  });

  factory Discount.fromJson(Map<String, dynamic> json) {
    return Discount(
      maGiamGia: json['ma_giam_gia'] as int,  // ĐỔI
      noiDung: json['noi_dung'] as String,
      code: json['code'] as String?,
      moTa: json['mo_ta'] as String?,
      loaiGiamGia: json['loai_giam_gia'] as String,
      mucGiamGia: (json['muc_giam_gia'] as num?)?.toDouble() ?? 0.0,
      ngayBatDau: DateTime.parse(json['ngay_bat_dau']),
      ngayKetThuc: DateTime.parse(json['ngay_ket_thuc']),
      trangThaiKichHoat: json['trang_thai_kich_hoat'] as bool,
      soLuongBanDau: json['so_luong_ban_dau'] as int? ?? 0,
      soLuongDaDung: json['so_luong_da_dung'] as int? ?? 0,
      donGiaToiThieu: json['don_gia_toi_thieu'] != null 
          ? (json['don_gia_toi_thieu'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ma_giam_gia': maGiamGia,
      'noi_dung': noiDung,
      'code': code,
      'mo_ta': moTa,
      'loai_giam_gia': loaiGiamGia,
      'muc_giam_gia': mucGiamGia,
      'ngay_bat_dau': ngayBatDau.toIso8601String(),
      'ngay_ket_thuc': ngayKetThuc.toIso8601String(),
      'trang_thai_kich_hoat': trangThaiKichHoat,
      'so_luong_ban_dau': soLuongBanDau,
      'so_luong_da_dung': soLuongDaDung,
      'don_gia_toi_thieu': donGiaToiThieu,
    };
  }
}