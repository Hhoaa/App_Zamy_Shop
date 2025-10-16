class Collection {
  final int maBoSuuTap;  // ĐỔI String -> int
  final String tenBoSuuTap;
  final String? moTa;
  final bool trangThai;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> hinhAnh;

  Collection({
    required this.maBoSuuTap,
    required this.tenBoSuuTap,
    this.moTa,
    required this.trangThai,
    required this.createdAt,
    required this.updatedAt,
    this.hinhAnh = const [],
  });

  factory Collection.fromJson(Map<String, dynamic> json) {
    return Collection(
      maBoSuuTap: json['ma_bo_suu_tap'] as int,  // ĐỔI
      tenBoSuuTap: json['ten_bo_suu_tap'] as String,
      moTa: json['mo_ta'] as String?,
      trangThai: json['trang_thai'] as bool,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      hinhAnh: json['collection_images'] != null 
          ? (json['collection_images'] as List)
              .map((img) => img['duong_dan_anh'] as String)
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ma_bo_suu_tap': maBoSuuTap,
      'ten_bo_suu_tap': tenBoSuuTap,
      'mo_ta': moTa,
      'trang_thai': trangThai,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'hinh_anh': hinhAnh,
    };
  }
}