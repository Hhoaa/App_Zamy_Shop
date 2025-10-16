class Favorite {
  final int maNguoiDung;  // ĐỔI String -> int
  final int maSanPham;  // ĐỔI String -> int

  Favorite({
    required this.maNguoiDung,
    required this.maSanPham,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      maNguoiDung: json['ma_nguoi_dung'] as int,  // ĐỔI
      maSanPham: json['ma_san_pham'] as int,  // ĐỔI
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ma_nguoi_dung': maNguoiDung,
      'ma_san_pham': maSanPham,
    };
  }
}