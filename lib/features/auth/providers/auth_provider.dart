import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_service.dart';
import '../models/app_user.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// In demo mode, start with demo user. In Supabase mode, start null
// (set after sign-in).
final currentUserProvider = StateProvider<AppUser?>((ref) {
  return null;
});

class AuthController extends StateNotifier<AsyncValue<AppUser?>> {
  AuthController(this._service, this._ref) : super(const AsyncValue.data(null));

  final AuthService _service;
  final Ref _ref;

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _service.signIn(email: email, password: password);
      _ref.read(currentUserProvider.notifier).state = user;
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signUp({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _service.signUp(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
      );
      _ref.read(currentUserProvider.notifier).state = user;
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refreshCurrentUser() async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;
    try {
      final refreshed = await _service.fetchProfile(user.id);
      _ref.read(currentUserProvider.notifier).state = refreshed;
      state = AsyncValue.data(refreshed);
    } catch (_) {
      return;
    }
  }

  Future<void> signOut() async {
    await _service.signOut();
    _ref.read(currentUserProvider.notifier).state = null;
    state = const AsyncValue.data(null);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<AppUser?>>((ref) {
  return AuthController(ref.read(authServiceProvider), ref);
});
