class Chat {
  final int maChat;  // ĐỔI String -> int
  final int maNguoiDung1;  // ĐỔI String -> int
  final int maNguoiDung2;  // ĐỔI String -> int
  final DateTime ngayTao;
  final DateTime? ngayCapNhat;
  final bool trangThai;

  Chat({
    required this.maChat,
    required this.maNguoiDung1,
    required this.maNguoiDung2,
    required this.ngayTao,
    this.ngayCapNhat,
    required this.trangThai,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      maChat: json['ma_chat'] as int,  // ĐỔI
      maNguoiDung1: json['ma_nguoi_dung_1'] as int,  // ĐỔI
      maNguoiDung2: json['ma_nguoi_dung_2'] as int,  // ĐỔI
      ngayTao: DateTime.parse(json['ngay_tao']),
      ngayCapNhat: json['ngay_cap_nhat'] != null 
          ? DateTime.parse(json['ngay_cap_nhat']) : null,
      trangThai: json['trang_thai'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ma_chat': maChat,
      'ma_nguoi_dung_1': maNguoiDung1,
      'ma_nguoi_dung_2': maNguoiDung2,
      'ngay_tao': ngayTao.toIso8601String(),
      'ngay_cap_nhat': ngayCapNhat?.toIso8601String(),
      'trang_thai': trangThai,
    };
  }
}

class ChatMessage {
  final int maTinNhan;  // ĐỔI String -> int
  final int maChat;  // ĐỔI String -> int
  final int maNguoiGui;  // ĐỔI String -> int
  final String noiDung;
  final String? loaiTinNhan;
  final DateTime thoiGianGui;
  final bool daDoc;
  final int? maTinNhanCha;  // ĐỔI String? -> int?

  ChatMessage({
    required this.maTinNhan,
    required this.maChat,
    required this.maNguoiGui,
    required this.noiDung,
    this.loaiTinNhan,
    required this.thoiGianGui,
    required this.daDoc,
    this.maTinNhanCha,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      maTinNhan: json['ma_tin_nhan'] as int,  // ĐỔI
      maChat: json['ma_chat'] as int,  // ĐỔI
      maNguoiGui: json['ma_nguoi_gui'] as int,  // ĐỔI
      noiDung: json['noi_dung'] as String,
      loaiTinNhan: json['loai_tin_nhan'] as String?,
      thoiGianGui: DateTime.parse(json['thoi_gian_gui']),
      daDoc: json['da_doc'] as bool,
      maTinNhanCha: json['ma_tin_nhan_cha'] as int?,  // ĐỔI
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ma_tin_nhan': maTinNhan,
      'ma_chat': maChat,
      'ma_nguoi_gui': maNguoiGui,
      'noi_dung': noiDung,
      'loai_tin_nhan': loaiTinNhan,
      'thoi_gian_gui': thoiGianGui.toIso8601String(),
      'da_doc': daDoc,
      'ma_tin_nhan_cha': maTinNhanCha,
    };
  }
}