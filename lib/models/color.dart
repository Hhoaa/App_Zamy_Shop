class ColorModel {
  final int maMau;  // ĐỔI String -> int
  final String tenMau;
  final String? maMauHex;

  ColorModel({
    required this.maMau,
    required this.tenMau,
    this.maMauHex,
  });

  factory ColorModel.fromJson(Map<String, dynamic> json) {
    return ColorModel(
      maMau: json['ma_mau'] as int,  // ĐỔI
      tenMau: json['ten_mau'] as String,
      maMauHex: json['ma_mau_hex'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ma_mau': maMau,
      'ten_mau': tenMau,
      'ma_mau_hex': maMauHex,
    };
  }
}