import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/labeled_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../data/quick_login_store.dart';
import '../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _quickLoginStore = QuickLoginStore();
  List<QuickLoginAccount> _quickLoginAccounts = const [];
  bool _obscure = true;
  bool _quickLoginSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadQuickLoginAccounts();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authControllerProvider.notifier)
        .signIn(_email.text.trim(), _password.text);
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

    final accounts = await _quickLoginStore.saveAccount(
      email: _email.text.trim(),
      password: _password.text,
    );
    if (!mounted) return;
    setState(() => _quickLoginAccounts = accounts);

    if (user.role == UserRole.admin) {
      context.go('/admin');
    } else {
      context.go('/home');
    }
  }

  Future<void> _loadQuickLoginAccounts() async {
    final accounts = await _quickLoginStore.loadAccounts();
    if (!mounted) return;
    setState(() => _quickLoginAccounts = accounts);
  }

  Future<void> _selectQuickLoginAccount(QuickLoginAccount account) async {
    if (_quickLoginSubmitting || ref.read(authControllerProvider).isLoading) {
      return;
    }
    _email.text = account.email;
    _password.text = account.password;
    _formKey.currentState?.validate();
    setState(() => _quickLoginSubmitting = true);
    await _submit();
    if (!mounted) return;
    setState(() => _quickLoginSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              SizedBox(
                height: 300,
                width: double.infinity,
                child: Image.asset(
                  AppIcons.loginHeader,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (_, __, ___) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.95),
                          AppColors.primaryDark,
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
                        Container(
                          margin: const EdgeInsets.only(bottom: AppSizes.lg),
                          child: Center(
                            child: Container(
                              width: 48,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppColors.border,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                        const Text(
                          'Masuk ke Akun Anda',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSizes.xs),
                        const Text(
                          'Masukkan detail akun untuk melanjutkan.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppSizes.xl),
                        const Text(
                          'Login Cepat',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSizes.md),
                        SizedBox(
                          height: 44,
                          child: _quickLoginAccounts.isEmpty
                              ? const _QuickLoginEmpty()
                              : ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: _quickLoginAccounts.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: AppSizes.sm),
                                  itemBuilder: (context, index) {
                                    final account = _quickLoginAccounts[index];
                                    return _QuickLoginButton(
                                      email: account.email,
                                      loading: _quickLoginSubmitting &&
                                          _email.text == account.email,
                                      onPressed: () =>
                                          _selectQuickLoginAccount(account),
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: AppSizes.xl),
                        LabeledField(
                          label: 'Email',
                          child: AppTextField(
                            controller: _email,
                            hint: 'Alamat email Anda',
                            prefixIcon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: Validators.email,
                          ),
                        ),
                        const SizedBox(height: AppSizes.md),
                        LabeledField(
                          label: 'Kata Sandi',
                          child: AppTextField(
                            controller: _password,
                            hint: '••••••••',
                            prefixIcon: Icons.lock_outline_rounded,
                            obscureText: _obscure,
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
                            validator: Validators.password,
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            child: const Text('Lupa Kata Sandi?'),
                          ),
                        ),
                        const SizedBox(height: AppSizes.md),
                        PrimaryButton(
                          label: 'Masuk Sekarang',
                          loading: auth.isLoading,
                          onPressed: _submit,
                        ),
                        const SizedBox(height: AppSizes.xl),
                        const Row(
                          children: [
                            Expanded(child: Divider(color: AppColors.border)),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSizes.md,
                              ),
                              child: Text(
                                'ATAU MASUK DENGAN',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textTertiary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: AppColors.border)),
                          ],
                        ),
                        const SizedBox(height: AppSizes.md),
                        const Row(
                          children: [
                            Expanded(
                              child: _SocialButton(
                                label: 'Google',
                                icon: Icons.g_mobiledata_rounded,
                                color: Color(0xFFEA4335),
                              ),
                            ),
                            SizedBox(width: AppSizes.md),
                            Expanded(
                              child: _SocialButton(
                                label: 'Facebook',
                                icon: Icons.facebook_rounded,
                                color: Color(0xFF1877F2),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.xl),
                        Center(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'Belum punya akun? ',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.go('/register'),
                                behavior: HitTestBehavior.opaque,
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    'Daftar',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
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

class _QuickLoginEmpty extends StatelessWidget {
  const _QuickLoginEmpty();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_add_alt_1_rounded,
              size: 18,
              color: AppColors.textTertiary,
            ),
            SizedBox(width: AppSizes.sm),
            Text(
              'Login dulu untuk menyimpan akun',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickLoginButton extends StatelessWidget {
  final String email;
  final bool loading;
  final VoidCallback onPressed;

  const _QuickLoginButton({
    required this.email,
    this.loading = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primarySubtle,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: InkWell(
        onTap: loading ? null : onPressed,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Container(
          constraints: const BoxConstraints(minWidth: 132, maxWidth: 214),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: AppSizes.sm,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.22),
            ),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: loading
                    ? const Padding(
                        padding: EdgeInsets.all(6),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 17,
                      ),
              ),
              const SizedBox(width: AppSizes.sm),
              Flexible(
                child: Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
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

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        ),
      ),
      icon: Icon(icon, color: color, size: 24),
      label: Text(
        label,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
