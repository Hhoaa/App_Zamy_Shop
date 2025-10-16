class Store {
  final int maCuaHang;  // ĐỔI String -> int
  final String tenCuaHang;
  final String diaChi;
  final String soDienThoai;
  final bool trangThai;

  Store({
    required this.maCuaHang,
    required this.tenCuaHang,
    required this.diaChi,
    required this.soDienThoai,
    required this.trangThai,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      maCuaHang: json['ma_cua_hang'] as int,  // ĐỔI
      tenCuaHang: json['ten_cua_hang'] as String,
      diaChi: json['dia_chi'] as String,
      soDienThoai: json['so_dien_thoai'] as String,
      trangThai: json['trang_thai'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ma_cua_hang': maCuaHang,
      'ten_cua_hang': tenCuaHang,
      'dia_chi': diaChi,
      'so_dien_thoai': soDienThoai,
      'trang_thai': trangThai,
    };
  }
}