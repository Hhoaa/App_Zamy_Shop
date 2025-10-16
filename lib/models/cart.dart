import 'product_variant.dart';

class Cart {
  final int maGioHang;  // ĐỔI String -> int
  final int maNguoiDung;  // ĐỔI String -> int
  final List<CartDetail> cartDetails;

  Cart({
    required this.maGioHang,
    required this.maNguoiDung,
    required this.cartDetails,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      maGioHang: json['ma_gio_hang'] as int,  // ĐỔI
      maNguoiDung: json['ma_nguoi_dung'] as int,  // ĐỔI
      cartDetails: (json['cart_details'] as List?)
          ?.map((item) => CartDetail.fromJson(item))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ma_gio_hang': maGioHang,
      'ma_nguoi_dung': maNguoiDung,
    };
  }
}

class CartDetail {
  final int maChiTietGioHang;  // ĐỔI String -> int
  final int maGioHang;  // ĐỔI String -> int
  final int maBienTheSanPham;  // ĐỔI String -> int
  final int soLuong;
  final double giaTienTaiThoiDiemThem;
  final ProductVariant? productVariant;

  CartDetail({
    required this.maChiTietGioHang,
    required this.maGioHang,
    required this.maBienTheSanPham,
    required this.soLuong,
    required this.giaTienTaiThoiDiemThem,
    this.productVariant,
  });

  factory CartDetail.fromJson(Map<String, dynamic> json) {
    return CartDetail(
      maChiTietGioHang: json['ma_chi_tiet_gio_hang'] as int,  // ĐỔI
      maGioHang: json['ma_gio_hang'] as int,  // ĐỔI
      maBienTheSanPham: json['ma_bien_the_san_pham'] as int,  // ĐỔI
      soLuong: json['so_luong'] as int,
      giaTienTaiThoiDiemThem: (json['gia_tien_tai_thoi_diem_them'] as num).toDouble(),
      productVariant: json['product_variant'] != null
          ? ProductVariant.fromJson(json['product_variant'])
          : null,
    );
  }

  dynamic get product => productVariant?.product;
  String? get size => productVariant?.size?.tenSize;
  String? get color => productVariant?.color?.tenMau;

  Map<String, dynamic> toJson() {
    return {
      'ma_chi_tiet_gio_hang': maChiTietGioHang,
      'ma_gio_hang': maGioHang,
      'ma_bien_the_san_pham': maBienTheSanPham,
      'so_luong': soLuong,
      'gia_tien_tai_thoi_diem_them': giaTienTaiThoiDiemThem,
    };
  }
}