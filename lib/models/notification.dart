class NotificationModel {
  final int maThongBao;  // ĐỔI String -> int
  final int maNguoiDung;  // ĐỔI String -> int
  final String tieuDe;
  final String noiDung;
  final String loaiThongBao;
  final bool daDoc;
  final DateTime thoiGianTao;
  final int? maDonHang;  // ĐỔI String? -> int?
  final int? maKhuyenMai;  // ĐỔI String? -> int?
  final Map<String, dynamic>? duLieuBoSung;

  NotificationModel({
    required this.maThongBao,
    required this.maNguoiDung,
    required this.tieuDe,
    required this.noiDung,
    required this.loaiThongBao,
    required this.daDoc,
    required this.thoiGianTao,
    this.maDonHang,
    this.maKhuyenMai,
    this.duLieuBoSung,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      maThongBao: json['ma_thong_bao'] as int,  // ĐỔI
      maNguoiDung: json['ma_nguoi_dung'] as int,  // ĐỔI
      tieuDe: json['tieu_de'] as String,
      noiDung: json['noi_dung'] as String,
      loaiThongBao: json['loai_thong_bao'] as String,
      daDoc: json['da_doc'] as bool,
      thoiGianTao: DateTime.parse(json['thoi_gian_tao']),
      maDonHang: json['ma_don_hang'] as int?,  // ĐỔI
      maKhuyenMai: json['ma_khuyen_mai'] as int?,  // ĐỔI
      duLieuBoSung: json['du_lieu_bo_sung'] != null 
          ? Map<String, dynamic>.from(json['du_lieu_bo_sung']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ma_thong_bao': maThongBao,
      'ma_nguoi_dung': maNguoiDung,
      'tieu_de': tieuDe,
      'noi_dung': noiDung,
      'loai_thong_bao': loaiThongBao,
      'da_doc': daDoc,
      'thoi_gian_tao': thoiGianTao.toIso8601String(),
      'ma_don_hang': maDonHang,
      'ma_khuyen_mai': maKhuyenMai,
      'du_lieu_bo_sung': duLieuBoSung,
    };
  }
}