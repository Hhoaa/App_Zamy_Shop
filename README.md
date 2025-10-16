# Zamy Shop - Flutter E-commerce App

Ứng dụng bán hàng thời trang Zamy được xây dựng bằng Flutter với giao diện đẹp và chức năng đầy đủ.

## 🚀 Tính năng chính

### 👤 Xác thực người dùng
- Đăng nhập/Đăng ký với email và mật khẩu
- Đăng nhập bằng Google, Facebook, Apple
- Xác thực OTP qua email/SMS
- Quên mật khẩu và đổi mật khẩu

### 🛍️ Mua sắm
- Trang chủ với sản phẩm nổi bật
- Danh mục sản phẩm theo loại
- Chi tiết sản phẩm với hình ảnh, màu sắc, size
- Tìm kiếm sản phẩm
- Giỏ hàng và thanh toán
- Lịch sử đơn hàng

### ❤️ Yêu thích
- Thêm/xóa sản phẩm yêu thích
- Danh sách sản phẩm yêu thích

### 💬 Chat & Thông báo
- Chat trực tiếp với hỗ trợ khách hàng
- Gửi tin nhắn, hình ảnh, file
- Thông báo đơn hàng và khuyến mãi
- Đánh giá sản phẩm

## 🏗️ Kiến trúc dự án

```
lib/
├── models/           # Data models
├── services/         # API services
├── providers/        # State management
├── screens/          # UI screens
├── widgets/          # Reusable widgets
├── theme/           # App theming
├── navigation/      # App routing
└── utils/           # Helper functions
```

## 📱 Các màn hình chính

### Xác thực
- **LoginScreen**: Đăng nhập với email/mật khẩu và mạng xã hội
- **RegisterScreen**: Đăng ký tài khoản mới với xác thực OTP

### Mua sắm
- **HomeScreen**: Trang chủ với banner, sản phẩm nổi bật, danh mục
- **ProductDetailScreen**: Chi tiết sản phẩm với hình ảnh, thông tin, đánh giá
- **CartScreen**: Giỏ hàng với quản lý sản phẩm và thanh toán
- **FavoritesScreen**: Danh sách sản phẩm yêu thích

### Chat & Thông báo
- **ChatListScreen**: Danh sách cuộc trò chuyện
- **ChatDetailScreen**: Màn hình chat với gửi tin nhắn, hình ảnh
- **NotificationsScreen**: Danh sách thông báo

## 🎨 Giao diện

### Màu sắc chủ đạo
- **Primary Beige**: `#F8F5F0` - Màu nền chính
- **Secondary Beige**: `#EAE0D5` - Màu nền phụ
- **Dark Brown**: `#8B4513` - Màu text chính
- **Accent Red**: `#D9534F` - Màu nhấn
- **Price Red**: `#DC3545` - Màu giá tiền
- **Gold Yellow**: `#FFD700` - Màu sao đánh giá

### Typography
- Font chính: Inter (Google Fonts)
- Kích thước: 12px - 32px
- Trọng số: Normal, Medium, SemiBold, Bold

## 🔧 Cài đặt và chạy

### Yêu cầu hệ thống
- Flutter SDK >= 3.7.2
- Dart SDK >= 3.0.0
- Android Studio / VS Code
- iOS Simulator / Android Emulator

### Cài đặt dependencies
```bash
flutter pub get
```

### Chạy ứng dụng
```bash
# Debug mode
flutter run

# Release mode
flutter run --release
```

### Build APK
```bash
flutter build apk --release
```

### Build iOS
```bash
flutter build ios --release
```

## 📦 Dependencies chính

### State Management
- `provider: ^6.1.2` - State management

### UI Components
- `google_fonts: ^6.2.1` - Custom fonts
- `cached_network_image: ^3.3.1` - Image caching
- `shimmer: ^3.0.0` - Loading animations
- `flutter_rating_bar: ^4.0.1` - Rating stars
- `carousel_slider: ^5.0.0` - Image carousel

### Navigation
- `go_router: ^14.2.7` - App routing

### Authentication
- `google_sign_in: ^6.2.1` - Google login
- `sign_in_with_apple: ^6.1.0` - Apple login
- `pin_code_fields: ^8.0.1` - OTP input

### Chat & Notifications
- `socket_io_client: ^2.0.3+1` - Real-time chat
- `flutter_local_notifications: ^17.2.2` - Local notifications

### Utils
- `http: ^1.2.2` - HTTP requests
- `shared_preferences: ^2.2.3` - Local storage
- `intl: ^0.19.0` - Internationalization
- `uuid: ^4.4.0` - UUID generation

## 🗄️ Database Models

### Core Models
- **User**: Thông tin người dùng
- **Product**: Sản phẩm với biến thể màu sắc, size
- **Order**: Đơn hàng và chi tiết
- **Cart**: Giỏ hàng và chi tiết

### Communication Models
- **Chat**: Cuộc trò chuyện
- **ChatMessage**: Tin nhắn trong chat
- **Notification**: Thông báo hệ thống

### Content Models
- **Category**: Danh mục sản phẩm
- **Review**: Đánh giá sản phẩm
- **Banner**: Banner quảng cáo
- **News**: Tin tức

## 🔄 State Management

### AuthProvider
- Quản lý trạng thái đăng nhập/đăng xuất
- Xử lý xác thực OTP
- Quản lý thông tin người dùng

### CartProvider
- Quản lý giỏ hàng
- Thêm/xóa/cập nhật sản phẩm
- Tính tổng tiền

### NotificationProvider
- Quản lý thông báo
- Đánh dấu đã đọc
- Đếm số thông báo chưa đọc

## 🌐 API Integration

### Base URL
```dart
static const String baseUrl = 'https://your-api-url.com/api';
```

### Endpoints chính
- `/auth/*` - Xác thực
- `/products/*` - Sản phẩm
- `/cart/*` - Giỏ hàng
- `/orders/*` - Đơn hàng
- `/chat/*` - Chat
- `/notifications/*` - Thông báo

## 📱 Responsive Design

Ứng dụng được thiết kế responsive cho:
- **Mobile**: 320px - 768px
- **Tablet**: 768px - 1024px
- **Desktop**: 1024px+

## 🚀 Deployment

### Android
1. Tạo keystore
2. Cấu hình `android/app/build.gradle`
3. Build APK/AAB
4. Upload lên Google Play

### iOS
1. Cấu hình `ios/Runner.xcworkspace`
2. Build IPA
3. Upload lên App Store

## 🔒 Bảo mật

- Mã hóa mật khẩu
- JWT token authentication
- HTTPS cho tất cả API calls
- Input validation
- SQL injection prevention

## 📈 Performance

- Image caching với `cached_network_image`
- Lazy loading cho danh sách
- State management tối ưu
- Memory management

## 🧪 Testing

```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/
```

## 📝 Changelog

### v1.0.0
- ✅ Xác thực người dùng
- ✅ Mua sắm cơ bản
- ✅ Chat và thông báo
- ✅ Giao diện responsive

## 🤝 Contributing

1. Fork repository
2. Tạo feature branch
3. Commit changes
4. Push to branch
5. Tạo Pull Request

## 📄 License

MIT License - xem file [LICENSE](LICENSE) để biết thêm chi tiết.

## 📞 Support

- Email: support@zamy.com
- Phone: +84 123 456 789
- Website: https://zamy.com

---

**Zamy Shop** - Nơi thời trang gặp gỡ công nghệ ✨