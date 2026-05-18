class AppStrings {
  AppStrings._();

  static const String appName = 'EcoPoin';
  static const String tagline = 'Ubah Sampahmu Jadi GreenCoin';
  static const String region = 'GERAKAN DAUR ULANG SURABAYA';
  static const String defaultBankSampah = 'Bank Sampah Induk Surabaya';

  static const double gcToRupiahRate = 100;
  static const int minWithdrawRupiah = 10000;
}

enum TransactionStatus {
  pending('pending'),
  process('process'),
  verified('verified'),
  completed('completed'),
  rejected('rejected'),
  cancelled('cancelled');

  final String value;
  const TransactionStatus(this.value);

  String get label {
    switch (this) {
      case TransactionStatus.pending:
        return 'Menunggu';
      case TransactionStatus.process:
        return 'Diproses';
      case TransactionStatus.verified:
        return 'Terverifikasi';
      case TransactionStatus.completed:
        return 'Selesai';
      case TransactionStatus.rejected:
        return 'Ditolak';
      case TransactionStatus.cancelled:
        return 'Dibatalkan';
    }
  }
}

enum UserRole {
  user('user'),
  admin('admin');

  final String value;
  const UserRole(this.value);
}
