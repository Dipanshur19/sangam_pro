import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../domain/entities/store_profile.dart';
import '../../providers/providers.dart';
import '../auth/login_screen.dart' show ContextSnack;

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _S();
}

class _S extends ConsumerState<SettingsScreen> {
  final _keyCtrl = TextEditingController();
  bool _visible = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    ref.read(apiKeyProvider.future).then((k) {
      if (k != null && k.isNotEmpty && mounted) _keyCtrl.text = '••••••${k.substring(k.length<6?0:k.length-6)}';
    });
  }

  @override
  void dispose() { _keyCtrl.dispose(); super.dispose(); }

  void _editStore(BuildContext context, StoreProfile current) {
    final nameCtrl = TextEditingController(text: current.name);
    final ownerCtrl = TextEditingController(text: current.ownerName);
    final locationCtrl = TextEditingController(text: current.location);
    int dueDays = current.creditDueDays;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Edit store details', style: AppTextStyles.h3),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Shop name *')),
            const SizedBox(height: 12),
            TextField(controller: ownerCtrl, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Owner name')),
            const SizedBox(height: 12),
            TextField(controller: locationCtrl, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Location')),
            const SizedBox(height: 16),
            Text('CREDIT DUE AFTER', style: AppTextStyles.labelCaps),
            const SizedBox(height: 8),
            Row(children: [7, 15, 30].map((d) => Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: GestureDetector(
                onTap: () => setSheet(() => dueDays = d),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: dueDays == d ? AppColors.saffron : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: dueDays == d ? AppColors.saffron : AppColors.border),
                  ),
                  child: Text('$d days', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: dueDays == d ? Colors.white : AppColors.text2)),
                ),
              ),
            ))).toList()),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) { context.showSnack('Enter a shop name', isError: true); return; }
                await ref.read(storeProfileProvider.notifier).save(current.copyWith(
                  name: nameCtrl.text.trim(),
                  ownerName: ownerCtrl.text.trim(),
                  location: locationCtrl.text.trim(),
                  creditDueDays: dueDays,
                ));
                ref.invalidate(overdueCustomersProvider);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) context.showSnack('Store details updated');
              }, child: const Text('Save'))),
            ]),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(storeProfileProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Settings'), leading: BackButton(onPressed: () => context.go('/dashboard'))),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Section(title: 'Store', children: [_Tile(
          icon: Icons.store_outlined,
          label: store.name.isEmpty ? 'My Store' : store.name,
          sub: [
            if (store.ownerName.isNotEmpty) store.ownerName,
            if (store.location.isNotEmpty) store.location,
          ].join(' · ').isEmpty ? 'Tap to edit details' : [
            if (store.ownerName.isNotEmpty) store.ownerName,
            if (store.location.isNotEmpty) store.location,
          ].join(' · '),
          onTap: () => _editStore(context, store),
        )]),
        const SizedBox(height: 16),
        _Section(title: 'AI Photo Parsing', children: [Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Anthropic API Key', style: AppTextStyles.bodyMd), const SizedBox(height: 4),
          Text('Required for Khata Photo import.', style: AppTextStyles.caption), const SizedBox(height: 10),
          TextField(controller: _keyCtrl, obscureText: !_visible, decoration: InputDecoration(hintText: 'sk-ant-api03-…',
            suffixIcon: IconButton(icon: Icon(_visible ? Icons.visibility_off : Icons.visibility, size: 18), onPressed: () => setState(() => _visible = !_visible)))),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () { _keyCtrl.clear(); ref.read(setApiKeyProvider)(''); context.showSnack('Cleared'); }, child: const Text('Clear'))),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton(onPressed: _saving ? null : () async {
              final v = _keyCtrl.text.trim();
              if (v.isEmpty || v.startsWith('••')) { context.showSnack('Enter valid key', isError: true); return; }
              setState(() => _saving = true);
              await ref.read(setApiKeyProvider)(v);
              setState(() => _saving = false);
              if (mounted) context.showSnack('Saved!');
            }, child: _saving ? const SizedBox(width:16,height:16,child: CircularProgressIndicator(strokeWidth:2,color: Colors.white)) : const Text('Save'))),
          ]),
        ]))]),
        const SizedBox(height: 16),
        _Section(title: 'Roles', children: [
          _Tile(icon: Icons.verified_user_outlined, label: 'Owner', sub: 'Full access — add, edit & view everything'),
          const Divider(height: 0, indent: 56),
          _Tile(icon: Icons.visibility_outlined, label: 'Staff', sub: 'Read-only balance lookup'),
        ]),
        const SizedBox(height: 16),
        _Section(title: 'Data', children: [
          _Tile(icon: Icons.refresh_rounded, label: 'Load demo data', sub: 'Replace with sample customers', onTap: () async {
          final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
            title: const Text('Load demo data?'), content: const Text('This replaces your current entries with sample data.'),
            actions: [TextButton(onPressed: ()=>Navigator.pop(ctx,false), child: const Text('Cancel')), TextButton(onPressed: ()=>Navigator.pop(ctx,true), child: const Text('Load', style: TextStyle(color: AppColors.saffron)))]));
          if (confirm == true) {
            await ref.read(localSourceProvider).resetToDemo();
            ref.invalidate(transactionsStreamProvider); ref.invalidate(customersStreamProvider);
            ref.invalidate(todayTotalsProvider); ref.invalidate(overdueCustomersProvider);
            if (context.mounted) context.showSnack('Demo data loaded!');
          }
          }),
          const Divider(height: 0, indent: 56),
          _Tile(icon: Icons.delete_outline_rounded, label: 'Clear all data', sub: 'Erase all customers & transactions', onTap: () async {
            final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
              title: const Text('Clear all data?'), content: const Text('This permanently erases every customer and transaction. Your store profile is kept. This cannot be undone.'),
              actions: [TextButton(onPressed: ()=>Navigator.pop(ctx,false), child: const Text('Cancel')), TextButton(onPressed: ()=>Navigator.pop(ctx,true), child: const Text('Clear all', style: TextStyle(color: AppColors.error)))]));
            if (confirm == true) {
              await ref.read(localSourceProvider).clearAllData();
              ref.invalidate(transactionsStreamProvider); ref.invalidate(customersStreamProvider);
              ref.invalidate(todayTotalsProvider); ref.invalidate(overdueCustomersProvider);
              if (context.mounted) context.showSnack('All data cleared');
            }
          }),
        ]),
        const SizedBox(height: 16),
        _Section(title: 'About', children: [
          _Tile(icon: Icons.info_outline_rounded, label: 'Sangam', sub: 'Version 2.0.0'),
          const Divider(height: 0, indent: 56),
          _Tile(icon: Icons.favorite_outline_rounded, label: 'Sab ka ek hisaab', sub: 'One ledger for UPI, cash & udhar'),
        ]),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, child: OutlinedButton(
          onPressed: () => context.go('/login'),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error), foregroundColor: AppColors.error),
          child: const Text('Logout'))),
        const SizedBox(height: 40),
      ])),
    );
  }
}

class _Section extends StatelessWidget {
  final String title; final List<Widget> children;
  const _Section({required this.title, required this.children});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: Text(title.toUpperCase(), style: AppTextStyles.labelCaps)),
    Container(decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: AppColors.borderLight, width: 0.5)), child: Column(children: children)),
  ]);
}

class _Tile extends StatelessWidget {
  final IconData icon; final String label; final String? sub; final VoidCallback? onTap;
  const _Tile({required this.icon, required this.label, this.sub, this.onTap});
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, size: 20, color: AppColors.text3),
    title: Text(label, style: AppTextStyles.bodyMd),
    subtitle: sub != null ? Text(sub!, style: AppTextStyles.caption) : null,
    trailing: onTap != null ? const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.text4) : null,
    onTap: onTap, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
  );
}
