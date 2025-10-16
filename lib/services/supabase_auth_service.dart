import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show ValueNotifier;
import '../models/user.dart' as app_user;
import '../config/supabase_config.dart';

class SupabaseAuthService {
  static SupabaseClient get _client => SupabaseConfig.client;
  static final ValueNotifier<int> authStateChanges = ValueNotifier<int>(0);

  // Đăng nhập với email và mật khẩu
  static Future<app_user.User?> loginWithEmail(
    String email,
    String password,
  ) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        return await _getUserFromSupabase(response.user!.id);
      }
      return null;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Đăng ký tài khoản mới - SỬA
  static Future<app_user.User?> register(
    String email,
    String password,
    String fullName,
    String phone,
  ) async {
    try {
      print('SupabaseAuthService.register - Bắt đầu:');
      print('Email: $email');
      print('Password length: ${password.length}');
      print('Full Name: $fullName');
      print('Phone: $phone');

      // Kiểm tra email đã tồn tại trong database chưa
      final existingUser =
          await _client
              .from('users')
              .select('email')
              .eq('email', email)
              .maybeSingle();

      if (existingUser != null) {
        print('Email already exists in database');
        throw Exception(
          'Tài khoản với email này đã được đăng ký. Vui lòng sử dụng email khác hoặc đăng nhập.',
        );
      }

      final response = await _client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'io.supabase.zamyshop://auth-callback/',
        data: {'full_name': fullName, 'phone': phone},
      );

      print('Supabase response:');
      print('User: ${response.user?.id}');
      print('Session: ${response.session?.accessToken}');

      if (response.user != null) {
        print('User created successfully, creating profile...');
        await _createUserProfile(response.user!, fullName, phone);
        print('Profile created, fetching user...');

        // Nếu có session, đợi một chút để đảm bảo session được cập nhật
        if (response.session != null) {
          await Future.delayed(const Duration(milliseconds: 500));
          final user = await _getUserFromSupabase(response.user!.id);
          print('Final user: $user');
          return user;
        } else {
          // Nếu không có session (email chưa được confirm),
          // vẫn tạo user object từ response để trả về
          print('No session - email needs confirmation');
          return app_user.User(
            maNguoiDung:
                response.user!.id.hashCode.abs(), // Convert UUID to int
            tenNguoiDung: fullName,
            email: response.user!.email ?? email,
            // Không bao giờ trả về hoặc lưu mật khẩu thuần trong app model
            matKhau: '',
            soDienThoai: phone,
            maRole: 3,
            avatar: null,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }
      } else {
        print('No user created');
        return null;
      }
    } catch (e) {
      print('Registration error: $e');
      throw _handleAuthError(e);
    }
  }

  // Quên mật khẩu - gửi email reset
  static Future<bool> resetPassword(String email) async {
    try {
      print('SupabaseAuthService.resetPassword - Bắt đầu:');
      print('Email: $email');

      // Kiểm tra email có tồn tại trong database không
      final existingUser =
          await _client
              .from('users')
              .select('email')
              .eq('email', email)
              .maybeSingle();

      if (existingUser == null) {
        print('Email not found in database');
        throw Exception(
          'Email này chưa được đăng ký. Vui lòng kiểm tra lại email hoặc đăng ký tài khoản mới.',
        );
      }

      // Gửi email reset password
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.zamyshop://reset-password/',
      );

      print('Reset password email sent successfully');
      return true;
    } catch (e) {
      print('Reset password error: $e');
      throw _handleAuthError(e);
    }
  }

  static void attachAuthDebugListener() {
    _client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;
      print(
        '[SupabaseAuth][onAuthStateChange] event=$event user=${session?.user?.id} accessToken=${session?.accessToken != null}',
      );
      authStateChanges.value++;
    });
  }

  static Future<app_user.User?> loginWithGoogle() async {
    try {
      print('[GoogleLogin][OAuth] Start signInWithOAuth (redirect)');
      final response = await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.zamyshop://login-callback/',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      print('[GoogleLogin][OAuth] signInWithOAuth return=$response');
      await Future.delayed(const Duration(milliseconds: 400));
      var session = _client.auth.currentSession;
      final sessionUserId = session?.user?.id;
      final hasToken = session?.accessToken != null;
      print(
        '[GoogleLogin][OAuth] after delay session user=$sessionUserId hasToken=$hasToken',
      );

      if (session == null || session.user == null) {
        await Future.delayed(const Duration(seconds: 1));
        session = _client.auth.currentSession;
        print(
          '[GoogleLogin][OAuth] after 1s session user=${session?.user?.id}',
        );
      }

      if (session?.user != null) {
        final authId = session!.user!.id;
        var user = await _getUserFromSupabase(authId);
        print('[GoogleLogin][OAuth] App user fetched: ${user?.maNguoiDung}');
        if (user == null) {
          print(
            '[GoogleLogin][OAuth] No profile in DB -> creating minimal profile',
          );
          await _ensureUserProfileFromAuthUser(session.user!);
          user = await _getUserFromSupabase(authId);
          print(
            '[GoogleLogin][OAuth] App user after create: ${user?.maNguoiDung}',
          );
        }
        return user;
      }

      print(
        '[GoogleLogin][OAuth] No session after redirect. Likely deep link not captured.',
      );
      return null;
    } catch (e) {
      print('[GoogleLogin][Error] $e');
      throw Exception('Google login failed: $e');
    }
  }

  static Future<app_user.User?> loginWithFacebook() async {
    try {
      print('[FacebookLogin][OAuth] Start signInWithOAuth (redirect)');
      final response = await _client.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: 'io.supabase.zamyshop://login-callback/',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      print('[FacebookLogin][OAuth] signInWithOAuth return=$response');
      await Future.delayed(const Duration(milliseconds: 400));
      var session = _client.auth.currentSession;
      final fbSessionUserId = session?.user?.id;
      final fbHasToken = session?.accessToken != null;
      print(
        '[FacebookLogin][OAuth] after delay session user=$fbSessionUserId hasToken=$fbHasToken',
      );

      if (session == null || session.user == null) {
        await Future.delayed(const Duration(seconds: 1));
        session = _client.auth.currentSession;
        print(
          '[FacebookLogin][OAuth] after 1s session user=${session?.user?.id}',
        );
      }

      if (session?.user != null) {
        final authId = session!.user!.id;
        var user = await _getUserFromSupabase(authId);
        print('[FacebookLogin][OAuth] App user fetched: ${user?.maNguoiDung}');
        if (user == null) {
          print(
            '[FacebookLogin][OAuth] No profile in DB -> creating minimal profile',
          );
          await _ensureUserProfileFromAuthUser(session.user!);
          user = await _getUserFromSupabase(authId);
          print(
            '[FacebookLogin][OAuth] App user after create: ${user?.maNguoiDung}',
          );
        }
        return user;
      }

      print(
        '[FacebookLogin][OAuth] No session after redirect. Likely deep link not captured.',
      );
      return null;
    } catch (e) {
      print('[FacebookLogin][Error] $e');
      throw Exception('Facebook login failed: $e');
    }
  }

  static Future<app_user.User?> loginWithApple() async {
    try {
      final response = await _client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'io.supabase.zamyshop://login-callback/',
      );

      final sessionApple = _client.auth.currentSession;
      if (sessionApple?.user != null) {
        return await _getUserFromSupabase(sessionApple!.user!.id);
      }
      return null;
    } catch (e) {
      throw Exception('Apple login failed: $e');
    }
  }

  static Future<bool> sendOTP(String email) async {
    try {
      await _client.auth.signInWithOtp(email: email);
      return true;
    } catch (e) {
      throw Exception('Send OTP failed: $e');
    }
  }

  static Future<bool> verifyOTP(String email, String otp) async {
    try {
      final response = await _client.auth.verifyOTP(
        type: OtpType.email,
        token: otp,
        email: email,
      );
      return response.user != null;
    } catch (e) {
      throw Exception('Verify OTP failed: $e');
    }
  }

  static Future<bool> forgotPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
      return true;
    } catch (e) {
      throw Exception('Forgot password failed: $e');
    }
  }

  static Future<bool> changePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
      return true;
    } catch (e) {
      throw Exception('Change password failed: $e');
    }
  }

  // Cập nhật profile - SỬA: userId giờ là INTEGER
  static Future<bool> updateUserProfile(
    int userId, { // ĐỔI String -> int
    String? name,
    String? phone,
    String? address,
    String? avatarUrl,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updateData['ten_nguoi_dung'] = name;
      if (phone != null) updateData['so_dien_thoai'] = phone;
      if (address != null) updateData['dia_chi'] = address;
      if (avatarUrl != null) updateData['avatar'] = avatarUrl;

      await _client.from('users').update(updateData).eq('id', userId);

      return true;
    } catch (e) {
      throw Exception('Update profile failed: $e');
    }
  }

  // Upload avatar bytes to Supabase Storage and return public URL
  static Future<String> uploadUserAvatar({
    required int userId,
    required Uint8List data,
    String contentType = 'image/jpeg',
  }) async {
    try {
      final path =
          'user_${userId}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _client.storage
          .from('avatars')
          .uploadBinary(
            path,
            data,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );
      final publicUrl = _client.storage.from('avatars').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      throw Exception('Upload avatar failed: $e');
    }
  }

  static Future<void> logout() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
  }

  static Future<app_user.User?> getCurrentUser() async {
    try {
      final session = _client.auth.currentSession;
      if (session?.user != null) {
        return await _getUserFromSupabase(session!.user!.id);
      }
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Tạo profile - SỬA để phù hợp với schema mới (INTEGER IDs)
  static Future<void> _createUserProfile(
    User user,
    String fullName,
    String phone,
  ) async {
    try {
      print('Creating user profile for: ${user.email}');

      final existingUser =
          await _client
              .from('users')
              .select('id')
              .eq('email', user.email ?? '')
              .maybeSingle();

      if (existingUser != null) {
        print('User profile already exists, updating information...');
        // Cập nhật thông tin user nếu đã tồn tại
        await _client
            .from('users')
            .update({
              'ten_nguoi_dung': fullName,
              'so_dien_thoai': phone,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('email', user.email ?? '');
        print('User profile updated');
        return;
      }

      final userData = {
        'ten_nguoi_dung': fullName,
        'email': user.email,
        'mat_khau': '', // OAuth không có password
        'so_dien_thoai': phone,
        'ma_role': 3, // INTEGER role: 3 = user
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      print('User data to insert: $userData');

      final response = await _client.from('users').insert(userData);
      print('User profile created successfully: $response');
    } catch (e) {
      print('Error creating user profile: $e');
      if (e.toString().contains('duplicate key') ||
          e.toString().contains('unique constraint')) {
        print('User profile already exists, continuing...');
        return;
      }
      rethrow;
    }
  }

  // Tạo profile từ OAuth - SỬA để phù hợp với schema mới (INTEGER IDs)
  static Future<void> _ensureUserProfileFromAuthUser(User authUser) async {
    try {
      print('Creating OAuth user profile for: ${authUser.email}');

      final userData = {
        'ten_nguoi_dung':
            authUser.userMetadata?['full_name'] ??
            (authUser.email ?? 'Người dùng'),
        'email': authUser.email,
        'mat_khau': '', // OAuth không có password
        'avatar': authUser.userMetadata?['avatar_url'],
        'so_dien_thoai': authUser.phone,
        'ma_role': 3, // INTEGER role: 3 = user
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      print('Upserting OAuth user data by email: $userData');
      await _client
          .from('users')
          .upsert(userData, onConflict: 'email')
          .select('id')
          .maybeSingle();
      print('OAuth user profile ensured');
    } catch (e) {
      print('_ensureUserProfileFromAuthUser error: $e');
    }
  }

  static Exception _handleAuthError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('email_address_invalid') ||
        errorString.contains('invalid_email')) {
      return Exception(
        'Địa chỉ email không hợp lệ. Vui lòng kiểm tra lại email của bạn.',
      );
    } else if (errorString.contains('email_not_confirmed')) {
      return Exception(
        'Email chưa được xác thực. Vui lòng kiểm tra hộp thư và xác thực email.',
      );
    } else if (errorString.contains('user_already_registered') ||
        errorString.contains(
          'duplicate key value violates unique constraint',
        )) {
      return Exception(
        'Email này đã được đăng ký. Vui lòng sử dụng email khác hoặc đăng nhập.',
      );
    } else if (errorString.contains('password_too_short')) {
      return Exception(
        'Mật khẩu quá ngắn. Vui lòng nhập mật khẩu có ít nhất 6 ký tự.',
      );
    } else if (errorString.contains('weak_password')) {
      return Exception('Mật khẩu quá yếu. Vui lòng sử dụng mật khẩu mạnh hơn.');
    } else if (errorString.contains('invalid_credentials') ||
        errorString.contains('invalid_login_credentials')) {
      return Exception(
        'Email hoặc mật khẩu không đúng. Vui lòng kiểm tra lại thông tin đăng nhập.',
      );
    } else if (errorString.contains('over_email_send_rate_limit') ||
        errorString.contains('email_rate_limit_exceeded')) {
      return Exception(
        'Bạn đã đăng ký quá nhiều lần. Vui lòng chờ ít phút rồi thử lại.',
      );
    } else if (errorString.contains('rate_limit') ||
        errorString.contains('too_many_requests')) {
      return Exception('Quá nhiều yêu cầu. Vui lòng thử lại sau ít phút.');
    } else if (errorString.contains('duplicate key') ||
        errorString.contains('unique constraint')) {
      return Exception(
        'Thông tin đã tồn tại. Vui lòng sử dụng thông tin khác.',
      );
    } else if (errorString.contains('foreign key constraint')) {
      return Exception(
        'Dữ liệu không hợp lệ. Vui lòng kiểm tra lại thông tin.',
      );
    } else if (errorString.contains('not null constraint')) {
      return Exception(
        'Thiếu thông tin bắt buộc. Vui lòng điền đầy đủ thông tin.',
      );
    } else if (errorString.contains('signup_disabled')) {
      return Exception(
        'Tính năng đăng ký tạm thời bị tắt. Vui lòng liên hệ hỗ trợ.',
      );
    } else if (errorString.contains('network') ||
        errorString.contains('connection')) {
      return Exception(
        'Lỗi kết nối mạng. Vui lòng kiểm tra internet và thử lại.',
      );
    } else if (errorString.contains('timeout')) {
      return Exception('Hết thời gian chờ. Vui lòng thử lại.');
    } else if (errorString.contains('server_error')) {
      return Exception('Lỗi máy chủ. Vui lòng thử lại sau.');
    } else if (errorString.contains('unauthorized') ||
        errorString.contains('forbidden')) {
      return Exception('Không có quyền thực hiện. Vui lòng liên hệ hỗ trợ.');
    } else {
      return Exception('Đã xảy ra lỗi. Vui lòng thử lại sau.');
    }
  }

  // Lấy user - SỬA để phù hợp với schema mới (INTEGER IDs)
  static Future<app_user.User?> _getUserFromSupabase(String authUserId) async {
    try {
      print('Fetching user from Supabase: $authUserId');

      // Lấy email từ Supabase Auth user
      var authUser = _client.auth.currentUser;

      // Nếu không có auth user, thử đợi một chút và thử lại
      if (authUser?.email == null) {
        print('No email found in auth user, waiting and retrying...');
        await Future.delayed(const Duration(milliseconds: 300));
        authUser = _client.auth.currentUser;

        if (authUser?.email == null) {
          print('Still no email found in auth user after retry');
          return null;
        }
      }

      final response = await _client
          .from('users')
          .select()
          .eq('email', authUser!.email!);

      print('Raw response from database: $response');

      if (response.isEmpty) {
        print('No user found in database');
        return null;
      }

      final userData = response.first;

      final convertedData = {
        'id': userData['id'], // INTEGER ID từ database
        'ten_nguoi_dung': userData['ten_nguoi_dung'],
        'avatar': userData['avatar'],
        'email': userData['email'],
        'so_dien_thoai': userData['so_dien_thoai'], // Có thể null
        'ngay_sinh': userData['ngay_sinh'],
        'gioi_tinh': userData['gioi_tinh'],
        'mat_khau': userData['mat_khau'] ?? '',
        'otp': null,
        'thoi_diem_het_han_otp': null,
        'nha_cung_cap_mxh': null,
        'id_mxh': null,
        'dia_chi': userData['dia_chi'],
        'ma_role': userData['ma_role'], // INTEGER role từ database
        'created_at': userData['created_at'],
        'updated_at': userData['updated_at'],
      };

      print('Converted user data: $convertedData');

      return app_user.User.fromJson(convertedData);
    } catch (e) {
      print('Error getting user from Supabase: $e');
      return null;
    }
  }
}
