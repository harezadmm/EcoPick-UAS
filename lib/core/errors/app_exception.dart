class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => message;
}

class AuthException extends AppException {
  const AuthException(super.message, {super.code});
}

class ValidationException extends AppException {
  const ValidationException(super.message, {super.code});
}

class InsufficientBalanceException extends AppException {
  const InsufficientBalanceException()
      : super('Saldo GreenCoin tidak mencukupi');
}
