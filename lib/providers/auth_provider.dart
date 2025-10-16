import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/user.dart';
import '../services/supabase_auth_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<AuthState>? _authSub;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  AuthProvider() {
    // Lắng nghe thay đổi phiên đăng nhập từ Supabase để cập nhật UI ngay
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      try {
        if (data.session?.user != null) {
          final u = await SupabaseAuthService.getCurrentUser();
          setUser(u);
        } else {
          setUser(null);
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void setUser(User? user) {
    _user = user;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    setLoading(true);
    setError(null);

    try {
      final user = await SupabaseAuthService.loginWithEmail(email, password);
      if (user != null) {
        setUser(user);
        return true;
      } else {
        setError('Đăng nhập thất bại');
        return false;
      }
    } catch (e) {
      setError('Lỗi đăng nhập: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> register(String email, String password, String fullName, String phone) async {
    setLoading(true);
    setError(null);

    try {
      final user = await SupabaseAuthService.register(email, password, fullName, phone);
      if (user != null) {
        setUser(user);
        return true;
      } else {
        setError('Đăng ký thất bại');
        return false;
      }
    } catch (e) {
      setError('Lỗi đăng ký: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> loginWithGoogle() async {
    setLoading(true);
    setError(null);

    try {
      final user = await SupabaseAuthService.loginWithGoogle();
      if (user != null) {
        setUser(user);
        return true;
      } else {
        setError('Đăng nhập Google thất bại');
        return false;
      }
    } catch (e) {
      setError('Lỗi đăng nhập Google: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> loginWithApple() async {
    setLoading(true);
    setError(null);

    try {
      final user = await SupabaseAuthService.loginWithApple();
      if (user != null) {
        setUser(user);
        return true;
      } else {
        setError('Đăng nhập Apple thất bại');
        return false;
      }
    } catch (e) {
      setError('Lỗi đăng nhập Apple: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> sendOTP(String email) async {
    setLoading(true);
    setError(null);

    try {
      final success = await SupabaseAuthService.sendOTP(email);
      if (success) {
        return true;
      } else {
        setError('Gửi OTP thất bại');
        return false;
      }
    } catch (e) {
      setError('Lỗi gửi OTP: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> verifyOTP(String email, String otp) async {
    setLoading(true);
    setError(null);

    try {
      final success = await SupabaseAuthService.verifyOTP(email, otp);
      if (success) {
        return true;
      } else {
        setError('Xác thực OTP thất bại');
        return false;
      }
    } catch (e) {
      setError('Lỗi xác thực OTP: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> forgotPassword(String email) async {
    setLoading(true);
    setError(null);

    try {
      final success = await SupabaseAuthService.forgotPassword(email);
      if (success) {
        return true;
      } else {
        setError('Gửi email khôi phục thất bại');
        return false;
      }
    } catch (e) {
      setError('Lỗi khôi phục mật khẩu: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    setLoading(true);
    setError(null);

    try {
      final success = await SupabaseAuthService.changePassword(newPassword);
      if (success) {
        return true;
      } else {
        setError('Đổi mật khẩu thất bại');
        return false;
      }
    } catch (e) {
      setError('Lỗi đổi mật khẩu: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<void> logout() async {
    setLoading(true);
    setError(null);

    try {
      await SupabaseAuthService.logout();
      setUser(null);
      // Reset state khác nếu cần (giỏ hàng, thông báo...)
    } catch (e) {
      setError('Lỗi đăng xuất: $e');
    } finally {
      setLoading(false);
    }
  }

  void clearError() {
    setError(null);
  }

  // Kiểm tra user hiện tại khi app khởi động
  Future<void> checkCurrentUser() async {
    setLoading(true);
    try {
      print('🔍 AuthProvider: Checking current user...');
      final user = await SupabaseAuthService.getCurrentUser();
      print('🔍 AuthProvider: User found: ${user?.tenNguoiDung}');
      setUser(user);
    } catch (e) {
      print('Error checking current user: $e');
      setUser(null);
    } finally {
      setLoading(false);
    }
  }
}
