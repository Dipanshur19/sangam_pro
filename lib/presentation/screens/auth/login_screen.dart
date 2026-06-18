import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../domain/entities/app_user.dart';
import '../../providers/providers.dart';
import '../../widgets/sangam_logo.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  UserRole _role = UserRole.admin;
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    final user = await ref.read(currentUserProvider.notifier).login(
          username: _userCtrl.text.trim(),
          password: _passCtrl.text,
          role: _role,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    if (user != null) {
      context.go('/dashboard');
      context.showSnack('Welcome back, ${user.name}!');
    } else {
      context.showSnack('Wrong ${_role.label.toLowerCase()} username or password', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 48),

              Center(
                child: SangamLogo(size: 84)
                    .animate().scale(begin: const Offset(0.7, 0.7), end: const Offset(1, 1), duration: 600.ms, curve: Curves.elasticOut),
              ),
              const SizedBox(height: 18),
              Center(child: Text('Sangam', style: AppTextStyles.h1.copyWith(letterSpacing: -0.5)))
                  .animate(delay: 150.ms).fadeIn(),
              const SizedBox(height: 4),
              Center(child: Text('Sab ka ek hisaab', style: AppTextStyles.body))
                  .animate(delay: 200.ms).fadeIn(),

              const SizedBox(height: 40),

              // Role selector
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceTinted,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Row(children: [
                  _roleTab(UserRole.admin, Icons.shield_outlined),
                  _roleTab(UserRole.staff, Icons.person_outline_rounded),
                ]),
              ).animate(delay: 280.ms).fadeIn(duration: 400.ms),

              const SizedBox(height: 24),

              Text(_role == UserRole.admin ? 'Owner login' : 'Staff login', style: AppTextStyles.h3),
              const SizedBox(height: 4),
              Text(
                _role == UserRole.admin
                    ? 'Full access to add, edit and manage your shop.'
                    : 'Log in with the username and password your owner gave you.',
                style: AppTextStyles.bodySm,
              ),
              const SizedBox(height: 20),

              Text('USERNAME', style: AppTextStyles.labelCaps),
              const SizedBox(height: 8),
              TextFormField(
                controller: _userCtrl,
                autocorrect: false,
                textInputAction: TextInputAction.next,
                inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                style: AppTextStyles.bodyMd,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your username' : null,
                decoration: const InputDecoration(hintText: 'e.g. smriti', prefixIcon: Icon(Icons.alternate_email_rounded, size: 18)),
              ),
              const SizedBox(height: 16),

              Text('PASSWORD', style: AppTextStyles.labelCaps),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscure,
                style: AppTextStyles.bodyMd,
                validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
                onFieldSubmitted: (_) => _login(),
                decoration: InputDecoration(
                  hintText: '••••••',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              _GradientButton(label: 'Log in', loading: _loading, onTap: _login)
                  .animate(delay: 360.ms).fadeIn(duration: 400.ms),

              const SizedBox(height: 16),
              Center(
                child: Text(
                  'New here? Create your shop from the welcome screen.',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _roleTab(UserRole role, IconData icon) {
    final selected = _role == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _role = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: selected ? AppShadows.sm : [],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 16, color: selected ? AppColors.saffron : AppColors.text3),
            const SizedBox(width: 6),
            Text(role.label,
                style: AppTextStyles.btnSm.copyWith(color: selected ? AppColors.saffron : AppColors.text3)),
          ]),
        ),
      ),
    );
  }
}

// ── Shared widgets ──────────────────────────────────────

class _GradientButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onTap;
  const _GradientButton({required this.label, required this.loading, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: loading ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 58,
          decoration: BoxDecoration(
            gradient: onTap != null ? AppGradients.saffron : const LinearGradient(colors: [Color(0xFFCBD5E1), Color(0xFFB8C2CF)]),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: onTap != null ? AppShadows.saffron : [],
          ),
          child: Center(
            child: loading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : Text(label, style: AppTextStyles.btn.copyWith(color: Colors.white)),
          ),
        ),
      );
}

extension ContextSnack on BuildContext {
  void showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.text1,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      margin: const EdgeInsets.all(16),
    ));
  }
}
