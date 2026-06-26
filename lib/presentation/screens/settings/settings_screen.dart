import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme.dart';
import '../../../core/l10n.dart';
import '../../../domain/entities/store_profile.dart';
import '../../../domain/entities/app_user.dart';
import '../../../services/auth_service.dart';
import '../../providers/providers.dart';
import '../auth/login_screen.dart' show ContextSnack;

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(storeProfileProvider);
    final me = ref.watch(currentUserProvider);
    final isAdmin = me?.isAdmin ?? false;
    final smsOn = ref.watch(smsAutoReadProvider);
    final hi = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(tr('Settings', 'सेटिंग्स', hi)), leading: BackButton(onPressed: () => context.go('/dashboard'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Signed in as ──
          if (me != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppGradients.saffron,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: AppShadows.saffron,
              ),
              child: Row(children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(me.name.isEmpty ? '?' : me.name[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(me.name, style: AppTextStyles.h4.copyWith(color: Colors.white)),
                    Text('@${me.username} · ${me.isAdmin ? 'Admin' : (me.canEdit ? 'Staff (can edit)' : 'Staff (view only)')}',
                        style: AppTextStyles.caption.copyWith(color: Colors.white.withOpacity(0.85))),
                  ]),
                ),
              ]),
            ),
          const SizedBox(height: 16),

          // ── Store ──
          _Section(title: tr('Store', 'दुकान', hi), children: [
            _Tile(
              icon: Icons.store_outlined,
              label: store.name.isEmpty ? 'My Store' : store.name,
              sub: _storeSub(store),
              onTap: isAdmin ? () => _editStore(context, ref, store) : null,
            ),
          ]),
          const SizedBox(height: 16),

          // ── Language ──
          _Section(title: tr('Preferences', 'प्राथमिकताएँ', hi), children: [
            ListTile(
              leading: const Icon(Icons.translate_rounded, size: 20, color: AppColors.text3),
              title: Text(tr('Language', 'भाषा', hi), style: AppTextStyles.bodyMd),
              subtitle: Text(tr('Choose app language', 'ऐप की भाषा चुनें', hi), style: AppTextStyles.caption),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.saffronLight, borderRadius: BorderRadius.circular(AppRadius.full)),
                child: Text(hi ? 'हिंदी' : 'English',
                    style: AppTextStyles.btnSm.copyWith(color: AppColors.saffron)),
              ),
              onTap: () => ref.read(languageProvider.notifier).toggle(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            ),
          ]),
          const SizedBox(height: 16),

          // ── Automatic SMS reading ──
          _Section(title: tr('Payments', 'भुगतान', hi), children: [
            SwitchListTile(
              value: smsOn,
              activeColor: AppColors.saffron,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              secondary: const Icon(Icons.sms_outlined, color: AppColors.text3, size: 20),
              title: Text(tr('Auto-read UPI SMS', 'UPI SMS अपने आप पढ़ें', hi), style: AppTextStyles.bodyMd),
              subtitle: Text(
                smsOn ? tr('Reading payment SMS automatically', 'भुगतान SMS अपने आप पढ़े जा रहे हैं', hi) : tr('Detect Paytm / GPay / PhonePe payments from SMS', 'SMS से Paytm / GPay / PhonePe भुगतान पहचानें', hi),
                style: AppTextStyles.caption,
              ),
              onChanged: !isAdmin ? null : (v) async {
                if (v) {
                  final ok = await ref.read(smsAutoReadProvider.notifier).enable();
                  if (context.mounted) {
                    context.showSnack(ok ? 'Auto-read enabled' : 'SMS permission denied', isError: !ok);
                  }
                } else {
                  await ref.read(smsAutoReadProvider.notifier).disable();
                  if (context.mounted) context.showSnack('Auto-read turned off');
                }
              },
            ),
            const Divider(height: 0, indent: 56),
            _Tile(
              icon: Icons.inbox_outlined,
              label: tr('Review detected payments', 'पहचाने गए भुगतान देखें', hi),
              sub: tr('Assign incoming UPI SMS to customers', 'आने वाले UPI SMS ग्राहकों को सौंपें', hi),
              onTap: () => context.push('/sms-queue'),
            ),
          ]),
          const SizedBox(height: 16),

          const SizedBox(height: 16),

          // ── Cloud sync ──
          _CloudSyncSection(),
          const SizedBox(height: 16),

          // ── Business tools ──
          _Section(title: tr('Business', 'व्यापार', hi), children: [
            _Tile(icon: Icons.person_outline_rounded, label: tr('Profile', 'प्रोफ़ाइल', hi), sub: tr('Business info, GST, UPI ID, address', 'व्यापार जानकारी, GST, UPI ID, पता', hi), onTap: () => context.push('/profile')),
            const Divider(height: 0, indent: 56),
            _Tile(icon: Icons.inventory_2_outlined, label: tr('Stock management', 'स्टॉक प्रबंधन', hi), sub: tr('Track the items you sell', 'आप जो सामान बेचते हैं उसे ट्रैक करें', hi), onTap: () => context.push('/stock')),
            const Divider(height: 0, indent: 56),
            _Tile(icon: Icons.devices_rounded, label: tr('Multi device', 'कई डिवाइस', hi), sub: tr('Use on family & staff phones', 'परिवार और स्टाफ़ के फ़ोन पर इस्तेमाल करें', hi), onTap: () => context.push('/multi-device')),
          ]),
          const SizedBox(height: 16),

          // ── Team (admin only) ──
          if (isAdmin) ...[
            _TeamSection(),
            const SizedBox(height: 16),
          ],

          // ── Data (admin only) ──
          if (isAdmin) ...[
            _Section(title: tr('Data', 'डेटा', hi), children: [
              _Tile(icon: Icons.refresh_rounded, label: tr('Load demo data', 'डेमो डेटा लोड करें', hi), sub: tr('Replace with sample customers', 'सैंपल ग्राहकों से बदलें', hi), onTap: () async {
                final ok = await _confirm(context, 'Load demo data?', 'This replaces your current entries with sample data.', 'Load', AppColors.saffron);
                if (ok) {
                  await ref.read(localSourceProvider).resetToDemo();
                  _refreshData(ref);
                  if (context.mounted) context.showSnack('Demo data loaded!');
                }
              }),
              const Divider(height: 0, indent: 56),
              _Tile(icon: Icons.delete_outline_rounded, label: tr('Clear all data', 'सारा डेटा मिटाएँ', hi), sub: tr('Erase all customers & transactions', 'सभी ग्राहक और लेन-देन मिटाएँ', hi), onTap: () async {
                final ok = await _confirm(context, 'Clear all data?', 'This permanently erases every customer and transaction. Your shop profile and team are kept.', 'Clear all', AppColors.error);
                if (ok) {
                  await ref.read(localSourceProvider).clearAllData();
                  _refreshData(ref);
                  if (context.mounted) context.showSnack('All data cleared');
                }
              }),
            ]),
            const SizedBox(height: 16),
          ],

          // ── About ──
          _Section(title: tr('About', 'ऐप के बारे में', hi), children: [
            _Tile(icon: Icons.info_outline_rounded, label: 'Sangam', sub: 'Version 2.0.0'),
            const Divider(height: 0, indent: 56),
            _Tile(icon: Icons.favorite_outline_rounded, label: 'Sab ka ek hisaab', sub: tr('One ledger for UPI, cash & udhar', 'UPI, नकद और उधार — एक ही हिसाब', hi)),
          ]),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await ref.read(currentUserProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error), foregroundColor: AppColors.error),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: Text(tr('Log out', 'लॉग आउट', hi)),
            ),
          ),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  String _storeSub(StoreProfile s) {
    final parts = [if (s.ownerName.isNotEmpty) s.ownerName, if (s.location.isNotEmpty) s.location];
    return parts.isEmpty ? 'Tap to edit details' : parts.join(' · ');
  }

  void _refreshData(WidgetRef ref) {
    ref.invalidate(transactionsStreamProvider);
    ref.invalidate(customersStreamProvider);
    ref.invalidate(todayTotalsProvider);
    ref.invalidate(overdueCustomersProvider);
  }

  Future<bool> _confirm(BuildContext context, String title, String body, String action, Color color) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(action, style: TextStyle(color: color))),
        ],
      ),
    );
    return r ?? false;
  }

  void _editStore(BuildContext context, WidgetRef ref, StoreProfile current) {
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
                if (context.mounted) context.showSnack('Store details updated');
              }, child: const Text('Save'))),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ── Team management ─────────────────────────────────────
class _TeamSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);
    return _Section(title: 'Team', children: [
      ...usersAsync.when(
        loading: () => [const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator())],
        error: (_, __) => [const Padding(padding: EdgeInsets.all(16), child: Text('Could not load team'))],
        data: (users) {
          final staff = users.where((u) => !u.isAdmin).toList();
          return [
            for (final u in staff) ...[
              ListTile(
                leading: const Icon(Icons.person_outline_rounded, size: 20, color: AppColors.text3),
                title: Text(u.name, style: AppTextStyles.bodyMd),
                subtitle: Text('@${u.username} · ${u.canEdit ? 'Can edit' : 'View only'}', style: AppTextStyles.caption),
                trailing: IconButton(
                  icon: const Icon(Icons.more_horiz_rounded, size: 20, color: AppColors.text3),
                  onPressed: () => _staffOptions(context, ref, u),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              const Divider(height: 0, indent: 56),
            ],
            ListTile(
              leading: const Icon(Icons.person_add_alt_1_rounded, size: 20, color: AppColors.saffron),
              title: Text('Add staff login', style: AppTextStyles.bodyMd.copyWith(color: AppColors.saffron)),
              subtitle: Text(staff.isEmpty ? 'Give a helper their own username & password' : '${staff.length} staff member(s)', style: AppTextStyles.caption),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              onTap: () => _addStaff(context, ref),
            ),
          ];
        },
      ),
    ]);
  }

  Future<void> _addStaff(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    bool canEdit = true;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Add staff login', style: AppTextStyles.h3),
            const SizedBox(height: 4),
            Text('They log in with the Staff tab using these details.', style: AppTextStyles.caption),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            TextField(
              controller: userCtrl,
              autocorrect: false,
              inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 12),
            TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Password')),
            const SizedBox(height: 8),
            SwitchListTile(
              value: canEdit,
              activeColor: AppColors.saffron,
              contentPadding: EdgeInsets.zero,
              title: Text('Allow adding & editing', style: AppTextStyles.bodyMd),
              subtitle: Text(canEdit ? 'Can record transactions' : 'View only — cannot change data', style: AppTextStyles.caption),
              onChanged: (v) => setSheet(() => canEdit = v),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(onPressed: () async {
                final name = nameCtrl.text.trim();
                final username = userCtrl.text.trim();
                final pass = passCtrl.text;
                if (name.isEmpty || username.length < 3 || pass.length < 4) {
                  context.showSnack('Name, username (3+), password (4+) required', isError: true);
                  return;
                }
                try {
                  await ref.read(authServiceProvider).addStaff(name: name, username: username, password: pass, canEdit: canEdit);
                  ref.invalidate(usersProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) context.showSnack('Staff added');
                } on DuplicateUsernameException {
                  if (context.mounted) context.showSnack('Username already taken', isError: true);
                }
              }, child: const Text('Add'))),
            ]),
          ]),
        ),
      ),
    );
  }

  Future<void> _staffOptions(BuildContext context, WidgetRef ref, AppUser u) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          ListTile(
            leading: Icon(u.canEdit ? Icons.visibility_outlined : Icons.edit_outlined, color: AppColors.text2),
            title: Text(u.canEdit ? 'Make view-only' : 'Allow editing'),
            onTap: () async {
              await ref.read(authServiceProvider).updateStaff(u.id, canEdit: !u.canEdit);
              ref.invalidate(usersProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
          ),
          ListTile(
            leading: const Icon(Icons.key_outlined, color: AppColors.text2),
            title: const Text('Reset password'),
            onTap: () async {
              Navigator.pop(ctx);
              await _resetPassword(context, ref, u);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            title: const Text('Remove staff', style: TextStyle(color: AppColors.error)),
            onTap: () async {
              await ref.read(authServiceProvider).removeUser(u.id);
              ref.invalidate(usersProvider);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) context.showSnack('Staff removed');
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Future<void> _resetPassword(BuildContext context, WidgetRef ref, AppUser u) async {
    final passCtrl = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Reset password for ${u.name}', style: AppTextStyles.h4),
          const SizedBox(height: 16),
          TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'New password')),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: () async {
              if (passCtrl.text.length < 4) { context.showSnack('Use at least 4 characters', isError: true); return; }
              await ref.read(authServiceProvider).setPassword(u.id, passCtrl.text);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) context.showSnack('Password updated');
            }, child: const Text('Update password')),
          ),
        ]),
      ),
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


// ── Cloud sync section ──────────────────────────────────
class _CloudSyncSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cloud = ref.watch(cloudSyncProvider);

    if (!cloud.available) {
      return _Section(title: 'Cloud sync', children: const [
        _Tile(
          icon: Icons.cloud_off_rounded,
          label: 'Not enabled in this build',
          sub: 'Build with Firebase keys (--dart-define) to sync across devices. See README.',
        ),
      ]);
    }

    if (!cloud.connected) {
      return _Section(title: 'Cloud sync', children: [
        _Tile(
          icon: Icons.cloud_queue_rounded,
          label: 'Connect to cloud',
          sub: 'Enter a shop code to share data across phones',
          onTap: () => _connectDialog(context, ref),
        ),
      ]);
    }

    final last = cloud.syncing
        ? 'Syncing…'
        : (cloud.lastSync != null ? 'Last synced ${_ago(cloud.lastSync!)}' : 'Connected');
    return _Section(title: 'Cloud sync', children: [
      _Tile(icon: Icons.cloud_done_rounded, label: 'Connected · ${cloud.shopCode}', sub: last),
      const Divider(height: 0, indent: 56),
      _Tile(
        icon: Icons.ios_share_rounded,
        label: 'Share shop code',
        sub: 'Send the code to staff to join',
        onTap: () => Share.share(
          'Join my shop on Sangam 🪔\n\n'
          'Open the app → Settings → Cloud sync → Connect, and enter this shop code:\n\n'
          '${cloud.shopCode}\n\n'
          'We\'ll then share the same live ledger.',
          subject: 'Sangam shop code: ${cloud.shopCode}',
        ),
      ),
      const Divider(height: 0, indent: 56),
      _Tile(
        icon: Icons.sync_rounded,
        label: 'Sync now',
        sub: 'Push & pull the latest data',
        onTap: () async {
          await ref.read(cloudSyncProvider.notifier).syncNow();
          if (context.mounted) context.showSnack('Synced');
        },
      ),
      const Divider(height: 0, indent: 56),
      _Tile(
        icon: Icons.link_off_rounded,
        label: 'Disconnect',
        sub: 'Stop syncing this device',
        onTap: () async {
          await ref.read(cloudSyncProvider.notifier).disconnect();
          if (context.mounted) context.showSnack('Disconnected from cloud');
        },
      ),
    ]);
  }

  static String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  void _connectDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Connect to cloud', style: AppTextStyles.h3),
          const SizedBox(height: 6),
          Text(
            'Pick any shop code (e.g. SMRITI2024) on the owner\'s phone, then enter the SAME code on staff phones to share one live ledger.',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: ctrl,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'Shop code', hintText: 'e.g. SMRITI2024'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final ok = await ref.read(cloudSyncProvider.notifier).connect(ctrl.text);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  context.showSnack(ok ? 'Connected — syncing…' : 'Enter a valid shop code', isError: !ok);
                }
              },
              child: const Text('Connect'),
            ),
          ),
        ]),
      ),
    );
  }
}
