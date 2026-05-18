import '../../../core/constants/app_strings.dart';

class AppUser {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final UserRole role;
  final int greenCoinBalance;

  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.greenCoinBalance,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      fullName: map['full_name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      role: (map['role'] as String?) == 'admin' ? UserRole.admin : UserRole.user,
      greenCoinBalance: map['green_coin_balance'] as int? ?? 0,
    );
  }

  AppUser copyWith({
    String? fullName,
    String? email,
    String? phone,
    UserRole? role,
    int? greenCoinBalance,
  }) {
    return AppUser(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      greenCoinBalance: greenCoinBalance ?? this.greenCoinBalance,
    );
  }

  static const demo = AppUser(
    id: 'demo-user',
    fullName: 'Alexa M.',
    email: 'alexa.m@example.com',
    phone: '+62 812 3456 7890',
    role: UserRole.user,
    greenCoinBalance: 5240,
  );

  static const demoAdmin = AppUser(
    id: 'demo-admin',
    fullName: 'Admin EcoPoin',
    email: 'admin@ecopoin.id',
    phone: '+62 800 0000 0000',
    role: UserRole.admin,
    greenCoinBalance: 0,
  );
}
