import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/labeled_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../data/greencoin_service.dart';
import '../models/withdraw_request.dart';
import '../providers/greencoin_provider.dart';

class WithdrawBottomSheet extends ConsumerStatefulWidget {
  final int balanceGc;
  const WithdrawBottomSheet({super.key, required this.balanceGc});

  static Future<void> show(BuildContext context, int balanceGc) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surf(context),
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
      ),
      builder: (_) => WithdrawBottomSheet(balanceGc: balanceGc),
    );
  }

  @override
  ConsumerState<WithdrawBottomSheet> createState() => _WithdrawBottomSheetState();
}

class _WithdrawBottomSheetState extends ConsumerState<WithdrawBottomSheet> {
  int _selectedWallet = 0;
  int _selectedPreset = 2;
  bool _confirmed = false;
  bool _isCustomAmount = false;
  int _customAmount = 0;
  final _accountCtrl = TextEditingController(text: '0812 3456 7890');
  final _nameCtrl = TextEditingController(text: 'Alexa M.');
  final _customAmountCtrl = TextEditingController();

  final _wallets = const [
    _Wallet('DANA', Color(0xFF118EEA), Icons.account_balance_wallet_rounded),
    _Wallet('GoPay', Color(0xFF00AED6), Icons.payments_rounded),
    _Wallet('OVO', Color(0xFF4C2A86), Icons.circle),
    _Wallet('ShopeePay', Color(0xFFEE4D2D), Icons.shopping_bag_rounded),
  ];

  final _presets = const [500, 1000, 2000, -1];

  int get _amount {
    if (_isCustomAmount && _customAmount > 0) return _customAmount;
    return _presets[_selectedPreset] == -1
        ? widget.balanceGc
        : _presets[_selectedPreset];
  }

  int get _rupiah => Formatters.rupiahFromGc(_amount);

  @override
  void dispose() {
    _accountCtrl.dispose();
    _nameCtrl.dispose();
    _customAmountCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (!_confirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon centang konfirmasi data')),
      );
      return;
    }
    if (_rupiah < AppStrings.minWithdrawRupiah) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal penarikan Rp 10.000')),
      );
      return;
    }
    if (_amount > widget.balanceGc) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saldo tidak cukup. Saldo Anda ${Formatters.greenCoin(widget.balanceGc)}')),
      );
      return;
    }

    final remainingBalance = widget.balanceGc - _amount;
    final request = WithdrawRequest(
      walletType: _wallets[_selectedWallet].name,
      accountNumber: _accountCtrl.text,
      accountName: _nameCtrl.text,
      amountGc: _amount,
      amountRupiah: _rupiah,
      remainingBalanceGc: remainingBalance,
    );

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('User tidak ditemukan');

      await GreenCoinService().createWithdraw(user.id, request);

      // Invalidate providers to refresh data
      ref.invalidate(dashboardProvider);
      ref.invalidate(greenCoinBalanceProvider);
      ref.invalidate(greenCoinTransactionsProvider);

      if (!mounted) return;
      Navigator.of(context).pop();
      context.push('/withdraw/success', extra: request);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: h * 0.92,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: AppSizes.md),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.brd(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSizes.xl,
                  AppSizes.lg,
                  AppSizes.xl,
                  AppSizes.md,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tarik dana',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textP(context),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Ubah GreenCoin Anda menjadi saldo e-wallet dengan cepat dan aman.',
                            style: TextStyle(
                              color: AppColors.textS(context),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.xl,
                  ),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSizes.lg),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Saldo tersedia',
                                  style: TextStyle(
                                    color:
                                        Colors.white.withValues(alpha: 0.85),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  Formatters.greenCoin(widget.balanceGc),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '≈ ${Formatters.rupiah(Formatters.rupiahFromGc(widget.balanceGc))}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.lg),
                    Text(
                      'Pilih e-wallet',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textP(context),
                      ),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _wallets.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: AppSizes.sm,
                        crossAxisSpacing: AppSizes.sm,
                        childAspectRatio: 3.0,
                      ),
                      itemBuilder: (context, i) {
                        final selected = i == _selectedWallet;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedWallet = i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.md,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primaryLight
                                  : AppColors.surface,
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusLg),
                              border: Border.all(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.brd(context),
                                width: selected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: _wallets[i]
                                        .color
                                        .withValues(alpha: 0.15),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _wallets[i].icon,
                                    color: _wallets[i].color,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: AppSizes.sm),
                                Expanded(
                                  child: Text(
                                    _wallets[i].name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textP(context),
                                    ),
                                  ),
                                ),
                                if (selected)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSizes.lg),
                    Text(
                      'Detail tujuan',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textP(context),
                      ),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    LabeledField(
                      label: 'Nomor tujuan',
                      child: AppTextField(controller: _accountCtrl),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    LabeledField(
                      label: 'Nama pemilik akun',
                      child: AppTextField(controller: _nameCtrl),
                    ),
                    const SizedBox(height: AppSizes.lg),
                    Text(
                      'Jumlah penarikan',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textP(context),
                      ),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.lg,
                        vertical: AppSizes.md,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfMuted(context),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusPill),
                      ),
                      child: Text(
                        Formatters.greenCoin(_amount),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    Wrap(
                      spacing: AppSizes.sm,
                      children: [
                        ...List.generate(_presets.length, (i) {
                          final selected = !_isCustomAmount && i == _selectedPreset;
                          final label = _presets[i] == -1
                              ? 'Semua'
                              : Formatters.compactNumber(_presets[i]);
                          return GestureDetector(
                            onTap: () => setState(() {
                              _selectedPreset = i;
                              _isCustomAmount = false;
                              _customAmountCtrl.clear();
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.lg,
                                vertical: AppSizes.sm,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusPill,
                                ),
                                border: Border.all(
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.brd(context),
                                ),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? Colors.white
                                      : AppColors.textS(context),
                                ),
                              ),
                            ),
                          );
                        }),
                        GestureDetector(
                          onTap: () => setState(() => _isCustomAmount = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.lg,
                              vertical: AppSizes.sm,
                            ),
                            decoration: BoxDecoration(
                              color: _isCustomAmount
                                  ? AppColors.primary
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusPill,
                              ),
                              border: Border.all(
                                color: _isCustomAmount
                                    ? AppColors.primary
                                    : AppColors.brd(context),
                              ),
                            ),
                            child: Text(
                              'Custom',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _isCustomAmount
                                    ? Colors.white
                                    : AppColors.textS(context),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_isCustomAmount) ...[
                      const SizedBox(height: AppSizes.sm),
                      TextField(
                        controller: _customAmountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Masukkan nominal dalam GC',
                          prefixText: 'GC ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.lg,
                            vertical: AppSizes.md,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _customAmount = int.tryParse(value) ?? 0;
                          });
                        },
                      ),
                    ],
                    const SizedBox(height: AppSizes.lg),
                    Container(
                      padding: const EdgeInsets.all(AppSizes.lg),
                      decoration: BoxDecoration(
                        color: AppColors.surfMuted(context),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusLg),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                'RINGKASAN PENCAIRAN',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textT(context),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSizes.md),
                          _kv('Nilai penarikan', Formatters.rupiah(_rupiah)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Biaya admin',
                                  style: TextStyle(
                                    color: AppColors.textS(context),
                                  ),
                                ),
                              ),
                              Text(
                                'Gratis',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Total diterima',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textP(context),
                                  ),
                                ),
                              ),
                              Text(
                                Formatters.rupiah(_rupiah),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                  fontSize: 17,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                    Container(
                      padding: const EdgeInsets.all(AppSizes.md),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusMd),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.info,
                            size: 18,
                          ),
                          SizedBox(width: AppSizes.sm),
                          Expanded(
                            child: Text(
                              'Pencairan biasanya membutuhkan waktu 1–5 menit. Pastikan nomor e-wallet aktif untuk menghindari kegagalan transaksi.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textS(context),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                    Row(
                      children: [
                        Checkbox(
                          value: _confirmed,
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          onChanged: (v) =>
                              setState(() => _confirmed = v ?? false),
                        ),
                        Expanded(
                          child: Text(
                            'Saya memastikan data penarikan sudah benar',
                            style: TextStyle(
                              color: AppColors.textS(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSizes.xl),
                child: Column(
                  children: [
                    PrimaryButton(
                      label: 'Konfirmasi',
                      onPressed: _confirm,
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Batal',
                        style: TextStyle(color: AppColors.textT(context)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Row(
        children: [
          Expanded(
            child: Text(
              k,
              style: TextStyle(color: AppColors.textS(context)),
            ),
          ),
          Text(
            v,
            style: TextStyle(
              color: AppColors.textP(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
}

class _Wallet {
  final String name;
  final Color color;
  final IconData icon;
  const _Wallet(this.name, this.color, this.icon);
}
