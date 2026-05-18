import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class QuickLoginAccount {
  final String email;
  final String password;

  const QuickLoginAccount({
    required this.email,
    required this.password,
  });

  factory QuickLoginAccount.fromJson(Map<String, dynamic> json) {
    return QuickLoginAccount(
      email: json['email'] as String? ?? '',
      password: json['password'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

class QuickLoginStore {
  QuickLoginStore({
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  static const _storageKey = 'quick_login_accounts';
  static const _maxAccounts = 4;

  final FlutterSecureStorage _storage;

  Future<List<QuickLoginAccount>> loadAccounts() async {
    try {
      final value = await _storage.read(key: _storageKey);
      if (value == null || value.isEmpty) return const [];

      final decoded = jsonDecode(value);
      if (decoded is! List) return const [];

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(QuickLoginAccount.fromJson)
          .where((account) =>
              account.email.trim().isNotEmpty && account.password.isNotEmpty)
          .take(_maxAccounts)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<QuickLoginAccount>> saveAccount({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty || password.isEmpty) {
      return loadAccounts();
    }

    final currentAccounts = await loadAccounts();
    final nextAccounts = [
      QuickLoginAccount(email: normalizedEmail, password: password),
      ...currentAccounts.where(
        (account) =>
            account.email.trim().toLowerCase() != normalizedEmail.toLowerCase(),
      ),
    ].take(_maxAccounts).toList();

    try {
      await _storage.write(
        key: _storageKey,
        value: jsonEncode(
          nextAccounts.map((account) => account.toJson()).toList(),
        ),
      );
    } catch (_) {
      return currentAccounts;
    }

    return nextAccounts;
  }

  Future<void> clearAccounts() async {
    try {
      await _storage.delete(key: _storageKey);
    } catch (_) {
      return;
    }
  }
}
