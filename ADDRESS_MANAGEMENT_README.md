# Hướng dẫn sử dụng chức năng Quản lý Địa chỉ

## 📋 Tổng quan
Chức năng quản lý địa chỉ cho phép người dùng:
- Thêm, sửa, xóa địa chỉ giao hàng
- Đặt địa chỉ mặc định
- Chọn địa chỉ khi đặt hàng
- Phân loại địa chỉ (nhà riêng, văn phòng, khác)

## 🗄️ Database Schema

### 1. Chạy SQL Schema
```sql
-- Chạy file user_addresses_schema.sql trên Supabase SQL Editor
-- File này tạo bảng user_addresses với các tính năng:
- Tự động đảm bảo chỉ có 1 địa chỉ mặc định
- Row Level Security (RLS) để bảo mật dữ liệu
- Triggers để tự động cập nhật timestamps
```

### 2. Cấu trúc bảng user_addresses
```sql
CREATE TABLE user_addresses (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    address_line1 VARCHAR(200) NOT NULL,
    address_line2 VARCHAR(200),
    ward VARCHAR(100),
    district VARCHAR(100),
    city VARCHAR(100) NOT NULL,
    postal_code VARCHAR(10),
    is_default BOOLEAN DEFAULT FALSE,
    address_type VARCHAR(20) DEFAULT 'home',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## 📱 Các màn hình đã tạo

### 1. AddressManagementScreen
- **Đường dẫn**: `lib/screens/address/address_management_screen.dart`
- **Chức năng**: Quản lý tất cả địa chỉ của user
- **Tính năng**:
  - Hiển thị danh sách địa chỉ
  - Đặt địa chỉ mặc định
  - Chỉnh sửa địa chỉ
  - Xóa địa chỉ
  - Thêm địa chỉ mới

### 2. AddEditAddressScreen
- **Đường dẫn**: `lib/screens/address/add_edit_address_screen.dart`
- **Chức năng**: Thêm mới hoặc chỉnh sửa địa chỉ
- **Tính năng**:
  - Form nhập thông tin địa chỉ đầy đủ
  - Validation dữ liệu
  - Chọn loại địa chỉ (nhà riêng, văn phòng, khác)
  - Đặt làm địa chỉ mặc định

### 3. AddressSelectionScreen
- **Đường dẫn**: `lib/screens/address/address_selection_screen.dart`
- **Chức năng**: Chọn địa chỉ khi đặt hàng
- **Tính năng**:
  - Hiển thị danh sách địa chỉ để chọn
  - Radio button selection
  - Thêm địa chỉ mới nếu cần
  - Xác nhận địa chỉ đã chọn

## 🔧 Services và Models

### 1. UserAddress Model
- **Đường dẫn**: `lib/models/user_address.dart`
- **Chức năng**: Model cho địa chỉ người dùng
- **Tính năng**:
  - JSON serialization/deserialization
  - Helper methods (fullAddress, shortAddress, etc.)
  - Address type icons và names

### 2. SupabaseAddressService
- **Đường dẫn**: `lib/services/supabase_address_service.dart`
- **Chức năng**: Service để tương tác với database
- **API Methods**:
  - `getUserAddresses(userId)` - Lấy tất cả địa chỉ
  - `getDefaultAddress(userId)` - Lấy địa chỉ mặc định
  - `addAddress(address)` - Thêm địa chỉ mới
  - `updateAddress(address)` - Cập nhật địa chỉ
  - `deleteAddress(addressId)` - Xóa địa chỉ
  - `setDefaultAddress(userId, addressId)` - Đặt địa chỉ mặc định

### 3. AddressProvider
- **Đường dẫn**: `lib/providers/address_provider.dart`
- **Chức năng**: State management cho địa chỉ
- **Tính năng**:
  - Quản lý state của danh sách địa chỉ
  - Cache địa chỉ mặc định
  - Real-time updates khi thay đổi

## 🚀 Cách sử dụng

### 1. Truy cập quản lý địa chỉ
```
Profile Screen → "Quản lý địa chỉ"
```

### 2. Thêm địa chỉ mới
```
Address Management → "+" button → Fill form → Save
```

### 3. Chỉnh sửa địa chỉ
```
Address Management → "Chỉnh sửa" → Modify → Save
```

### 4. Đặt địa chỉ mặc định
```
Address Management → "Đặt mặc định"
```

### 5. Chọn địa chỉ khi đặt hàng
```
Checkout → Address Selection → Choose → Confirm
```

## 🔒 Bảo mật

### 1. Row Level Security (RLS)
- User chỉ có thể xem/sửa địa chỉ của mình
- Policies được tạo tự động trong schema

### 2. Validation
- Validate dữ liệu input
- Kiểm tra quyền truy cập
- Error handling đầy đủ

## 🎨 UI/UX Features

### 1. Visual Indicators
- Địa chỉ mặc định có badge "Mặc định"
- Địa chỉ được chọn có border đỏ
- Icons cho từng loại địa chỉ (🏠 🏢 📍)

### 2. User Experience
- Loading states
- Error messages
- Success notifications
- Empty states với call-to-action

### 3. Responsive Design
- Form validation real-time
- Keyboard-friendly
- Touch-friendly buttons

## 🔄 Integration

### 1. Với Profile Screen
- Menu item "Quản lý địa chỉ" đã được thêm

### 2. Với Checkout Process
- Sử dụng `AddressSelectionScreen` để chọn địa chỉ

### 3. Với State Management
- `AddressProvider` đã được thêm vào `main.dart`

## 📝 Lưu ý quan trọng

1. **Database**: Chạy schema SQL trước khi sử dụng
2. **Permissions**: Đảm bảo RLS policies hoạt động đúng
3. **Validation**: Luôn validate dữ liệu trước khi lưu
4. **Error Handling**: Xử lý lỗi network và database
5. **User Experience**: Hiển thị loading và feedback phù hợp

## 🐛 Troubleshooting

### Lỗi thường gặp:
1. **"Không thể lấy danh sách địa chỉ"**
   - Kiểm tra RLS policies
   - Kiểm tra user authentication

2. **"Không thể thêm địa chỉ"**
   - Kiểm tra validation rules
   - Kiểm tra database constraints

3. **"Địa chỉ mặc định không được cập nhật"**
   - Kiểm tra trigger function
   - Kiểm tra database permissions

## 🚀 Mở rộng trong tương lai

1. **Geocoding**: Tự động lấy tọa độ từ địa chỉ
2. **Address Suggestions**: Gợi ý địa chỉ từ API
3. **Delivery Zones**: Kiểm tra khu vực giao hàng
4. **Address History**: Lịch sử thay đổi địa chỉ
5. **Bulk Operations**: Thao tác nhiều địa chỉ cùng lúc
