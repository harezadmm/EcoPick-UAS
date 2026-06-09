import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/labeled_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/image_source_sheet.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/profile_service.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _currentPwCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _savingProfile = false;
  bool _savingPassword = false;
  bool _uploadingAvatar = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _currentPwCtrl.dispose();
    _newPwCtrl.dispose();
    super.dispose();
  }

  void _hydrate() {
    if (_initialized) return;
    final user = ref.read(currentUserProvider);
    _nameCtrl.text = user?.fullName ?? '';
    _emailCtrl.text = user?.email ?? '';
    _phoneCtrl.text = user?.phone ?? '';
    _initialized = true;
  }

  Future<void> _changeAvatar() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final picked = await pickImageWithSource(context);
    if (picked == null) return;

    setState(() => _uploadingAvatar = true);
    try {
      final url = await ProfileService().uploadAvatar(
        userId: user.id,
        file: File(picked.path),
      );
      ref.read(currentUserProvider.notifier).state =
          user.copyWith(avatarUrl: url);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto profil diperbarui')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengunggah foto: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _saveProfile() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    if (name.isEmpty) {
      _toast('Nama lengkap tidak boleh kosong');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      _toast('Email tidak valid');
      return;
    }

    setState(() => _savingProfile = true);
    try {
      final updated = await ProfileService().updateProfile(
        userId: user.id,
        fullName: name,
        email: email,
        phone: phone,
      );
      if (updated != null) {
        ref.read(currentUserProvider.notifier).state = updated;
      }
      if (!mounted) return;
      _toast('Profil berhasil diperbarui');
    } catch (e) {
      if (!mounted) return;
      _toast('Gagal menyimpan profil: $e');
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _changePassword() async {
    final newPw = _newPwCtrl.text;
    if (newPw.length < 8) {
      _toast('Kata sandi baru minimal 8 karakter');
      return;
    }
    setState(() => _savingPassword = true);
    try {
      await ProfileService().updatePassword(newPw);
      if (!mounted) return;
      _currentPwCtrl.clear();
      _newPwCtrl.clear();
      _toast('Kata sandi berhasil diubah');
    } catch (e) {
      if (!mounted) return;
      _toast('Gagal mengubah kata sandi: $e');
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    _hydrate();

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
                child: GestureDetector(
                  onTap: _uploadingAvatar ? null : _changeAvatar,
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
                          image: (user?.avatarUrl != null &&
                                  user!.avatarUrl!.isNotEmpty)
                              ? DecorationImage(
                                  image: NetworkImage(user.avatarUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: (user?.avatarUrl == null ||
                                (user?.avatarUrl?.isEmpty ?? true))
                            ? const Icon(
                                Icons.person,
                                color: AppColors.primary,
                                size: 56,
                              )
                            : null,
                      ),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: _uploadingAvatar
                            ? const Padding(
                                padding: EdgeInsets.all(6),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.edit_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                      ),
                    ],
                  ),
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

              // ── Edit Profil ─────────────────────────────────────────
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
                    LabeledField(
                      label: 'Nama Lengkap',
                      child: AppTextField(
                        controller: _nameCtrl,
                        hint: 'Nama lengkap',
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                    LabeledField(
                      label: 'Email',
                      child: AppTextField(
                        controller: _emailCtrl,
                        hint: 'email@contoh.com',
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                    LabeledField(
                      label: 'Nomor Telepon',
                      child: AppTextField(
                        controller: _phoneCtrl,
                        hint: '08xxxxxxxxxx',
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                    const SizedBox(height: AppSizes.lg),
                    PrimaryButton(
                      label: 'Simpan Profil',
                      icon: Icons.save_outlined,
                      loading: _savingProfile,
                      onPressed: _savingProfile ? null : _saveProfile,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.xl),

              // ── Ubah Kata Sandi ─────────────────────────────────────
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
                      controller: _currentPwCtrl,
                      obscureText: _obscureCurrent,
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureCurrent
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textT(context),
                          ),
                          onPressed: () => setState(
                              () => _obscureCurrent = !_obscureCurrent),
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
                      controller: _newPwCtrl,
                      obscureText: _obscureNew,
                      decoration: InputDecoration(
                        hintText: 'Minimal 8 karakter',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNew
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textT(context),
                          ),
                          onPressed: () =>
                              setState(() => _obscureNew = !_obscureNew),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.lg),
                    PrimaryButton(
                      label: 'Ubah Kata Sandi',
                      icon: Icons.lock_outline_rounded,
                      loading: _savingPassword,
                      onPressed: _savingPassword ? null : _changePassword,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.xl),
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
