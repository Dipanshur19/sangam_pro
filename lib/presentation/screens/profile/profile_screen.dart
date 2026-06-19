import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../domain/entities/store_profile.dart';
import '../../providers/providers.dart';
import '../auth/login_screen.dart' show ContextSnack;

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(storeProfileProvider);
    final isAdmin = ref.watch(currentUserProvider)?.isAdmin ?? true;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        leading: BackButton(onPressed: () => context.go('/dashboard')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Center(
            child: Stack(children: [
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(gradient: AppGradients.saffron, shape: BoxShape.circle, boxShadow: AppShadows.saffron),
                child: Center(
                  child: Text(
                    store.name.isEmpty ? 'S' : store.name[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 34),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 10),
          Center(child: Text(store.name.isEmpty ? 'My Store' : store.name, style: AppTextStyles.h3)),
          if (store.ownerName.isNotEmpty)
            Center(child: Text(store.ownerName, style: AppTextStyles.caption)),
          const SizedBox(height: 24),

          Text('BUSINESS INFORMATION', style: AppTextStyles.labelCaps),
          const SizedBox(height: 8),
          _Card(children: [
            _Row(icon: Icons.store_outlined, label: 'Shop name', value: store.name, hint: 'Visible to your customers',
                enabled: isAdmin, onTap: () => _edit(context, ref, store, _Field.name)),
            _div(),
            _Row(icon: Icons.person_outline_rounded, label: 'Owner name', value: store.ownerName, hint: 'Owner',
                enabled: isAdmin, onTap: () => _edit(context, ref, store, _Field.owner)),
            _div(),
            _Row(icon: Icons.phone_android_rounded, label: 'Mobile number', value: store.phone ?? '', hint: 'Mobile number',
                enabled: isAdmin, onTap: () => _edit(context, ref, store, _Field.phone)),
            _div(),
            _Row(icon: Icons.qr_code_2_rounded, label: 'UPI ID', value: store.upiId, hint: 'For collection QR (name@bank)',
                enabled: isAdmin, onTap: () => _edit(context, ref, store, _Field.upi)),
            _div(),
            _Row(icon: Icons.receipt_long_outlined, label: 'GST number', value: store.gst, hint: 'GST number',
                enabled: isAdmin, onTap: () => _edit(context, ref, store, _Field.gst)),
            _div(),
            _Row(icon: Icons.apartment_outlined, label: 'Business type', value: store.businessType, hint: 'e.g. Retail / Wholesale',
                enabled: isAdmin, onTap: () => _edit(context, ref, store, _Field.bizType)),
            _div(),
            _Row(icon: Icons.category_outlined, label: 'Category', value: store.category, hint: 'e.g. Kirana / Grocery',
                enabled: isAdmin, onTap: () => _edit(context, ref, store, _Field.category)),
            _div(),
            _Row(icon: Icons.location_on_outlined, label: 'Address', value: store.address, hint: 'Shop address',
                enabled: isAdmin, onTap: () => _edit(context, ref, store, _Field.address)),
          ]),
          const SizedBox(height: 18),

          Text('OTHER INFORMATION', style: AppTextStyles.labelCaps),
          const SizedBox(height: 8),
          _Card(children: [
            _Row(icon: Icons.mail_outline_rounded, label: 'Email', value: store.email, hint: 'Email',
                enabled: isAdmin, onTap: () => _edit(context, ref, store, _Field.email)),
          ]),
        ],
      ),
    );
  }

  void _edit(BuildContext context, WidgetRef ref, StoreProfile s, _Field field) {
    final cfg = _fieldConfig(field, s);
    final ctrl = TextEditingController(text: cfg.value);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(cfg.label, style: AppTextStyles.h4),
          const SizedBox(height: 14),
          TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: cfg.keyboard,
            textCapitalization: cfg.caps,
            inputFormatters: cfg.formatters,
            decoration: InputDecoration(hintText: cfg.hint),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final v = ctrl.text.trim();
                if (field == _Field.name && v.isEmpty) {
                  context.showSnack('Shop name cannot be empty', isError: true);
                  return;
                }
                await ref.read(storeProfileProvider.notifier).save(cfg.apply(s, v));
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) context.showSnack('Saved');
              },
              child: const Text('Save'),
            ),
          ),
        ]),
      ),
    );
  }
}

enum _Field { name, owner, phone, upi, gst, bizType, category, address, email }

class _FieldCfg {
  final String label, value, hint;
  final TextInputType keyboard;
  final TextCapitalization caps;
  final List<TextInputFormatter>? formatters;
  final StoreProfile Function(StoreProfile, String) apply;
  _FieldCfg(this.label, this.value, this.hint, this.apply,
      {this.keyboard = TextInputType.text, this.caps = TextCapitalization.words, this.formatters});
}

_FieldCfg _fieldConfig(_Field f, StoreProfile s) {
  switch (f) {
    case _Field.name:
      return _FieldCfg('Shop name', s.name, 'e.g. Sharma General Store', (p, v) => p.copyWith(name: v));
    case _Field.owner:
      return _FieldCfg('Owner name', s.ownerName, 'e.g. Smriti Sharma', (p, v) => p.copyWith(ownerName: v));
    case _Field.phone:
      return _FieldCfg('Mobile number', s.phone ?? '', '10-digit number', (p, v) => p.copyWith(phone: v),
          keyboard: TextInputType.phone, caps: TextCapitalization.none,
          formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)]);
    case _Field.upi:
      return _FieldCfg('UPI ID', s.upiId, 'name@bank', (p, v) => p.copyWith(upiId: v), caps: TextCapitalization.none);
    case _Field.gst:
      return _FieldCfg('GST number', s.gst, '15-character GSTIN', (p, v) => p.copyWith(gst: v.toUpperCase()),
          caps: TextCapitalization.characters, formatters: [LengthLimitingTextInputFormatter(15)]);
    case _Field.bizType:
      return _FieldCfg('Business type', s.businessType, 'e.g. Retail / Wholesale', (p, v) => p.copyWith(businessType: v));
    case _Field.category:
      return _FieldCfg('Category', s.category, 'e.g. Kirana / Grocery', (p, v) => p.copyWith(category: v));
    case _Field.address:
      return _FieldCfg('Address', s.address, 'Shop address', (p, v) => p.copyWith(address: v));
    case _Field.email:
      return _FieldCfg('Email', s.email, 'you@example.com', (p, v) => p.copyWith(email: v),
          keyboard: TextInputType.emailAddress, caps: TextCapitalization.none);
  }
}

Widget _div() => const Divider(height: 0, indent: 56);

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.borderLight, width: 0.5),
        ),
        child: Column(children: children),
      );
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label, value, hint;
  final bool enabled;
  final VoidCallback onTap;
  const _Row({required this.icon, required this.label, required this.value, required this.hint, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final filled = value.trim().isNotEmpty;
    return ListTile(
      leading: Icon(icon, size: 20, color: AppColors.saffron),
      title: Text(filled ? value : 'Enter your ${label.toLowerCase()}',
          style: filled ? AppTextStyles.bodyMd : AppTextStyles.bodyMd.copyWith(color: AppColors.text3)),
      subtitle: Text(label, style: AppTextStyles.caption),
      trailing: enabled ? Icon(filled ? Icons.edit_outlined : Icons.chevron_right_rounded, size: 18, color: AppColors.text4) : null,
      onTap: enabled ? onTap : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}
