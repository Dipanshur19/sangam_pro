import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../domain/entities/store_profile.dart';
import '../../providers/providers.dart';
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
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ownerCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _finish({required bool withDemo}) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final profile = StoreProfile(
      name: _nameCtrl.text.trim(),
      ownerName: _ownerCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
    );

    await ref.read(storeProfileProvider.notifier).save(profile);

    final source = ref.read(localSourceProvider);
    if (withDemo) {
      await source.seedDemoData();
    } else {
      await source.startFresh();
    }

    // Refresh data providers so the dashboard reflects the choice immediately.
    ref.invalidate(transactionsStreamProvider);
    ref.invalidate(customersStreamProvider);
    ref.invalidate(todayTotalsProvider);
    ref.invalidate(overdueCustomersProvider);

    if (mounted) {
      context.go('/dashboard');
      context.showSnack(withDemo ? 'Loaded sample data — explore freely!' : 'Your store is ready!');
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
              const SizedBox(height: 36),

              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  gradient: AppGradients.saffron,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: AppShadows.saffron,
                ),
                child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 28),
              ).animate().scale(begin: const Offset(0.7, 0.7), end: const Offset(1, 1), duration: 500.ms, curve: Curves.elasticOut),

              const SizedBox(height: 24),

              Text('Set up your shop', style: AppTextStyles.h1)
                  .animate(delay: 150.ms).fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 8),
              Text('Tell us about your store. You can change this anytime in Settings.',
                      style: AppTextStyles.body)
                  .animate(delay: 250.ms).fadeIn(duration: 500.ms),

              const SizedBox(height: 36),

              Text('SHOP NAME', style: AppTextStyles.labelCaps),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                style: AppTextStyles.bodyMd,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your shop name' : null,
                decoration: const InputDecoration(hintText: 'e.g. Sharma General Store'),
              ).animate(delay: 350.ms).fadeIn(duration: 400.ms),

              const SizedBox(height: 20),

              Text('OWNER NAME (optional)', style: AppTextStyles.labelCaps),
              const SizedBox(height: 10),
              TextFormField(
                controller: _ownerCtrl,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                style: AppTextStyles.bodyMd,
                decoration: const InputDecoration(hintText: 'e.g. Ramesh Sharma'),
              ).animate(delay: 420.ms).fadeIn(duration: 400.ms),

              const SizedBox(height: 20),

              Text('LOCATION (optional)', style: AppTextStyles.labelCaps),
              const SizedBox(height: 10),
              TextFormField(
                controller: _locationCtrl,
                textCapitalization: TextCapitalization.words,
                style: AppTextStyles.bodyMd,
                inputFormatters: [LengthLimitingTextInputFormatter(60)],
                decoration: const InputDecoration(hintText: 'e.g. Patna, Bihar'),
              ).animate(delay: 490.ms).fadeIn(duration: 400.ms),

              const SizedBox(height: 36),

              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: _saving ? null : () => _finish(withDemo: false),
                  child: _saving
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : const Text('Start fresh'),
                ),
              ).animate(delay: 560.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity, height: 52,
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : () => _finish(withDemo: true),
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: const Text('Try with sample data'),
                ),
              ).animate(delay: 620.ms).fadeIn(duration: 400.ms),

              const SizedBox(height: 16),

              Center(
                child: Text('Sample data adds demo customers so you can explore.\nClear it anytime from Settings.',
                    textAlign: TextAlign.center, style: AppTextStyles.caption),
              ).animate(delay: 700.ms).fadeIn(),

              const SizedBox(height: 32),
            ]),
          ),
        ),
      ),
    );
  }
}
