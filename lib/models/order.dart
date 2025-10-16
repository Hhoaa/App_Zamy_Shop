import 'product_variant.dart';
import 'product.dart';

class Order {
  final int maDonHang;  // ĐỔI String -> int
  final int maNguoiDung;  // ĐỔI String -> int
  final int? maGiamGia;  // ĐỔI String? -> int?
  final String diaChiGiaoHang;
  final String? ghiChu;
  final DateTime ngayDatHang;
  final double tongGiaTriDonHang;
  final String? lyDoHuyHoanHang;
  final int? maTrangThaiDonHang;  // ĐỔI String? -> int?
  final List<OrderDetail> orderDetails;
  final OrderStatus? orderStatus;

  Order({
    required this.maDonHang,
    required this.maNguoiDung,
    this.maGiamGia,
    required this.diaChiGiaoHang,
    this.ghiChu,
    required this.ngayDatHang,
    required this.tongGiaTriDonHang,
    this.lyDoHuyHoanHang,
    this.maTrangThaiDonHang,
    required this.orderDetails,
    this.orderStatus,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      maDonHang: json['ma_don_hang'] as int,  // ĐỔI
      maNguoiDung: json['ma_nguoi_dung'] as int,  // ĐỔI
      maGiamGia: json['ma_giam_gia'] as int?,  // ĐỔI
      diaChiGiaoHang: json['dia_chi_giao_hang'] as String,
      ghiChu: json['ghi_chu'] as String?,
      ngayDatHang: DateTime.parse(json['ngay_dat_hang']),
      tongGiaTriDonHang: (json['tong_gia_tri_don_hang'] as num).toDouble(),
      lyDoHuyHoanHang: json['ly_do_huy_hoan_hang'] as String?,
      maTrangThaiDonHang: json['ma_trang_thai_don_hang'] as int?,  // ĐỔI
      orderDetails: (json['order_details'] as List?)
          ?.map((item) => OrderDetail.fromJson(item))
          .toList() ?? [],
      orderStatus: json['order_status'] != null 
          ? OrderStatus.fromJson(json['order_status']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ma_don_hang': maDonHang,
      'ma_nguoi_dung': maNguoiDung,
      'ma_giam_gia': maGiamGia,
      'dia_chi_giao_hang': diaChiGiaoHang,
      'ghi_chu': ghiChu,
      'ngay_dat_hang': ngayDatHang.toIso8601String(),
      'tong_gia_tri_don_hang': tongGiaTriDonHang,
      'ly_do_huy_hoan_hang': lyDoHuyHoanHang,
      'ma_trang_thai_don_hang': maTrangThaiDonHang,
    };
  }

  List<OrderDetail> get orderItems => orderDetails;
  DateTime get createdAt => ngayDatHang;
  double get tongTien => tongGiaTriDonHang;
  String get trangThai => orderStatus?.tenTrangThai ?? 'Chưa xác định';
  String? get phuongThucThanhToan => 'COD';
}

class OrderStatus {
  final int maTrangThaiDonHang;  // ĐỔI String -> int
  final String tenTrangThai;
  final bool trangThaiKichHoat;

  OrderStatus({
    required this.maTrangThaiDonHang,
    required this.tenTrangThai,
    required this.trangThaiKichHoat,
  });

  factory OrderStatus.fromJson(Map<String, dynamic> json) {
    return OrderStatus(
      maTrangThaiDonHang: json['ma_trang_thai_don_hang'] as int,  // ĐỔI
      tenTrangThai: json['ten_trang_thai'] as String,
      trangThaiKichHoat: json['trang_thai_kich_hoat'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ma_trang_thai_don_hang': maTrangThaiDonHang,
      'ten_trang_thai': tenTrangThai,
      'trang_thai_kich_hoat': trangThaiKichHoat,
    };
  }
}

class OrderDetail {
  final int maChiTietDonHang;  // ĐỔI String -> int
  final int maDonHang;  // ĐỔI String -> int
  final int maBienTheSanPham;  // ĐỔI String -> int
  final double thanhTien;
  final int soLuongMua;
  final ProductVariant? productVariant;

  OrderDetail({
    required this.maChiTietDonHang,
    required this.maDonHang,
    required this.maBienTheSanPham,
    required this.thanhTien,
    required this.soLuongMua,
    this.productVariant,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
      maChiTietDonHang: json['ma_chi_tiet_don_hang'] as int,  // ĐỔI
      maDonHang: json['ma_don_hang'] as int,  // ĐỔI
      maBienTheSanPham: json['ma_bien_the_san_pham'] as int,  // ĐỔI
      thanhTien: (json['thanh_tien'] as num).toDouble(),
      soLuongMua: json['so_luong_mua'] as int,
      productVariant: json['product_variant'] != null
          ? ProductVariant.fromJson(json['product_variant'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ma_chi_tiet_don_hang': maChiTietDonHang,
      'ma_don_hang': maDonHang,
      'ma_bien_the_san_pham': maBienTheSanPham,
      'thanh_tien': thanhTien,
      'so_luong_mua': soLuongMua,
    };
  }

  Product? get product => productVariant?.product;
  double get giaBan => thanhTien / soLuongMua;
  int get soLuong => soLuongMua;
  String? get size => productVariant?.size?.tenSize;
  String? get mauSac => productVariant?.color?.tenMau;
}