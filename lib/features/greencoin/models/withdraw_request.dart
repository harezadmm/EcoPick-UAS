class WithdrawRequest {
  final String walletType;
  final String accountNumber;
  final String accountName;
  final int amountGc;
  final int amountRupiah;

  WithdrawRequest({
    required this.walletType,
    required this.accountNumber,
    required this.accountName,
    required this.amountGc,
    required this.amountRupiah,
  });

  String get maskedAccount {
    if (accountNumber.length <= 4) return accountNumber;
    return '${walletType} •••• ${accountNumber.substring(accountNumber.length - 4)}';
  }
}
