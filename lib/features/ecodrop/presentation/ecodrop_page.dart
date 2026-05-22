import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/labeled_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../greencoin/providers/greencoin_provider.dart';
import '../../ecopick/models/waste_category.dart';
import '../../ecopick/presentation/ecopick_page.dart';
import '../../ecopick/providers/ecopick_provider.dart';
import '../data/ecodrop_service.dart';

class EcoDropPage extends ConsumerStatefulWidget {
  const EcoDropPage({super.key});

  @override
  ConsumerState<EcoDropPage> createState() => _EcoDropPageState();
}

class _EcoDropPageState extends ConsumerState<EcoDropPage> {
  final _weight = TextEditingController();
  final _notes = TextEditingController();
  WasteCategory? _selectedCategory;
  bool _submitting = false;

  @override
  void dispose() {
    _weight.dispose();
    _notes.dispose();
    super.dispose();
  }

  int get _estimatedGc {
    final weight = double.tryParse(_weight.text.replaceAll(',', '.')) ?? 0;
    if (weight <= 0) return 0;
    final rate = _selectedCategory?.greenCoinPerKg ?? 0;
    final result = (weight * rate).round();
    return result < 0 ? 0 : result;
  }

  bool get _weightInvalid {
    final raw = _weight.text.replaceAll(',', '.').trim();
    if (raw.isEmpty) return false;
    final w = double.tryParse(raw);
    return w == null || w <= 0;
  }

  Future<void> _showInvalidPopup(String message) async {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.danger),
            SizedBox(width: AppSizes.sm),
            Text('Input tidak valid'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  Future<void> _onConfirm() async {
    final raw = _weight.text.replaceAll(',', '.').trim();
    final weight = double.tryParse(raw);

    if (_selectedCategory == null) {
      await _showInvalidPopup('Pilih kategori sampah terlebih dahulu.');
      return;
    }
    if (raw.isEmpty || weight == null) {
      await _showInvalidPopup('Masukkan estimasi berat sampah dalam kilogram.');
      return;
    }
    if (weight <= 0) {
      await _showInvalidPopup(
        'Berat sampah harus lebih dari 0 kg. Mohon masukkan nilai positif.',
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        await EcoDropService().submit(
          userId: user.id,
          categoryId: _selectedCategory!.id,
          weightKg: weight,
          estimatedGc: _estimatedGc,
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        );
        ref.invalidate(dashboardProvider);
        ref.invalidate(greenCoinTransactionsProvider);
        ref.invalidate(greenCoinBalanceProvider);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('EcoDrop terkirim. Menunggu persetujuan admin.'),
        ),
      );
      context.push('/ecodrop/success');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(wasteCategoriesProvider);
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('EcoDrop'),
      ),
      body: SafeArea(
        bottom: false,
        child: categories.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(e.toString())),
          data: (cats) => Column(
            children: [
              Expanded(
                child: MotionFadeSlide(
                  delayMs: 40,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.xl,
                      AppSizes.md,
                      AppSizes.xl,
                      AppSizes.xl,
                    ),
                    children: [
                      _BankSampahCard(),
                      const SizedBox(height: AppSizes.xl),
                      Text(
                        'Detail Pengiriman',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textP(context),
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),
                      LabeledField(
                        label: 'Kategori Sampah',
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.lg),
                          decoration: BoxDecoration(
                            color: AppColors.surfMuted(context),
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusPill),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<WasteCategory>(
                              value: _selectedCategory,
                              isExpanded: true,
                              hint: Text(
                                'Pilih kategori sampah',
                                style: TextStyle(color: AppColors.textT(context)),
                              ),
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                              ),
                              items: cats
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedCategory = v),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),
                      LabeledField(
                        label: 'Estimasi Berat (kg)',
                        child: AppTextField(
                          controller: _weight,
                          hint: '0.0',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: false,
                          ),
                          inputFormatters: const [
                            PositiveNumberInputFormatter(),
                          ],
                          onChanged: (_) => setState(() {}),
                          suffix: Padding(
                            padding: EdgeInsets.only(right: AppSizes.lg),
                            child: Align(
                              widthFactor: 1.0,
                              child: Text(
                                'KG',
                                style: TextStyle(
                                  color: AppColors.textT(context),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),
                      LabeledField(
                        label: 'Catatan (Opsional)',
                        child: AppTextField(
                          controller: _notes,
                          hint: 'Contoh: Plastik sudah dibersihkan',
                          maxLines: 3,
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),
                      const Text(
                        'Foto Bukti',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      DottedDashedContainer(
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: AppSizes.xl),
                          child: Column(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryLight,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt_outlined,
                                  color: AppColors.primary,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: AppSizes.md),
                              Text(
                                'Unggah foto sampah Anda',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textP(context),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Maks. 5MB (JPG, PNG)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textT(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              MotionFadeSlide(
                delayMs: 180,
                child: SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.xl,
                      vertical: AppSizes.md,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surf(context),
                      border: Border(
                        top: BorderSide(color: AppColors.div(context)),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.lg,
                            vertical: AppSizes.sm,
                          ),
                          decoration: BoxDecoration(
                            color: _weightInvalid
                                ? const Color(0x1AEF4444)
                                : AppColors.primarySubtle,
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusPill),
                            border: _weightInvalid
                                ? Border.all(
                                    color: AppColors.danger
                                        .withValues(alpha: 0.4),
                                  )
                                : null,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _weightInvalid
                                    ? Icons.error_outline
                                    : Icons.savings_outlined,
                                color: _weightInvalid
                                    ? AppColors.danger
                                    : AppColors.primary,
                                size: 18,
                              ),
                              const SizedBox(width: AppSizes.sm),
                              Text(
                                _weightInvalid
                                    ? 'Nominal Tidak Valid'
                                    : 'Estimasi Pendapatan',
                                style: TextStyle(
                                  color: _weightInvalid
                                      ? AppColors.danger
                                      : AppColors.textS(context),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _weightInvalid
                                    ? '—'
                                    : '+${Formatters.greenCoin(_estimatedGc)}',
                                style: TextStyle(
                                  color: _weightInvalid
                                      ? AppColors.danger
                                      : AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSizes.md),
                        Row(
                          children: [
                            Expanded(
                              child: SecondaryButton(
                                label: 'Batal',
                                onPressed: () => context.go('/home'),
                              ),
                            ),
                            const SizedBox(width: AppSizes.md),
                            Expanded(
                              flex: 2,
                              child: PrimaryButton(
                                label: 'Konfirmasi',
                                loading: _submitting,
                                onPressed: _onConfirm,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BankSampahCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                  ),
                  child: Text(
                    'Sedang Buka • 08:00 – 16:00',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  'Bank Sampah Induk Surabaya',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textP(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Jl. Ngagel Tim. No.26, Surabaya',
                  style: TextStyle(
                    color: AppColors.textS(context),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(AppSizes.radiusLg),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 140,
                  width: double.infinity,
                  color: const Color(0xFFCBE9D6),
                  child: const Center(
                    child: Icon(
                      Icons.map_outlined,
                      color: AppColors.primaryDark,
                      size: 40,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.lg,
                    vertical: AppSizes.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surf(context),
                    borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.navigation_rounded,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Petunjuk Arah',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
