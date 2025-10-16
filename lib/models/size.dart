class Size {
  final int maSize;  // ĐỔI String -> int
  final String tenSize;

  Size({
    required this.maSize,
    required this.tenSize,
  });

  factory Size.fromJson(Map<String, dynamic> json) {
    return Size(
      maSize: json['ma_size'] as int,  // ĐỔI
      tenSize: json['ten_size'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ma_size': maSize,
      'ten_size': tenSize,
    };
  }
}