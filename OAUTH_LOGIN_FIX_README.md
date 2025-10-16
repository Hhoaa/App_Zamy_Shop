# Sửa lỗi OAuth Login (Google/Facebook)

## Vấn đề
Khi login bằng Google/Facebook, Supabase Auth trả về UUID (ví dụ: `26580670-8576-4f9b-b271-e684ff1bdc67`), nhưng database của bạn sử dụng `ma_nguoi_dung` là INTEGER. Điều này gây ra lỗi:
```
PostgrestException: invalid input syntax for type integer: "26580670-8576-4f9b-b271-e684ff1bdc67"
```

## Giải pháp
1. **Thêm cột `auth_id` vào bảng `users`** để lưu UUID từ Supabase Auth
2. **Tạo `ma_nguoi_dung` INTEGER riêng biệt** cho mỗi user
3. **Liên kết 2 ID này** thông qua cột `auth_id`

## Cách thực hiện

### Bước 1: Chạy Migration SQL
```sql
-- Thêm cột auth_id vào bảng users
ALTER TABLE users ADD COLUMN auth_id UUID UNIQUE;

-- Tạo index cho tìm kiếm nhanh
CREATE INDEX idx_users_auth_id ON users(auth_id);

-- Cập nhật comment
COMMENT ON COLUMN users.auth_id IS 'Supabase Auth UUID - links to auth.users.id';
COMMENT ON COLUMN users.ma_nguoi_dung IS 'Internal integer ID used throughout the app';
```

### Bước 2: Cấu trúc Database mới
```sql
-- Bảng users sẽ có cấu trúc:
CREATE TABLE users (
    ma_nguoi_dung INTEGER PRIMARY KEY,  -- ID chính của app (integer)
    auth_id UUID UNIQUE,                -- UUID từ Supabase Auth
    ten_nguoi_dung VARCHAR,
    email VARCHAR,
    -- ... các cột khác
);
```

### Bước 3: Cách hoạt động
1. **User đăng ký thường**: Tạo `ma_nguoi_dung` integer + `auth_id` UUID
2. **User login Google/Facebook**: 
   - Tạo `ma_nguoi_dung` integer mới
   - Lưu UUID từ Google/Facebook vào `auth_id`
   - Liên kết 2 ID này

### Bước 4: Code đã được sửa
- ✅ `_ensureUserProfileFromAuthUser()`: Tạo `ma_nguoi_dung` integer mới
- ✅ `_getUserFromSupabase()`: Tìm user bằng `auth_id` thay vì `id`
- ✅ `_createUserProfile()`: Tạo cả `ma_nguoi_dung` và `auth_id`

## Kết quả
- ✅ Google/Facebook login sẽ tạo user với `ma_nguoi_dung` INTEGER
- ✅ Không còn lỗi "invalid input syntax for type integer"
- ✅ Tất cả ID trong app đều là INTEGER
- ✅ Vẫn giữ được liên kết với Supabase Auth UUID

## Test
1. Chạy migration SQL
2. Thử login bằng Google/Facebook
3. Kiểm tra database có user mới với `ma_nguoi_dung` INTEGER và `auth_id` UUID
