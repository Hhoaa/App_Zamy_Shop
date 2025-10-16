import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../navigation/navigator_key.dart';
import '../screens/auth/reset_password_form_screen.dart';

class AuthDeepLinkHandler {
  static StreamSubscription<AuthState>? _sub;

  static void initialize() {
    _sub?.cancel();
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        final nav = AppNavigator.key.currentState;
        if (nav != null) {
          nav.push(
            MaterialPageRoute(builder: (_) => const ResetPasswordFormScreen()),
          );
        }
      }
    });
  }

  static Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }
}


