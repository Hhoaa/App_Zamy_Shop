class Role {
  final int maRole; // ĐỔI String -> int
  final String tenRole;

  Role({required this.maRole, required this.tenRole});

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      maRole: json['ma_role'] as int, // ĐỔI
      tenRole: json['ten_role'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'ma_role': maRole, 'ten_role': tenRole};
  }
}

class Size {
  final int maSize; // ĐỔI String -> int
  final String tenSize;

  Size({required this.maSize, required this.tenSize});

  factory Size.fromJson(Map<String, dynamic> json) {
    return Size(
      maSize: json['ma_size'] as int, // ĐỔI
      tenSize: json['ten_size'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'ma_size': maSize, 'ten_size': tenSize};
  }
}

class Store {
  final int maCuaHang; // ĐỔI String -> int
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
      maCuaHang: json['ma_cua_hang'] as int, // ĐỔI
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

class User {
  final int maNguoiDung; // ĐỔI String -> int
  final String tenNguoiDung;
  final String? avatar;
  final String email;
  final String? soDienThoai; // SỬA: có thể null
  final DateTime? ngaySinh;
  final String? gioiTinh;
  final String matKhau;
  final String? otp;
  final DateTime? thoiDiemHetHanOTP;
  final String? nhaCungCapMXH;
  final String? idMXH;
  final String? diaChi;
  final int maRole; // ĐỔI String -> int
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.maNguoiDung,
    required this.tenNguoiDung,
    this.avatar,
    required this.email,
    this.soDienThoai, // SỬA: không required
    this.ngaySinh,
    this.gioiTinh,
    required this.matKhau,
    this.otp,
    this.thoiDiemHetHanOTP,
    this.nhaCungCapMXH,
    this.idMXH,
    this.diaChi,
    required this.maRole,
    required this.createdAt,
    required this.updatedAt,
  });
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      maNguoiDung: json['id'] as int, // ĐỔI
      tenNguoiDung: json['ten_nguoi_dung'] as String,
      avatar: json['avatar'] as String?,
      email: json['email'] as String,
      soDienThoai: json['so_dien_thoai'] as String?, // SỬA: có thể null
      ngaySinh:
          json['ngay_sinh'] != null ? DateTime.parse(json['ngay_sinh']) : null,
      gioiTinh: json['gioi_tinh'] as String?,
      matKhau: json['mat_khau'] as String,
      otp: json['otp'] as String?,
      thoiDiemHetHanOTP:
          json['thoi_diem_het_han_otp'] != null
              ? DateTime.parse(json['thoi_diem_het_han_otp'])
              : null,
      nhaCungCapMXH: json['nha_cung_cap_mxh'] as String?,
      idMXH: json['id_mxh'] as String?,
      diaChi: json['dia_chi'] as String?,
      maRole: json['ma_role'] as int, // ĐỔI String -> int
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': maNguoiDung,
      'ten_nguoi_dung': tenNguoiDung,
      'avatar': avatar,
      'email': email,
      'so_dien_thoai': soDienThoai,
      'ngay_sinh': ngaySinh?.toIso8601String(),
      'gioi_tinh': gioiTinh,
      'mat_khau': matKhau,
      'otp': otp,
      'thoi_diem_het_han_otp': thoiDiemHetHanOTP?.toIso8601String(),
      'nha_cung_cap_mxh': nhaCungCapMXH,
      'id_mxh': idMXH,
      'dia_chi': diaChi,
      'ma_role': maRole,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
