import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/providers/auth_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Akun'),
      ),
      body: SafeArea(
        child: MotionFadeSlide(
          delayMs: 40,
          child: ListView(
            padding: const EdgeInsets.all(AppSizes.xl),
            children: [
              const SizedBox(height: AppSizes.md),
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryLight,
                          width: 3,
                        ),
                        color: AppColors.primaryLight,
                      ),
                      child: const Icon(
                        Icons.person,
                        color: AppColors.primary,
                        size: 56,
                      ),
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.md),
              Center(
                child: Text(
                  user?.fullName ?? 'User',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textP(context),
                  ),
                ),
              ),
              Center(
                child: Text(
                  user?.email ?? '',
                  style: TextStyle(color: AppColors.textS(context)),
                ),
              ),
              const SizedBox(height: AppSizes.xl),
              Text(
                'Informasi Profil',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textP(context),
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              AppCard(
                child: Column(
                  children: [
                    _InfoRow(
                      label: 'NAMA LENGKAP',
                      value: user?.fullName ?? '-',
                    ),
                    const Divider(height: AppSizes.lg),
                    _InfoRow(label: 'EMAIL', value: user?.email ?? '-'),
                    const Divider(height: AppSizes.lg),
                    _InfoRow(
                      label: 'NOMOR TELEPON',
                      value: user?.phone ?? '-',
                    ),
                    const Divider(height: AppSizes.lg),
                    const _InfoRow(
                      label: 'LOKASI',
                      value: 'Jakarta, Indonesia',
                      prefixIcon: Icons.location_on_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.xl),
              Text(
                'Keamanan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textP(context),
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kata Sandi Saat Ini',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textS(context),
                      ),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    TextField(
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textT(context),
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                    Text(
                      'Kata Sandi Baru',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textS(context),
                      ),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    TextField(
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Masukkan kata sandi baru',
                        suffixIcon: Icon(
                          Icons.lock_outline_rounded,
                          color: AppColors.textT(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.xl),
              PrimaryButton(
                label: 'Simpan Perubahan',
                icon: Icons.save_outlined,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Perubahan tersimpan')),
                  );
                },
              ),
              const SizedBox(height: AppSizes.md),
              SecondaryButton(
                label: 'Keluar Akun',
                icon: Icons.logout_rounded,
                borderColor: AppColors.danger,
                labelColor: AppColors.danger,
                onPressed: () async {
                  await ref.read(authControllerProvider.notifier).signOut();
                  if (!context.mounted) return;
                  context.go('/');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? prefixIcon;

  const _InfoRow({
    required this.label,
    required this.value,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textT(context),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (prefixIcon != null) ...[
              Icon(prefixIcon, size: 16, color: AppColors.primary),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textP(context),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
