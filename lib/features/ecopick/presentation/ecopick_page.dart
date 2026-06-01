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
import '../data/ecopick_service.dart';
import '../models/ecopick_result.dart';
import '../models/waste_category.dart';
import '../providers/ecopick_provider.dart';

class EcoPickPage extends ConsumerStatefulWidget {
  const EcoPickPage({super.key});

  @override
  ConsumerState<EcoPickPage> createState() => _EcoPickPageState();
}

class _EcoPickPageState extends ConsumerState<EcoPickPage> {
  final _weightCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  WasteCategory? _selectedCategory;
  int _selectedDay = 0;
  int _selectedTimeSlot = 0;

  static const _timeSlots = ['08:00', '10:00', '13:00', '15:00'];

  @override
  void dispose() {
    _weightCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  bool _submitting = false;

  int get _estimatedGc {
    final weight = double.tryParse(_weightCtrl.text.replaceAll(',', '.')) ?? 0;
    if (weight <= 0) return 0;
    final rate = _selectedCategory?.greenCoinPerKg ?? 0;
    final result = (weight * rate).round();
    return result < 0 ? 0 : result;
  }

  bool get _weightInvalid {
    final raw = _weightCtrl.text.replaceAll(',', '.').trim();
    if (raw.isEmpty) return false; // empty is "neutral", not invalid
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

  Future<void> _onConfirm(List<WasteCategory> categories) async {
    final raw = _weightCtrl.text.replaceAll(',', '.').trim();
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
    const pickupAddress = 'Jl. Hijau No. 12, Jakarta Selatan';
    try {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        await EcoPickService().submit(
          userId: user.id,
          categoryId: _selectedCategory!.id,
          weightKg: weight,
          estimatedGc: _estimatedGc,
          pickupAddress: pickupAddress,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        );
        ref.invalidate(dashboardProvider);
        ref.invalidate(greenCoinTransactionsProvider);
        ref.invalidate(greenCoinBalanceProvider);
      }
      if (!mounted) return;
      context.push('/ecopick/success', extra: EcoPickResult(
        categoryName: _selectedCategory!.name,
        weightKg: weight,
        estimatedGc: _estimatedGc,
        pickupAddress: pickupAddress,
      ));
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
    final categoriesAsync = ref.watch(wasteCategoriesProvider);
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('EcoPick'),
      ),
      body: SafeArea(
        bottom: false,
        child: categoriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(e.toString())),
          data: (categories) => Column(
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
                      Text(
                        'Unggah Foto Sampah',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textP(context),
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),
                      _UploadCard(),
                      const SizedBox(height: AppSizes.xl),
                      Text(
                        'Detail Sampah',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textP(context),
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),
                      LabeledField(
                        label: 'Kategori',
                        child: _CategoryDropdown(
                          categories: categories,
                          selected: _selectedCategory,
                          onChanged: (c) =>
                              setState(() => _selectedCategory = c),
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),
                      LabeledField(
                        label: 'Estimasi Berat (kg)',
                        child: AppTextField(
                          controller: _weightCtrl,
                          hint: 'Contoh: 5',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: false,
                          ),
                          inputFormatters: const [
                            PositiveNumberInputFormatter(),
                          ],
                          suffix: Padding(
                            padding: EdgeInsets.only(right: AppSizes.lg),
                            child: Align(
                              widthFactor: 1.0,
                              child: Text(
                                'kg',
                                style: TextStyle(
                                  color: AppColors.textT(context),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),
                      LabeledField(
                        label: 'Catatan (Opsional)',
                        child: AppTextField(
                          controller: _notesCtrl,
                          hint: 'Tulis catatan tambahan untuk kurir...',
                          maxLines: 3,
                        ),
                      ),
                      const SizedBox(height: AppSizes.xl),
                      Text(
                        'Detail Penjemputan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textP(context),
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),
                      const Text(
                        'Pilih Tanggal',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      SizedBox(
                        height: 76,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: 4,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: AppSizes.sm),
                          itemBuilder: (context, i) => _DateChip(
                            day: ['Sen', 'Sel', 'Rab', 'Kam'][i],
                            date: '${22 + i}',
                            selected: _selectedDay == i,
                            onTap: () => setState(() => _selectedDay = i),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),
                      const Text(
                        'Pilih Slot Waktu',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      Wrap(
                        spacing: AppSizes.sm,
                        runSpacing: AppSizes.sm,
                        children: List.generate(_timeSlots.length, (i) {
                          final selected = i == _selectedTimeSlot;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedTimeSlot = i),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.lg,
                                vertical: AppSizes.sm,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.primaryLight
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
                                _timeSlots[i],
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.textS(context),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: AppSizes.xl),
                      Row(
                        children: [
                          Text(
                            'Lokasi Penjemputan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textP(context),
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {},
                            child: const Text('Ubah'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.sm),
                      _LocationCard(),
                    ],
                  ),
                ),
              ),
              MotionFadeSlide(
                delayMs: 180,
                child: _BottomBar(
                  estimated: _estimatedGc,
                  invalid: _weightInvalid,
                  submitting: _submitting,
                  onConfirm: () => _onConfirm(categories),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DottedDashedContainer(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.xxl),
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
              'Ambil Foto atau Unggah',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textP(context),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.xl),
              child: Text(
                'Pastikan foto sampah terlihat jelas agar kurir mudah mengenali',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textT(context),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.md),
            SizedBox(
              width: 160,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(40),
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                  ),
                ),
                child: const Text(
                  'Unggah Foto',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DottedDashedContainer extends StatelessWidget {
  final Widget child;
  const DottedDashedContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primarySubtleColor(context),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        child: child,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.5)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    const radius = AppSizes.radiusLg;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    _drawDashed(canvas, path, paint);
  }

  void _drawDashed(Canvas canvas, Path path, Paint paint) {
    const dashLen = 8.0;
    const gap = 6.0;
    for (final metric in path.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        final end = (dist + dashLen).clamp(0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(dist, end), paint);
        dist = end + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _CategoryDropdown extends StatelessWidget {
  final List<WasteCategory> categories;
  final WasteCategory? selected;
  final ValueChanged<WasteCategory?> onChanged;

  const _CategoryDropdown({
    required this.categories,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.surfMuted(context),
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<WasteCategory>(
          value: selected,
          isExpanded: true,
          hint: Text(
            'Pilih kategori sampah',
            style: TextStyle(color: AppColors.textT(context)),
          ),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textT(context),
          ),
          items: categories
              .map(
                (c) => DropdownMenuItem(
                  value: c,
                  child: Text(c.name),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String day;
  final String date;
  final bool selected;
  final VoidCallback onTap;

  const _DateChip({
    required this.day,
    required this.date,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.brd(context),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              day,
              style: TextStyle(
                fontSize: 12,
                color: selected ? Colors.white : AppColors.textS(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              date,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : AppColors.textP(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSizes.radiusLg),
            ),
            child: Container(
              height: 120,
              color: const Color(0xFFE9F2DA),
              child: const Center(
                child: Icon(
                  Icons.location_on_rounded,
                  color: AppColors.primary,
                  size: 36,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.home_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rumah Utama',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textP(context),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Jl. Hijau No. 12, Kel. Lestari, Kec. Bumi, Jakarta Selatan, 12345',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textS(context),
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

class _BottomBar extends StatelessWidget {
  final int estimated;
  final bool invalid;
  final bool submitting;
  final VoidCallback onConfirm;

  const _BottomBar({
    required this.estimated,
    required this.onConfirm,
    this.invalid = false,
    this.submitting = false,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.xl,
          vertical: AppSizes.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surf(context),
          border: Border(top: BorderSide(color: AppColors.div(context))),
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
                color: invalid
                    ? const Color(0x1AEF4444)
                    : AppColors.primarySubtle,
                borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                border: invalid
                    ? Border.all(color: AppColors.danger.withValues(alpha: 0.4))
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    invalid ? Icons.error_outline : Icons.savings_outlined,
                    color: invalid ? AppColors.danger : AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Text(
                    invalid ? 'Nominal Tidak Valid' : 'Estimasi Pendapatan',
                    style: TextStyle(
                      color: invalid ? AppColors.danger : AppColors.textS(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    invalid ? '—' : '+${Formatters.greenCoin(estimated)}',
                    style: TextStyle(
                      color: invalid ? AppColors.danger : AppColors.primary,
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
                    loading: submitting,
                    onPressed: onConfirm,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
