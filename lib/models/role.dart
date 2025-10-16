class Role {
  final int maRole;  // ĐỔI String -> int
  final String tenRole;

  Role({
    required this.maRole,
    required this.tenRole,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      maRole: json['ma_role'] as int,  // ĐỔI
      tenRole: json['ten_role'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ma_role': maRole,
      'ten_role': tenRole,
    };
  }
}