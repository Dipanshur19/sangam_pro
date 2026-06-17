import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme.dart';
import '../../../domain/entities/transaction.dart';
import '../../../domain/entities/sms_entry.dart';
import '../../../services/sms_service.dart';
import '../../providers/providers.dart';
import '../auth/login_screen.dart' show ContextSnack;

class SmsQueueScreen extends ConsumerStatefulWidget {
  const SmsQueueScreen({super.key});
  @override
  ConsumerState<SmsQueueScreen> createState() => _S();
}

class _S extends ConsumerState<SmsQueueScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(smsQueueProvider).isEmpty) {
        for (final s in SmsService.getDemoSmsList()) ref.read(smsQueueProvider.notifier).add(s);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(smsQueueProvider).where((e) => e.status == 'pending').toList();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('UPI SMS Queue'), leading: BackButton(onPressed: () => context.go('/dashboard')),
        actions: [if (pending.isNotEmpty) TextButton(onPressed: () => ref.read(smsQueueProvider.notifier).clear(), child: Text('Clear', style: AppTextStyles.bodySm.copyWith(color: AppColors.text3)))]),
      body: pending.isEmpty
        ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.mark_email_read_outlined, size: 48, color: AppColors.border),
            const SizedBox(height: 12), Text('No pending SMS', style: AppTextStyles.h4),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text('Detected UPI payments will appear here for you to assign to a customer.',
                  textAlign: TextAlign.center, style: AppTextStyles.caption),
            ),
          ]))
        : Column(children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.info),
                const SizedBox(width: 8),
                Expanded(child: Text('Preview with sample payments. Assign them to a customer to record.',
                    style: AppTextStyles.caption.copyWith(color: AppColors.info))),
              ]),
            ),
            Expanded(
              child: ListView.separated(padding: const EdgeInsets.all(20), itemCount: pending.length, separatorBuilder: (_,__) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _SmsTile(entry: pending[i])),
            ),
          ]),
    );
  }
}

class _SmsTile extends ConsumerStatefulWidget {
  final SmsEntry entry; const _SmsTile({required this.entry});
  @override
  ConsumerState<_SmsTile> createState() => _STS();
}

class _STS extends ConsumerState<_SmsTile> {
  String? _custId; bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersStreamProvider);
    final e = widget.entry;
    return Container(padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.borderLight, width: 0.5), boxShadow: AppShadows.sm),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (e.parsedAmount != null) Text('₹${e.parsedAmount!.toStringAsFixed(0)}', style: AppTextStyles.h4.copyWith(color: AppColors.success)),
          const Spacer(), Text(e.parsedSource?.label ?? '', style: AppTextStyles.caption),
        ]),
        const SizedBox(height: 8),
        Text(e.rawSms, style: AppTextStyles.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 10),
        customersAsync.when(loading: ()=>const LinearProgressIndicator(), error: (_,__)=>const SizedBox(), data: (custs) => DropdownButtonFormField<String>(
          value: _custId, decoration: const InputDecoration(hintText: 'Assign to customer'),
          items: [const DropdownMenuItem(value: '__walkin__', child: Text('Walk-in')), ...custs.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))],
          onChanged: (v) => setState(() => _custId = v),
        )),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => ref.read(smsQueueProvider.notifier).dismiss(e.id), child: const Text('Dismiss'))),
          const SizedBox(width: 10),
          Expanded(child: ElevatedButton(onPressed: _custId == null || _saving ? null : _save,
            child: _saving ? const SizedBox(width:16,height:16,child: CircularProgressIndicator(strokeWidth:2,color: Colors.white)) : const Text('Save'))),
        ]),
      ]),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final e = widget.entry; final isWalkin = _custId == '__walkin__';
    final custs = ref.read(customersStreamProvider).value ?? [];
    final cust = isWalkin ? null : custs.where((c) => c.id == _custId).firstOrNull;
    await ref.read(addTransactionProvider)(Transaction(
      id: const Uuid().v4(), customerId: isWalkin ? null : cust?.id, customerName: isWalkin ? 'Walk-in' : (cust?.name ?? 'Unknown'),
      amount: e.parsedAmount ?? 0, type: e.parsedSource ?? TransactionType.upiPaytm, direction: TransactionDirection.incoming,
      note: 'From SMS', date: e.receivedAt, source: 'sms',
    ));
    ref.read(smsQueueProvider.notifier).dismiss(e.id);
    setState(() => _saving = false);
    if (mounted) context.showSnack('Saved!');
  }
}
