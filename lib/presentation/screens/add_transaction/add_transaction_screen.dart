import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme.dart';
import '../../../domain/entities/transaction.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/usecases/sms_parser.dart';
import '../../providers/providers.dart';
import '../../widgets/bottom_nav.dart';
import '../auth/login_screen.dart' show ContextSnack;

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});
  @override
  ConsumerState<AddTransactionScreen> createState() => _S();
}

class _S extends ConsumerState<AddTransactionScreen> {
  TransactionType _type = TransactionType.upiPaytm;
  final _amountCtrl = TextEditingController();
  final _custCtrl   = TextEditingController();
  final _noteCtrl   = TextEditingController();
  final _smsCtrl    = TextEditingController();
  Customer? _selectedCust;
  bool _showSms = false;
  bool _saving = false;
  String? _smsResult;

  @override
  void dispose() { _amountCtrl.dispose(); _custCtrl.dispose(); _noteCtrl.dispose(); _smsCtrl.dispose(); super.dispose(); }

  void _parseSms() {
    final parsed = SmsParser.parse(_smsCtrl.text);
    setState(() {
      if (parsed.amount != null) {
        _amountCtrl.text = parsed.amount!.toStringAsFixed(0);
        if (parsed.source != null) _type = parsed.source!;
        _smsResult = '✓ Parsed ₹${parsed.amount!.toStringAsFixed(0)} via ${_type.label}';
      } else { _smsResult = 'Could not parse — fill manually.'; }
    });
  }

  Future<void> _save() async {
    final amt = double.tryParse(_amountCtrl.text.trim());
    if (amt == null || amt <= 0) { context.showSnack('Enter a valid amount', isError: true); return; }
    setState(() => _saving = true);
    final custText = _custCtrl.text.trim();
    final name = _selectedCust?.name ?? (custText.isEmpty ? 'Walk-in customer' : custText);
    await ref.read(addTransactionProvider)(Transaction(
      id: const Uuid().v4(), customerId: _selectedCust?.id, customerName: name,
      amount: amt, type: _type,
      direction: _type == TransactionType.credit ? TransactionDirection.outgoing : TransactionDirection.incoming,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      date: DateTime.now(), source: 'manual',
    ));
    if (mounted) { context.go('/dashboard'); context.showSnack('Transaction saved!'); }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = ref.watch(currentUserProvider)?.canEdit ?? true;
    if (!canEdit) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Add Transaction'), leading: BackButton(onPressed: () => context.go('/dashboard'))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.lock_outline_rounded, size: 48, color: AppColors.border),
              const SizedBox(height: 12),
              Text('View-only access', style: AppTextStyles.h4),
              const SizedBox(height: 6),
              Text('Ask the shop owner to enable editing for your account.',
                  textAlign: TextAlign.center, style: AppTextStyles.caption),
            ]),
          ),
        ),
        bottomNavigationBar: const SangamBottomNav(currentIndex: 2),
      );
    }
    final customersAsync = ref.watch(customersStreamProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Add Transaction'), leading: BackButton(onPressed: () => context.go('/dashboard'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          _ImportBtn(icon: Icons.message_outlined, label: 'Paste a UPI payment SMS', active: _showSms, onTap: () => setState(() => _showSms = !_showSms))
            .animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 14),

          if (_showSms) Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.border)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Paste UPI SMS', style: AppTextStyles.label),
              const SizedBox(height: 8),
              TextField(controller: _smsCtrl, maxLines: 3, style: AppTextStyles.bodySm,
                decoration: const InputDecoration(hintText: 'e.g. ₹500 received via Paytm UPI')),
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _parseSms, child: const Text('Parse SMS'))),
              if (_smsResult != null) Padding(padding: const EdgeInsets.only(top:8),
                child: Text(_smsResult!, style: AppTextStyles.bodySm.copyWith(color: _smsResult!.startsWith('✓') ? AppColors.success : AppColors.warning, fontWeight: FontWeight.w600))),
            ]),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0),
          if (_showSms) const SizedBox(height: 14),

          Text('PAYMENT TYPE', style: AppTextStyles.labelCaps),
          const SizedBox(height: 10),
          _TypeGrid(selected: _type, onSelect: (t) => setState(() => _type = t)),
          const SizedBox(height: 20),

          Text('AMOUNT', style: AppTextStyles.labelCaps),
          const SizedBox(height: 10),
          TextField(controller: _amountCtrl, keyboardType: TextInputType.number,
            style: AppTextStyles.h2,
            decoration: const InputDecoration(prefixText: '₹  ', hintText: '0')),
          const SizedBox(height: 20),

          Text('CUSTOMER (optional)', style: AppTextStyles.labelCaps),
          const SizedBox(height: 10),
          customersAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_,__) => TextField(controller: _custCtrl, decoration: const InputDecoration(hintText: 'Customer name')),
            data: (custs) => Autocomplete<Customer>(
              optionsBuilder: (v) => v.text.isEmpty ? const [] : custs.where((c) => c.name.toLowerCase().contains(v.text.toLowerCase())),
              displayStringForOption: (c) => c.name,
              onSelected: (c) => setState(() => _selectedCust = c),
              fieldViewBuilder: (ctx, ctrl, node, _) => TextField(controller: ctrl, focusNode: node, decoration: const InputDecoration(hintText: 'Type customer name…')),
            ),
          ),
          const SizedBox(height: 20),

          Text('NOTE (optional)', style: AppTextStyles.labelCaps),
          const SizedBox(height: 10),
          TextField(controller: _noteCtrl, decoration: const InputDecoration(hintText: 'e.g. Atta 10kg, Dal 2kg')),
          const SizedBox(height: 28),

          SizedBox(width: double.infinity, height: 56, child: ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : const Text('Save Transaction'),
          )),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }
}

class _ImportBtn extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap; final bool active;
  const _ImportBtn({required this.icon, required this.label, required this.onTap, this.active=false});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: AnimatedContainer(
    duration: const Duration(milliseconds: 150), padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: BoxDecoration(color: active ? AppColors.saffronLight : AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: active ? AppColors.saffron : AppColors.border, width: active ? 1.5 : 0.5)),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 16, color: active ? AppColors.saffron : AppColors.text3), const SizedBox(width: 8),
      Text(label, style: AppTextStyles.btnSm.copyWith(color: active ? AppColors.saffron : AppColors.text2)),
    ]),
  ));
}

class _TypeGrid extends StatelessWidget {
  final TransactionType selected; final ValueChanged<TransactionType> onSelect;
  const _TypeGrid({required this.selected, required this.onSelect});
  @override
  Widget build(BuildContext context) {
    final types = [(TransactionType.upiPaytm,'Paytm',AppColors.paytm),(TransactionType.upiGpay,'GPay',AppColors.gpay),(TransactionType.upiPhonePe,'PhonePe',AppColors.phonePe),(TransactionType.cash,'Cash',AppColors.cash),(TransactionType.credit,'Udhar',AppColors.udhar)];
    return Row(children: types.map((t) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3),
      child: GestureDetector(onTap: () => onSelect(t.$1), child: AnimatedContainer(duration: const Duration(milliseconds: 150), padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: selected==t.$1 ? t.$3 : AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: selected==t.$1 ? t.$3 : AppColors.border)),
        child: Text(t.$2, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: selected==t.$1 ? Colors.white : AppColors.text2)))))
    )).toList());
  }
}
