class AppConstants {
  // API Configuration
  static const String baseUrl = 'https://your-api-url.com/api';
  static const String socketUrl = 'https://your-socket-server.com';
  
  // App Configuration
  static const String appName = 'Zamy Shop';
  static const String appVersion = '1.0.0';
  
  // Storage Keys
  static const String userTokenKey = 'user_token';
  static const String userIdKey = 'user_id';
  static const String userDataKey = 'user_data';
  static const String cartDataKey = 'cart_data';
  static const String favoritesKey = 'favorites';
  
  // Notification Channels
  static const String orderNotificationChannel = 'order_notifications';
  static const String promotionNotificationChannel = 'promotion_notifications';
  static const String systemNotificationChannel = 'system_notifications';
  
  // Chat Configuration
  static const int maxMessageLength = 1000;
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Image Configuration
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
  
  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 50;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 50;
  
  // Timeouts
  static const int apiTimeoutSeconds = 30;
  static const int socketTimeoutSeconds = 10;
  
  // Error Messages
  static const String networkError = 'Lỗi kết nối mạng';
  static const String serverError = 'Lỗi máy chủ';
  static const String unknownError = 'Lỗi không xác định';
  static const String loginError = 'Đăng nhập thất bại';
  static const String registerError = 'Đăng ký thất bại';
  static const String cartError = 'Lỗi giỏ hàng';
  static const String orderError = 'Lỗi đơn hàng';
  static const String chatError = 'Lỗi tin nhắn';
  static const String notificationError = 'Lỗi thông báo';
}
