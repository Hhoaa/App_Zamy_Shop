import 'size.dart';
import 'color.dart';
import 'product.dart';

class ProductVariant {
  final int maBienThe;  // ĐỔI String -> int
  final int maSanPham;  // ĐỔI String -> int
  final int maSize;  // ĐỔI String -> int
  final int maMau;  // ĐỔI String -> int
  final int tonKho;
  final Size? size;
  final ColorModel? color;
  final Product? product;

  ProductVariant({
    required this.maBienThe,
    required this.maSanPham,
    required this.maSize,
    required this.maMau,
    required this.tonKho,
    this.size,
    this.color,
    this.product,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      maBienThe: json['ma_bien_the'] as int,  // ĐỔI
      maSanPham: json['ma_san_pham'] as int,  // ĐỔI
      maSize: json['ma_size'] as int,  // ĐỔI
      maMau: json['ma_mau'] as int,  // ĐỔI
      tonKho: json['ton_kho'] as int,
      size: json['size'] != null ? Size.fromJson(json['size']) : null,
      color: json['color'] != null ? ColorModel.fromJson(json['color']) : null,
      product: json['product'] != null ? Product.fromJson(json['product']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ma_bien_the': maBienThe,
      'ma_san_pham': maSanPham,
      'ma_size': maSize,
      'ma_mau': maMau,
      'ton_kho': tonKho,
    };
  }
}

class ProductImage {
  final int maHinhAnh;  // ĐỔI String -> int
  final int maSanPham;  // ĐỔI String -> int
  final String duongDanAnh;

  ProductImage({
    required this.maHinhAnh,
    required this.maSanPham,
    required this.duongDanAnh,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      maHinhAnh: json['ma_hinh_anh'] as int,  // ĐỔI
      maSanPham: json['ma_san_pham'] as int,  // ĐỔI
      duongDanAnh: json['duong_dan_anh'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ma_hinh_anh': maHinhAnh,
      'ma_san_pham': maSanPham,
      'duong_dan_anh': duongDanAnh,
    };
  }
}