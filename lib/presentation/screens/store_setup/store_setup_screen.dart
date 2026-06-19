import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../domain/entities/store_profile.dart';
import '../../../services/auth_service.dart';
import '../../providers/providers.dart';
import '../../widgets/sangam_logo.dart';
import '../auth/login_screen.dart' show ContextSnack;

class StoreSetupScreen extends ConsumerStatefulWidget {
  const StoreSetupScreen({super.key});
  @override
  ConsumerState<StoreSetupScreen> createState() => _StoreSetupScreenState();
}

class _StoreSetupScreenState extends ConsumerState<StoreSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _ownerCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _saving = false;
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ownerCtrl.dispose();
    _locationCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _finish({required bool withDemo}) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final auth = ref.read(authServiceProvider);
    try {
      // 1. Create the owner (admin) account and start the session.
      final admin = await auth.createAdmin(
        name: _ownerCtrl.text.trim(),
        username: _userCtrl.text.trim(),
        password: _passCtrl.text,
      );
      await ref.read(currentUserProvider.notifier).setUser(admin);

      // 2. Save the store profile.
      await ref.read(storeProfileProvider.notifier).save(StoreProfile(
            name: _nameCtrl.text.trim(),
            ownerName: _ownerCtrl.text.trim(),
            location: _locationCtrl.text.trim(),
          ));

      // 3. Seed demo or start fresh.
      final source = ref.read(localSourceProvider);
      if (withDemo) {
        await source.seedDemoData();
      } else {
        await source.startFresh();
      }

      ref.invalidate(transactionsStreamProvider);
      ref.invalidate(customersStreamProvider);
      ref.invalidate(todayTotalsProvider);
      ref.invalidate(overdueCustomersProvider);
      ref.invalidate(usersProvider);

      if (mounted) {
        context.go('/dashboard');
        context.showSnack(withDemo ? 'Loaded sample data — explore freely!' : 'Your shop is ready!');
      }
    } on DuplicateUsernameException {
      if (mounted) context.showSnack('That username is taken, try another', isError: true);
    } catch (_) {
      if (mounted) context.showSnack('Could not finish setup, try again', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
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
              const SizedBox(height: 28),

              SangamLogo(size: 56)
                  .animate().scale(begin: const Offset(0.7, 0.7), end: const Offset(1, 1), duration: 500.ms, curve: Curves.elasticOut),
              const SizedBox(height: 22),

              Text('Set up your shop', style: AppTextStyles.h1)
                  .animate(delay: 150.ms).fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 8),
              Text('Create the owner (admin) account. You can add staff logins later from Settings.',
                      style: AppTextStyles.body)
                  .animate(delay: 250.ms).fadeIn(duration: 500.ms),

              const SizedBox(height: 28),

              _label('SHOP NAME'),
              _field(_nameCtrl, 'e.g. Sharma General Store', cap: TextCapitalization.words,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your shop name' : null),

              _label('OWNER NAME'),
              _field(_ownerCtrl, 'e.g. Smriti Sharma', cap: TextCapitalization.words,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter the owner name' : null),

              _label('LOCATION (optional)'),
              _field(_locationCtrl, 'e.g. Patna, Bihar', cap: TextCapitalization.words,
                  formatters: [LengthLimitingTextInputFormatter(60)]),

              const SizedBox(height: 8),
              Container(height: 1, color: AppColors.borderLight),
              const SizedBox(height: 16),

              _label('ADMIN USERNAME'),
              _field(_userCtrl, 'e.g. smriti', autocorrect: false,
                  formatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                  validator: (v) => (v == null || v.trim().length < 3) ? 'At least 3 characters, no spaces' : null),

              _label('ADMIN PASSWORD'),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscure,
                style: AppTextStyles.bodyMd,
                validator: (v) => (v == null || v.length < 4) ? 'Use at least 4 characters' : null,
                decoration: InputDecoration(
                  hintText: 'Choose a password',
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: _saving ? null : () => _finish(withDemo: false),
                  child: _saving
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : const Text('Create shop & start'),
                ),
              ).animate(delay: 360.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity, height: 52,
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : () => _finish(withDemo: true),
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: const Text('Create with sample data'),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Text('Sample data adds demo customers so you can explore.\nClear it anytime from Settings.',
                    textAlign: TextAlign.center, style: AppTextStyles.caption),
              ),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(t, style: AppTextStyles.labelCaps),
      );

  Widget _field(
    TextEditingController ctrl,
    String hint, {
    TextCapitalization cap = TextCapitalization.none,
    bool autocorrect = true,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: ctrl,
        textCapitalization: cap,
        autocorrect: autocorrect,
        textInputAction: TextInputAction.next,
        inputFormatters: formatters,
        validator: validator,
        style: AppTextStyles.bodyMd,
        decoration: InputDecoration(hintText: hint),
      );
}
