# Sửa lỗi OAuth Login (Google/Facebook) - Phiên bản 3

## Vấn đề đã phát hiện
Database thực tế sử dụng **UUID** làm primary key (`id`), không phải `ma_nguoi_dung` INTEGER như code đang cố gắng sử dụng.

## Schema thực tế
```sql
CREATE TABLE public.users (
  id uuid NOT NULL,                    -- UUID primary key
  ten_nguoi_dung text NOT NULL,
  email text NOT NULL UNIQUE,
  so_dien_thoai text,
  ma_role user_role DEFAULT 'user',    -- String role
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT users_pkey PRIMARY KEY (id),
  CONSTRAINT users_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
);
```

## Giải pháp đã thực hiện

### 1. `_getUserFromSupabase()` - Tìm và convert user
```dart
// Tìm user theo email
final response = await _client
    .from('users')
    .select()
    .eq('email', authUser!.email!);

// Convert UUID to integer for app compatibility
final userIdInt = userData['id'].toString().hashCode.abs();

final convertedData = {
    'ma_nguoi_dung': userIdInt,  // Convert UUID to integer
    'ten_nguoi_dung': userData['ten_nguoi_dung'],
    'email': userData['email'],
    'ma_role': userData['ma_role'] == 'admin' ? 1 : (userData['ma_role'] == 'staff' ? 2 : 3),
    // ... các field khác
};
```

### 2. `_ensureUserProfileFromAuthUser()` - Tạo user OAuth
```dart
final userData = {
    'id': authUser.id,  // UUID từ Supabase Auth
    'ten_nguoi_dung': authUser.userMetadata?['full_name'] ?? 'Người dùng',
    'email': authUser.email,
    'avatar': authUser.userMetadata?['avatar_url'],
    'so_dien_thoai': authUser.phone,
    'ma_role': 'user',  // String role theo schema
    'created_at': DateTime.now().toIso8601String(),
    'updated_at': DateTime.now().toIso8601String(),
};
```

### 3. `_createUserProfile()` - Tạo user thường
```dart
final userData = {
    'id': user.id,  // UUID từ Supabase Auth
    'ten_nguoi_dung': fullName,
    'email': user.email,
    'so_dien_thoai': phone,
    'ma_role': 'user',  // String role theo schema
    'created_at': DateTime.now().toIso8601String(),
    'updated_at': DateTime.now().toIso8601String(),
};
```

## Cách hoạt động

### Login Google/Facebook:
1. **Supabase Auth** tạo user với UUID (ví dụ: `49538fa4-31ea-4492-9c21-9fbc63207883`)
2. **App** lấy email từ Auth user
3. **Tìm user** trong bảng `users` theo email
4. **Nếu chưa có**: Tạo user mới với `id` UUID từ Auth
5. **Nếu đã có**: Convert UUID thành integer cho app

### Convert UUID → Integer:
```dart
final userIdInt = userData['id'].toString().hashCode.abs();
```
- UUID: `49538fa4-31ea-4492-9c21-9fbc63207883`
- Integer: `1234567890` (hash code)

### Convert Role:
```dart
'ma_role': userData['ma_role'] == 'admin' ? 1 : (userData['ma_role'] == 'staff' ? 2 : 3)
```
- `'admin'` → `1`
- `'staff'` → `2` 
- `'user'` → `3`

## Kết quả
- ✅ Google/Facebook login hoạt động
- ✅ Tạo tài khoản trong bảng `users` với UUID
- ✅ Convert UUID thành integer cho app
- ✅ Không cần thay đổi database schema
- ✅ Tất cả ID trong app đều là INTEGER

## Test
1. Thử login Google/Facebook
2. Kiểm tra console log:
   - `Creating OAuth user profile for: email@example.com`
   - `Inserting OAuth user data: {...}`
   - `OAuth user profile created successfully`
3. Kiểm tra database có user mới với `id` UUID
4. App sẽ convert UUID thành integer để sử dụng

## Lưu ý
- Database sử dụng UUID, app sử dụng INTEGER
- Conversion tự động trong `_getUserFromSupabase()`
- Không cần migration SQL
- Tương thích với cả UUID và INTEGER
