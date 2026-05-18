import '../../../core/config/supabase_config.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/errors/app_exception.dart';
import '../models/app_user.dart';

class AuthService {
  AppUser _freshUser({
    required String id,
    required String fullName,
    required String email,
    required String phone,
  }) {
    return AppUser(
      id: id,
      fullName: fullName,
      email: email,
      phone: phone,
      role: UserRole.user,
      greenCoinBalance: 0,
    );
  }

  Future<AppUser> _loadProfileWithRetry(String userId, AppUser fallback) async {
    for (var i = 0; i < 4; i++) {
      final row = await SupabaseConfig.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (row != null) return AppUser.fromMap(row);
      await Future.delayed(Duration(milliseconds: 150 * (i + 1)));
    }
    return fallback;
  }

  Future<AppUser> signUp({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    if (!SupabaseConfig.isConfigured) {
      return _freshUser(
        id: 'demo-${DateTime.now().millisecondsSinceEpoch}',
        fullName: fullName,
        email: email,
        phone: phone,
      );
    }
    try {
      final response = await SupabaseConfig.client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'phone': phone},
      );
      final user = response.user;
      if (user == null) throw const AuthException('Pendaftaran gagal');
      return _loadProfileWithRetry(
        user.id,
        _freshUser(
          id: user.id,
          fullName: fullName,
          email: email,
          phone: phone,
        ),
      );
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    if (!SupabaseConfig.isConfigured) {
      final isAdmin = email.trim().toLowerCase().contains('admin');
      if (isAdmin) return AppUser.demoAdmin.copyWith(email: email);
      return AppUser.demo.copyWith(email: email);
    }
    try {
      final response = await SupabaseConfig.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw const AuthException('Email atau kata sandi salah');
      }
      return _loadProfileWithRetry(
        user.id,
        _freshUser(
          id: user.id,
          fullName: '',
          email: email,
          phone: '',
        ),
      );
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  Future<AppUser> fetchProfile(String userId) async {
    if (!SupabaseConfig.isConfigured) {
      return AppUser.demo.copyWith();
    }
    try {
      final row = await SupabaseConfig.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (row == null) throw const AuthException('Profil tidak ditemukan');
      return AppUser.fromMap(row);
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  Future<void> signOut() async {
    if (!SupabaseConfig.isConfigured) return;
    await SupabaseConfig.client.auth.signOut();
  }
}
