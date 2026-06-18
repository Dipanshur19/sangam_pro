import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme.dart';
import '../../../domain/entities/transaction.dart';
import '../../../domain/entities/sms_entry.dart';
import '../../providers/providers.dart';
import '../auth/login_screen.dart' show ContextSnack;

class SmsQueueScreen extends ConsumerStatefulWidget {
  const SmsQueueScreen({super.key});
  @override
  ConsumerState<SmsQueueScreen> createState() => _S();
}

class _S extends ConsumerState<SmsQueueScreen> {
  bool _scanning = false;

  Future<void> _scan() async {
    setState(() => _scanning = true);
    final found = await ref.read(smsAutoReadProvider.notifier).scanNow();
    if (mounted) {
      setState(() => _scanning = false);
      context.showSnack(found > 0 ? 'Found $found payment(s)' : 'No new UPI payments found');
    }
  }

  Future<void> _enable() async {
    setState(() => _scanning = true);
    final ok = await ref.read(smsAutoReadProvider.notifier).enable();
    if (mounted) {
      setState(() => _scanning = false);
      context.showSnack(ok ? 'Auto-read enabled' : 'SMS permission denied', isError: !ok);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(smsAutoReadProvider);
    final pending = ref.watch(smsQueueProvider).where((e) => e.status == 'pending').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('UPI Payments'),
        leading: BackButton(onPressed: () => context.go('/dashboard')),
        actions: [
          if (enabled)
            IconButton(
              icon: _scanning
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh_rounded),
              tooltip: 'Scan now',
              onPressed: _scanning ? null : _scan,
            ),
          if (pending.isNotEmpty)
            TextButton(
              onPressed: () => ref.read(smsQueueProvider.notifier).clear(),
              child: Text('Clear', style: AppTextStyles.bodySm.copyWith(color: AppColors.text3)),
            ),
        ],
      ),
      body: !enabled
          ? _EnablePrompt(scanning: _scanning, onEnable: _enable)
          : pending.isEmpty
              ? _EmptyState(scanning: _scanning, onScan: _scan)
              : Column(children: [
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(AppRadius.md)),
                    child: Row(children: [
                      const Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.info),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Detected from your SMS. Assign each to a customer to record it.',
                          style: AppTextStyles.caption.copyWith(color: AppColors.info))),
                    ]),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: pending.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _SmsTile(entry: pending[i]),
                    ),
                  ),
                ]),
    );
  }
}

class _EnablePrompt extends StatelessWidget {
  final bool scanning;
  final VoidCallback onEnable;
  const _EnablePrompt({required this.scanning, required this.onEnable});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: AppColors.saffronLight, borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.sms_outlined, size: 34, color: AppColors.saffron),
            ),
            const SizedBox(height: 20),
            Text('Auto-read UPI payments', style: AppTextStyles.h3, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Allow Sangam to read your SMS so Paytm, GPay and PhonePe payments are detected automatically. Your messages never leave your phone.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySm,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton.icon(
                onPressed: scanning ? null : onEnable,
                icon: scanning
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.lock_open_rounded, size: 18),
                label: const Text('Allow SMS access'),
              ),
            ),
          ]),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  final bool scanning;
  final VoidCallback onScan;
  const _EmptyState({required this.scanning, required this.onScan});
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.mark_email_read_outlined, size: 48, color: AppColors.border),
          const SizedBox(height: 12),
          Text('No new payments', style: AppTextStyles.h4),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text('New UPI payment SMS will appear here automatically.', textAlign: TextAlign.center, style: AppTextStyles.caption),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: scanning ? null : onScan,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Scan now'),
          ),
        ]),
      );
}

class _SmsTile extends ConsumerStatefulWidget {
  final SmsEntry entry;
  const _SmsTile({required this.entry});
  @override
  ConsumerState<_SmsTile> createState() => _STS();
}

class _STS extends ConsumerState<_SmsTile> {
  String? _custId;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersStreamProvider);
    final e = widget.entry;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.borderLight, width: 0.5), boxShadow: AppShadows.sm),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (e.parsedAmount != null) Text('₹${e.parsedAmount!.toStringAsFixed(0)}', style: AppTextStyles.h4.copyWith(color: AppColors.success)),
          const Spacer(),
          Text(e.parsedSource?.label ?? '', style: AppTextStyles.caption),
        ]),
        const SizedBox(height: 8),
        Text(e.rawSms, style: AppTextStyles.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 10),
        customersAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const SizedBox(),
          data: (custs) => DropdownButtonFormField<String>(
            value: _custId,
            decoration: const InputDecoration(hintText: 'Assign to customer'),
            items: [
              const DropdownMenuItem(value: '__walkin__', child: Text('Walk-in')),
              ...custs.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
            ],
            onChanged: (v) => setState(() => _custId = v),
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => ref.read(smsQueueProvider.notifier).dismiss(e.id), child: const Text('Dismiss'))),
          const SizedBox(width: 10),
          Expanded(child: ElevatedButton(
            onPressed: _custId == null || _saving ? null : _save,
            child: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save'),
          )),
        ]),
      ]),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final e = widget.entry;
    final isWalkin = _custId == '__walkin__';
    final custs = ref.read(customersStreamProvider).value ?? [];
    final cust = isWalkin ? null : custs.where((c) => c.id == _custId).firstOrNull;
    await ref.read(addTransactionProvider)(Transaction(
      id: const Uuid().v4(),
      customerId: isWalkin ? null : cust?.id,
      customerName: isWalkin ? 'Walk-in' : (cust?.name ?? 'Unknown'),
      amount: e.parsedAmount ?? 0,
      type: e.parsedSource ?? TransactionType.upiPaytm,
      direction: TransactionDirection.incoming,
      note: 'From SMS',
      date: e.receivedAt,
      source: 'sms',
    ));
    ref.read(smsQueueProvider.notifier).dismiss(e.id);
    if (mounted) {
      setState(() => _saving = false);
      context.showSnack('Saved!');
    }
  }
}
