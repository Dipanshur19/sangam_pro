import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme.dart';
import '../../../domain/entities/transaction.dart';
import '../../providers/providers.dart';
import '../auth/login_screen.dart' show ContextSnack;

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final String customerId;
  const CustomerDetailScreen({super.key, required this.customerId});
  @override
  ConsumerState<CustomerDetailScreen> createState() => _S();
}

class _S extends ConsumerState<CustomerDetailScreen> {
  bool _showPay = false;
  TransactionType _payType = TransactionType.upiPaytm;
  final _payCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() { _payCtrl.dispose(); super.dispose(); }

  Future<void> _savePayment() async {
    final amt = double.tryParse(_payCtrl.text.trim());
    if (amt == null || amt <= 0) { context.showSnack('Enter amount', isError: true); return; }
    setState(() => _saving = true);
    final custs = ref.read(customersStreamProvider).value ?? [];
    final cust = custs.firstWhere((c) => c.id == widget.customerId);
    await ref.read(addTransactionProvider)(Transaction(
      id: const Uuid().v4(), customerId: widget.customerId, customerName: cust.name,
      amount: amt, type: _payType, direction: TransactionDirection.incoming,
      note: 'Payment received', date: DateTime.now(), source: 'manual',
    ));
    _payCtrl.clear();
    setState(() { _saving = false; _showPay = false; });
    if (mounted) context.showSnack('Payment saved!');
  }

  Future<void> _whatsapp(String name, String phone, double balance) async {
    final storeName = ref.read(storeProfileProvider).name;
    final shop = storeName.isEmpty ? 'our store' : storeName;
    final msg = Uri.encodeComponent('Namaste $name ji,\n\nAapka $shop mein \u20b9${balance.toStringAsFixed(0)} baaki hai.\n\nKripya jaldi payment karein.\n\n- $shop');
    final url = Uri.parse('https://wa.me/91$phone?text=$msg');
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final custsAsync = ref.watch(customersStreamProvider);
    final balAsync = ref.watch(customerBalanceProvider(widget.customerId));
    final txnsAsync = ref.watch(customerTransactionsProvider(widget.customerId));
    final customer = custsAsync.value?.where((c) => c.id == widget.customerId).firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(customer?.name ?? '…'), leading: BackButton(onPressed: () => context.pop())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Container(
            width: double.infinity, padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(gradient: AppGradients.saffron, borderRadius: BorderRadius.circular(AppRadius.xxl), boxShadow: AppShadows.saffron),
            child: balAsync.when(
              loading: () => const CircularProgressIndicator(color: Colors.white),
              error: (e, _) => Text('$e', style: const TextStyle(color: Colors.white)),
              data: (balance) => Column(children: [
                Text('OUTSTANDING BALANCE', style: AppTextStyles.labelCaps.copyWith(color: Colors.white70)),
                const SizedBox(height: 6),
                Text(balance > 0 ? '₹${balance.toStringAsFixed(0)}' : '✓ Settled',
                  style: AppTextStyles.h1.copyWith(color: Colors.white)),
                if (balance > 0) ...[
                  const SizedBox(height: 18),
                  Row(children: [
                    Expanded(child: ElevatedButton.icon(
                      onPressed: () => setState(() => _showPay = !_showPay),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.saffron),
                      icon: const Icon(Icons.payments_outlined, size: 16), label: const Text('Record Payment'))),
                    if (customer?.phone != null) ...[
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: () => _whatsapp(customer!.name, customer.phone!, balance),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white), foregroundColor: Colors.white),
                        icon: const Icon(Icons.send, size: 14), label: const Text('Remind')),
                    ],
                  ]),
                ],
              ]),
            ),
          ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.15, end: 0),
          const SizedBox(height: 14),

          if (_showPay) Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.border)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('RECORD PAYMENT', style: AppTextStyles.labelCaps),
              const SizedBox(height: 10),
              TextField(controller: _payCtrl, keyboardType: TextInputType.number, style: AppTextStyles.h3, decoration: const InputDecoration(prefixText: '₹  ')),
              const SizedBox(height: 12),
              Row(children: [TransactionType.upiPaytm, TransactionType.upiGpay, TransactionType.upiPhonePe, TransactionType.cash].map((t) {
                final colors = {TransactionType.upiPaytm: AppColors.paytm, TransactionType.upiGpay: AppColors.gpay, TransactionType.upiPhonePe: AppColors.phonePe, TransactionType.cash: AppColors.cash};
                return Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: GestureDetector(
                  onTap: () => setState(() => _payType = t),
                  child: Container(padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(color: _payType == t ? colors[t] : AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: _payType == t ? colors[t]! : AppColors.border)),
                    child: Text(t.label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _payType == t ? Colors.white : AppColors.text2))),
                )));
              }).toList()),
              const SizedBox(height: 14),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _saving ? null : _savePayment,
                child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save Payment'))),
            ]),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0),
          if (_showPay) const SizedBox(height: 14),

          Align(alignment: Alignment.centerLeft, child: Text('TRANSACTION HISTORY', style: AppTextStyles.labelCaps)),
          const SizedBox(height: 10),
          txnsAsync.when(
            loading: () => const CircularProgressIndicator(color: AppColors.saffron),
            error: (e, _) => Text('$e'),
            data: (txns) {
              if (txns.isEmpty) return const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Text('No transactions yet', style: AppTextStyles.caption));
              return Container(
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: AppColors.borderLight, width: 0.5)),
                child: Column(children: txns.asMap().entries.map((e) => Column(children: [
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (e.value.note != null) Text(e.value.note!, style: AppTextStyles.bodySm, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('${e.value.date.day}/${e.value.date.month}/${e.value.date.year}', style: AppTextStyles.caption),
                    ])),
                    Text('${e.value.direction == TransactionDirection.incoming ? '-' : '+'}₹${e.value.amount.toStringAsFixed(0)}',
                      style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w700, color: e.value.direction == TransactionDirection.incoming ? AppColors.success : AppColors.udhar)),
                  ])),
                  if (e.key < txns.length - 1) const Divider(height: 0),
                ])).toList()),
              );
            },
          ),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }
}
