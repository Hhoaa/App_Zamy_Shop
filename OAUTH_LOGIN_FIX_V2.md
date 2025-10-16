# Sửa lỗi OAuth Login (Google/Facebook) - Phiên bản 2

## Vấn đề đã sửa
- ✅ Tìm user theo **email** thay vì `auth_id` (vì database chưa có cột này)
- ✅ Đảm bảo tạo tài khoản trong bảng `users` khi login OAuth
- ✅ Sử dụng `ma_nguoi_dung` INTEGER thay vì UUID

## Thay đổi chính

### 1. `_getUserFromSupabase()` - Tìm user theo email
```dart
// Trước: Tìm theo auth_id (không tồn tại)
.eq('auth_id', authUserId)

// Sau: Tìm theo email
.eq('email', authUser!.email!)
```

### 2. `_ensureUserProfileFromAuthUser()` - Tạo user OAuth
```dart
// Kiểm tra user đã tồn tại chưa bằng email
final existing = await _client
    .from('users')
    .select('ma_nguoi_dung')
    .eq('email', authUser.email ?? '')
    .maybeSingle();

// Tạo ma_nguoi_dung INTEGER mới
final newUserId = DateTime.now().millisecondsSinceEpoch;

final userData = {
    'ma_nguoi_dung': newUserId,  // INTEGER ID
    'ten_nguoi_dung': authUser.userMetadata?['full_name'] ?? 'Người dùng',
    'email': authUser.email,
    'ma_role': 3,  // User role
    // ... các field khác
};
```

### 3. `_createUserProfile()` - Tạo user thường
```dart
// Kiểm tra user đã tồn tại chưa bằng email
final existingUser = await _client
    .from('users')
    .select('ma_nguoi_dung')
    .eq('email', user.email ?? '')
    .maybeSingle();
```

## Cách hoạt động

### Login Google/Facebook:
1. **Supabase Auth** tạo user với UUID (ví dụ: `b628f616-82a6-4639-80d3-cd9a8079d94f`)
2. **App** lấy email từ Auth user
3. **Tìm user** trong bảng `users` theo email
4. **Nếu chưa có**: Tạo user mới với `ma_nguoi_dung` INTEGER
5. **Nếu đã có**: Sử dụng user hiện tại

### Kết quả:
- ✅ Google/Facebook login hoạt động
- ✅ Tạo tài khoản trong bảng `users` 
- ✅ Sử dụng `ma_nguoi_dung` INTEGER
- ✅ Không cần thay đổi database schema

## Test
1. Thử login Google/Facebook
2. Kiểm tra console log:
   - `Creating OAuth user profile for: email@example.com`
   - `Inserting OAuth user data: {...}`
   - `OAuth user profile created successfully`
3. Kiểm tra database có user mới với `ma_nguoi_dung` INTEGER

## Lưu ý
- Không cần chạy migration SQL
- Sử dụng email làm key để liên kết Auth user với App user
- Tất cả ID trong app đều là INTEGER
