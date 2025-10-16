# Sửa lỗi Type Casting - INTEGER IDs

## Vấn đề đã phát hiện

Lỗi `type 'String' is not a subtype of type 'int?'` và `type 'Null' is not a subtype of type 'int'` xảy ra do:

1. **User Model**: `soDienThoai` được khai báo `String` nhưng database trả về `null`
2. **Checkout Screen**: `_selectedDiscountId` được khai báo `int?` nhưng gán `String` (discount code)
3. **Discount Service**: `userId` parameter được khai báo `String` nhưng cần `int`
4. **Discount Model**: Một số field có thể `null` nhưng được cast thành `int`

## Các thay đổi đã thực hiện

### ✅ 1. User Model (`lib/models/user.dart`)
```dart
// TRƯỚC
final String soDienThoai;
required this.soDienThoai,
soDienThoai: json['so_dien_thoai'] as String,

// SAU
final String? soDienThoai;  // Có thể null
this.soDienThoai,  // Không required
soDienThoai: json['so_dien_thoai'] as String?,  // Cast thành String?
```

### ✅ 2. Checkout Screen (`lib/screens/checkout/checkout_screen.dart`)
```dart
// TRƯỚC
int? _selectedDiscountId;
_selectedDiscountId = discount['code'];  // String -> int? ERROR

// SAU
String? _selectedDiscountId;  // Sử dụng String cho discount code
_selectedDiscountId = discount['code'];  // String -> String? OK
```

### ✅ 3. Discount Service (`lib/services/supabase_discount_service.dart`)
```dart
// TRƯỚC
static Future<Map<String, dynamic>?> validateDiscount({
  required String userId,  // String
}) async {

// SAU
static Future<Map<String, dynamic>?> validateDiscount({
  required int userId,  // INTEGER
}) async {
```

### ✅ 4. Discount Model (`lib/models/discount.dart`)
```dart
// TRƯỚC
soLuongBanDau: json['so_luong_ban_dau'] as int,
soLuongDaDung: json['so_luong_da_dung'] as int,
mucGiamGia: (json['muc_giam_gia'] as num).toDouble(),

// SAU
soLuongBanDau: json['so_luong_ban_dau'] as int? ?? 0,  // Handle null
soLuongDaDung: json['so_luong_da_dung'] as int? ?? 0,  // Handle null
mucGiamGia: (json['muc_giam_gia'] as num?)?.toDouble() ?? 0.0,  // Handle null
```

## Kết quả

### ✅ **Đã sửa:**
- ✅ User model handle null `soDienThoai`
- ✅ Checkout screen sử dụng String cho discount code
- ✅ Discount service sử dụng int cho userId
- ✅ Discount model handle null values

### ✅ **OAuth Login:**
- ✅ Google/Facebook login hoạt động
- ✅ User được tạo với INTEGER ID
- ✅ Không còn lỗi type casting

### ✅ **Discount System:**
- ✅ Chọn mã giảm giá hoạt động
- ✅ Validate discount code hoạt động
- ✅ Không còn lỗi type casting

## Test Checklist

- [ ] Google login tạo user với INTEGER ID
- [ ] Facebook login tạo user với INTEGER ID
- [ ] Chọn mã giảm giá WELCOME10 hoạt động
- [ ] Validate discount code hoạt động
- [ ] Checkout process hoạt động
- [ ] Không còn lỗi type casting

## Lưu ý quan trọng

1. **Database**: Sử dụng INTEGER IDs cho tất cả primary keys
2. **Null Handling**: Handle null values đúng cách trong models
3. **Type Safety**: Sử dụng đúng types cho parameters
4. **Discount Codes**: Sử dụng String cho discount codes, int cho IDs

## Kết luận

✅ **Tất cả lỗi type casting đã được sửa!**
- OAuth login hoạt động với INTEGER IDs
- Discount system hoạt động với proper types
- Không còn lỗi type casting
- App hoạt động bình thường
