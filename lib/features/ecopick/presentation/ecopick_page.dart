import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/labeled_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/image_source_sheet.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../greencoin/providers/greencoin_provider.dart';
import '../data/ecopick_service.dart';
import '../data/nominatim_service.dart';
import '../models/ecopick_result.dart';
import '../models/waste_category.dart';
import '../providers/ecopick_provider.dart';

// ─── Timezone helper ──────────────────────────────────────────────────────────

/// Zona waktu Jakarta (WIB = UTC+7)
DateTime _nowWib() => DateTime.now().toUtc().add(const Duration(hours: 7));

/// Nama hari singkat (Bahasa Indonesia) dari DateTime
String _dayName(DateTime d) =>
    const ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'][d.weekday % 7];

// ─── Main Page ────────────────────────────────────────────────────────────────

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

  XFile? _imageFile;

  // 4 tanggal real mulai hari ini (WIB)
  late final List<DateTime> _pickupDates;

  static const _timeSlots = ['08:00', '10:00', '13:00', '15:00'];

  // --- Lokasi ---
  double? _lat;
  double? _lon;
  String _pickupAddress = '';
  bool _locating = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    // Generate 4 hari ke depan dari hari ini (timezone WIB)
    final today = _nowWib();
    _pickupDates = List.generate(4, (i) => today.add(Duration(days: i)));
    // Minta lokasi GPS otomatis saat halaman dibuka
    _fetchLocation();
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  bool _submitting = false;

  // --- Estimasi GC ---
  int get _estimatedGc {
    final weight = double.tryParse(_weightCtrl.text.replaceAll(',', '.')) ?? 0;
    if (weight <= 0) return 0;
    final rate = _selectedCategory?.greenCoinPerKg ?? 0;
    final result = (weight * rate).round();
    return result < 0 ? 0 : result;
  }

  bool get _weightInvalid {
    final raw = _weightCtrl.text.replaceAll(',', '.').trim();
    if (raw.isEmpty) return false;
    final w = double.tryParse(raw);
    return w == null || w <= 0;
  }

  // --- Image Picker (camera or gallery) ---
  Future<void> _pickImage() async {
    final image = await pickImageWithSource(context);
    if (image != null) {
      setState(() {
        _imageFile = image;
      });
    }
  }

  // --- GPS + Nominatim ---
  Future<void> _fetchLocation() async {
    setState(() {
      _locating = true;
      _locationError = null;
    });

    try {
      // 1. Cek apakah layanan lokasi aktif
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'Layanan lokasi dinonaktifkan. Aktifkan GPS terlebih dahulu.';
          _locating = false;
        });
        return;
      }

      // 2. Cek & minta permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() {
          _locationError = 'Izin lokasi ditolak. Aktifkan dari pengaturan.';
          _locating = false;
        });
        return;
      }

      // 3. Ambil posisi GPS
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      // 4. Reverse geocoding via Nominatim
      final result = await NominatimService().reverse(pos.latitude, pos.longitude);

      if (!mounted) return;
      setState(() {
        _lat = pos.latitude;
        _lon = pos.longitude;
        _pickupAddress = result.shortAddress.isNotEmpty
            ? result.shortAddress
            : result.displayName;
        _locating = false;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _locationError = 'Waktu habis saat mengambil lokasi. Coba lagi.';
        _locating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationError = 'Gagal mendapatkan lokasi: ${e.toString()}';
        _locating = false;
      });
    }
  }

  // --- Cari Alamat Manual (Forward Geocoding) ---
  Future<void> _showAddressSearch() async {
    final result = await showModalBottomSheet<NominatimResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddressSearchSheet(),
    );
    if (result == null) return;
    if (!mounted) return;
    setState(() {
      _lat = result.lat;
      _lon = result.lon;
      _pickupAddress =
          result.shortAddress.isNotEmpty ? result.shortAddress : result.displayName;
      _locationError = null;
    });
  }

  // --- Dialog error ---
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

  // --- Submit ---
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

    // Gunakan alamat real dari Nominatim jika tersedia
    final finalAddress = _pickupAddress.isNotEmpty
        ? _pickupAddress
        : 'Alamat tidak diketahui';

    try {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        await EcoPickService().submit(
          userId: user.id,
          categoryId: _selectedCategory!.id,
          weightKg: weight,
          estimatedGc: _estimatedGc,
          pickupAddress: finalAddress,
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
        pickupAddress: finalAddress,
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
                      // ── Unggah Foto ──────────────────────────────────
                      Text(
                        'Unggah Foto Sampah',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textP(context),
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),
                      if (_imageFile != null)
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                              child: Image.file(
                                File(_imageFile!.path),
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.surf(context).withValues(alpha: 0.8),
                                ),
                                icon: const Icon(Icons.close_rounded, color: AppColors.danger),
                                onPressed: () => setState(() => _imageFile = null),
                              ),
                            ),
                          ],
                        )
                      else
                        _UploadCard(onTap: _pickImage),
                      const SizedBox(height: AppSizes.xl),

                      // ── Detail Sampah ────────────────────────────────
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

                      // ── Detail Penjemputan ───────────────────────────
                      Text(
                        'Detail Penjemputan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textP(context),
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),

                      // ── Pilih Tanggal (REAL, timezone WIB) ──────────
                      Text(
                        'Pilih Tanggal',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textP(context),
                        ),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      SizedBox(
                        height: 76,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _pickupDates.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: AppSizes.sm),
                          itemBuilder: (context, i) {
                            final d = _pickupDates[i];
                            return _DateChip(
                              day: i == 0 ? 'Hari ini' : _dayName(d),
                              date: '${d.day}',
                              selected: _selectedDay == i,
                              onTap: () =>
                                  setState(() => _selectedDay = i),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      // Label tanggal lengkap untuk chip yang dipilih
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          key: ValueKey(_selectedDay),
                          DateFormat(
                            'EEEE, d MMMM yyyy',
                            'id_ID',
                          ).format(_pickupDates[_selectedDay]),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),

                      // ── Pilih Slot Waktu ─────────────────────────────
                      Text(
                        'Pilih Slot Waktu',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textP(context),
                        ),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      Wrap(
                        spacing: AppSizes.sm,
                        runSpacing: AppSizes.sm,
                        children: List.generate(_timeSlots.length, (i) {
                          final selected = i == _selectedTimeSlot;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedTimeSlot = i),
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

                      // ── Lokasi Penjemputan ───────────────────────────
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
                          // Tombol Cari Alamat Manual
                          IconButton(
                            tooltip: 'Cari alamat',
                            onPressed: _showAddressSearch,
                            icon: const Icon(
                              Icons.search_rounded,
                              size: 20,
                              color: AppColors.primary,
                            ),
                          ),
                          // Tombol refresh GPS
                          TextButton.icon(
                            onPressed: _locating ? null : _fetchLocation,
                            icon: _locating
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.my_location_rounded,
                                    size: 16),
                            label: Text(_locating ? 'Mengambil...' : 'GPS'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.sm),
                      _LocationCard(
                        lat: _lat,
                        lon: _lon,
                        address: _pickupAddress,
                        loading: _locating,
                        error: _locationError,
                        onRetry: _fetchLocation,
                      ),
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

// ─── Upload Card ──────────────────────────────────────────────────────────────

class _UploadCard extends StatelessWidget {
  final VoidCallback onTap;

  const _UploadCard({required this.onTap});

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
                onPressed: onTap,
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

// ─── Dashed Border Container ──────────────────────────────────────────────────

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
    final path = ui.Path()..addRRect(rrect);
    _drawDashed(canvas, path, paint);
  }

  void _drawDashed(Canvas canvas, ui.Path path, Paint paint) {
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

// ─── Category Dropdown ────────────────────────────────────────────────────────

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

// ─── Date Chip ────────────────────────────────────────────────────────────────

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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: 64,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.brd(context),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              day,
              style: TextStyle(
                fontSize: day.length > 3 ? 9 : 12,
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

// ─── Location Card ────────────────────────────────────────────────────────────

class _LocationCard extends StatelessWidget {
  final double? lat;
  final double? lon;
  final String address;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;

  const _LocationCard({
    required this.lat,
    required this.lon,
    required this.address,
    required this.loading,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Area Peta ──────────────────────────────────────────────
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSizes.radiusLg),
            ),
            child: SizedBox(
              height: 160,
              child: _buildMapArea(context),
            ),
          ),

          // ── Info Alamat ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
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
                        'Lokasi Anda',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textP(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      _buildAddressText(context),
                      if (lat != null && lon != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.gps_fixed_rounded,
                              size: 11,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${lat!.toStringAsFixed(5)}, ${lon!.toStringAsFixed(5)}',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textT(context),
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildMapArea(BuildContext context) {
    // Loading state
    if (loading) {
      return Container(
        color: AppColors.primarySubtleColor(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Mengambil lokasi GPS...',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textS(context),
              ),
            ),
          ],
        ),
      );
    }

    // Error state
    if (error != null) {
      return Container(
        color: AppColors.primarySubtleColor(context),
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_off_rounded,
              color: AppColors.danger,
              size: 32,
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 14),
              label: const Text('Coba Lagi'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.lg,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    }

    // Peta OSM via flutter_map
    if (lat != null && lon != null) {
      final center = LatLng(lat!, lon!);
      return FlutterMap(
        options: MapOptions(
          initialCenter: center,
          initialZoom: 16,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.ecopoin.app',
            maxZoom: 19,
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: center,
                width: 40,
                height: 50,
                child: const _MapPin(),
              ),
            ],
          ),
        ],
      );
    }

    // Placeholder (belum ada data)
    return Container(
      color: AppColors.primarySubtleColor(context),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              color: AppColors.primaryTint(context),
              size: 36,
            ),
            const SizedBox(height: 6),
            Text(
              'Peta akan muncul setelah\nlokasi ditemukan',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textT(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressText(BuildContext context) {
    if (loading) {
      return Text(
        'Sedang mendeteksi alamat...',
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textS(context),
          fontStyle: FontStyle.italic,
        ),
      );
    }
    if (error != null && address.isEmpty) {
      return Text(
        'Alamat tidak tersedia',
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.danger,
        ),
      );
    }
    if (address.isNotEmpty) {
      return Text(
        address,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textS(context),
          height: 1.4,
        ),
      );
    }
    return Text(
      'Menunggu data lokasi...',
      style: TextStyle(
        fontSize: 12,
        color: AppColors.textT(context),
      ),
    );
  }
}

/// Pin marker di atas peta
class _MapPin extends StatelessWidget {
  const _MapPin();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.location_on_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
        // Shadow segitiga di bawah pin
        Container(
          width: 2,
          height: 10,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }
}

// ─── Bottom Bar ───────────────────────────────────────────────────────────────

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


// --- Address Search Sheet ---

class _AddressSearchSheet extends StatefulWidget {
  @override
  State<_AddressSearchSheet> createState() => _AddressSearchSheetState();
}

class _AddressSearchSheetState extends State<_AddressSearchSheet> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  List<NominatimResult> _results = [];
  bool _searching = false;
  String? _error;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 3) {
      setState(() { _results = []; _error = null; _searching = false; });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 600), () => _doSearch(value));
  }

  Future<void> _doSearch(String query) async {
    setState(() { _searching = true; _error = null; });
    try {
      final results = await NominatimService().search(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _searching = false;
        if (results.isEmpty) _error = 'Alamat tidak ditemukan. Coba kata kunci lain.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _searching = false; _error = 'Gagal mencari: ${e.toString()}'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surf(context),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, -4))],
      ),
      padding: EdgeInsets.only(bottom: bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 36, height: 4,
            decoration: BoxDecoration(color: AppColors.brd(context), borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.xl, vertical: AppSizes.sm),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
                const SizedBox(width: AppSizes.sm),
                Text('Cari Alamat', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textP(context))),
                const Spacer(),
                IconButton(icon: Icon(Icons.close_rounded, color: AppColors.textT(context)), onPressed: () => Navigator.of(context).pop()),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.xl),
            child: TextField(
              controller: _ctrl,
              focusNode: _focus,
              textInputAction: TextInputAction.search,
              onChanged: _onChanged,
              onSubmitted: (v) => _doSearch(v),
              decoration: InputDecoration(
                hintText: 'Ketik jalan, kelurahan, atau kota...',
                prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
                suffixIcon: _searching
                    ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)))
                    : _ctrl.text.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear_rounded, size: 18), onPressed: () { _ctrl.clear(); setState(() { _results = []; _error = null; }); })
                        : null,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.38),
            child: _buildResults(context),
          ),
          const SizedBox(height: AppSizes.md),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    if (_error != null && _results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(children: [
          Icon(Icons.location_off_outlined, color: AppColors.textT(context), size: 32),
          const SizedBox(height: AppSizes.sm),
          Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: AppColors.textS(context), fontSize: 13)),
        ]),
      );
    }
    if (_results.isEmpty && !_searching) {
      return Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(children: [
          Icon(Icons.search_outlined, color: AppColors.textT(context), size: 32),
          const SizedBox(height: AppSizes.sm),
          Text('Ketik minimal 3 karakter.\nContoh: "Jl. Tunjungan, Surabaya"', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textS(context), fontSize: 13, height: 1.5)),
        ]),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
      itemCount: _results.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.div(context)),
      itemBuilder: (_, i) {
        final r = _results[i];
        final short = r.shortAddress.isNotEmpty ? r.shortAddress : r.displayName;
        final detail = r.displayName.length > short.length ? r.displayName.replaceFirst('$short, ', '') : '';
        return InkWell(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          onTap: () => Navigator.of(context).pop(r),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: AppSizes.md),
            child: Row(
              children: [
                Container(width: 36, height: 36, decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle), child: const Icon(Icons.location_on_rounded, size: 18, color: AppColors.primary)),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(short, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textP(context)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (detail.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(detail, style: TextStyle(fontSize: 12, color: AppColors.textT(context)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.primary),
              ],
            ),
          ),
        );
      },
    );
  }
}
