import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/labeled_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../data/quick_login_store.dart';
import '../providers/auth_provider.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _quickLoginStore = QuickLoginStore();
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authControllerProvider.notifier).signUp(
          fullName: _name.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          password: _password.text,
        );
    if (!mounted) return;
    final state = ref.read(authControllerProvider);
    final error = state.asError?.error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
      return;
    }

    final user = state.asData?.value;
    if (user == null) return;

    await _quickLoginStore.saveAccount(
      email: _email.text.trim(),
      password: _password.text,
    );
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: 280,
                width: double.infinity,
                child: Image.asset(
                  AppIcons.registerHeader,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (_, __, ___) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF2C5F4F),
                          AppColors.primaryDark.withValues(alpha: 0.95),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -24),
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(AppSizes.radiusXl),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.xl,
                    AppSizes.xxl,
                    AppSizes.xl,
                    AppSizes.xl,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 48,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: AppSizes.lg),
                            decoration: BoxDecoration(
                              color: AppColors.border,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const Text(
                          'Daftar Akun Baru',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSizes.xs),
                        const Text(
                          'Lengkapi data diri untuk mulai menabung sampah.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppSizes.xl),
                        LabeledField(
                          label: 'Nama Lengkap',
                          child: AppTextField(
                            controller: _name,
                            hint: 'Masukkan nama lengkap Anda',
                            prefixIcon: Icons.person_outline_rounded,
                            validator: (v) =>
                                Validators.required(v, fieldName: 'Nama'),
                          ),
                        ),
                        const SizedBox(height: AppSizes.md),
                        LabeledField(
                          label: 'Email',
                          child: AppTextField(
                            controller: _email,
                            hint: 'contoh@email.com',
                            prefixIcon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: Validators.email,
                          ),
                        ),
                        const SizedBox(height: AppSizes.md),
                        LabeledField(
                          label: 'Nomor Telepon',
                          child: AppTextField(
                            controller: _phone,
                            hint: '0812xxxxxx',
                            prefixIcon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            validator: Validators.phone,
                          ),
                        ),
                        const SizedBox(height: AppSizes.md),
                        LabeledField(
                          label: 'Kata Sandi',
                          child: AppTextField(
                            controller: _password,
                            hint: 'Min. 8 karakter',
                            prefixIcon: Icons.lock_outline_rounded,
                            obscureText: _obscure,
                            validator: Validators.password,
                            suffix: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.textTertiary,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSizes.xl),
                        PrimaryButton(
                          label: 'Daftar Sekarang',
                          loading: auth.isLoading,
                          onPressed: _submit,
                        ),
                        const SizedBox(height: AppSizes.lg),
                        const Row(
                          children: [
                            Expanded(child: Divider(color: AppColors.border)),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSizes.md,
                              ),
                              child: Text(
                                'Atau daftar dengan',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: AppColors.border)),
                          ],
                        ),
                        const SizedBox(height: AppSizes.md),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.g_mobiledata_rounded,
                                  color: Color(0xFFEA4335),
                                  size: 28,
                                ),
                                label: const Text(
                                  'Google',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.radiusPill,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSizes.md),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.facebook_rounded,
                                  color: Color(0xFF1877F2),
                                ),
                                label: const Text(
                                  'Facebook',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.radiusPill,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.lg),
                        Center(
                          child: Wrap(
                            children: [
                              const Text(
                                'Sudah punya akun? ',
                                style:
                                    TextStyle(color: AppColors.textSecondary),
                              ),
                              GestureDetector(
                                onTap: () => context.go('/login'),
                                child: const Text(
                                  'Masuk',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
