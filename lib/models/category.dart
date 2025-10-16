class Category {
  final int maDanhMuc;  // ĐỔI String -> int
  final String tenDanhMuc;
  final DateTime createdAt;

  Category({
    required this.maDanhMuc,
    required this.tenDanhMuc,
    required this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      maDanhMuc: json['ma_danh_muc'] as int,  // ĐỔI
      tenDanhMuc: json['ten_danh_muc'] as String,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ma_danh_muc': maDanhMuc,
      'ten_danh_muc': tenDanhMuc,
      'created_at': createdAt.toIso8601String(),
    };
  }
}