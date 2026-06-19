import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../providers/providers.dart';

class StaffScreen extends ConsumerStatefulWidget {
  const StaffScreen({super.key});
  @override
  ConsumerState<StaffScreen> createState() => _S();
}

class _S extends ConsumerState<StaffScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersStreamProvider);
    final store = ref.watch(storeProfileProvider);
    final found = _query.isEmpty ? null : (customersAsync.value ?? []).where((c) => c.name.toLowerCase().contains(_query.toLowerCase())).firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 0), child: Row(children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(gradient: AppGradients.saffron, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.water_drop_outlined, size: 16, color: Colors.white)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Sangam', style: AppTextStyles.h4),
              Text('${store.name.isEmpty ? 'Store' : store.name} · Staff',
                  style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
          TextButton(onPressed: () => context.go('/login'), child: Text('Exit', style: AppTextStyles.bodySm.copyWith(color: AppColors.text3))),
        ])),

        const SizedBox(height: 40),
        Text('Customer Balance Lookup', style: AppTextStyles.h2).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 8),
        Text('Type a name to see their balance', style: AppTextStyles.body).animate(delay: 100.ms).fadeIn(),
        const SizedBox(height: 28),

        Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: TextField(
          controller: _searchCtrl, autofocus: true, textCapitalization: TextCapitalization.words,
          style: AppTextStyles.h3,
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: 'Customer name…', prefixIcon: const Icon(Icons.search_rounded, size: 24),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.xl), borderSide: const BorderSide(color: AppColors.border, width: 2)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.xl), borderSide: const BorderSide(color: AppColors.saffron, width: 2)),
          ),
        )).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

        const SizedBox(height: 20),

        if (_query.isNotEmpty) Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child:
          found != null ? _Result(customerId: found.id, name: found.name).animate().scale(begin: const Offset(0.9,0.9), end: const Offset(1,1), curve: Curves.elasticOut)
            : Container(padding: const EdgeInsets.all(28), width: double.infinity, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: AppColors.border)),
                child: Column(children: [const Icon(Icons.person_search_outlined, size: 36, color: AppColors.border), const SizedBox(height: 8), Text('No customer found', style: AppTextStyles.bodyMd)])),
        ),
      ])),
    );
  }
}

class _Result extends ConsumerWidget {
  final String customerId; final String name;
  const _Result({required this.customerId, required this.name});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balAsync = ref.watch(customerBalanceProvider(customerId));
    final ownerName = ref.watch(storeProfileProvider).ownerName;
    final contact = ownerName.isEmpty ? 'the owner' : '$ownerName ji';
    return Container(padding: const EdgeInsets.all(32), width: double.infinity,
      decoration: BoxDecoration(gradient: AppGradients.saffron, borderRadius: BorderRadius.circular(AppRadius.xxl), boxShadow: AppShadows.saffron),
      child: Column(children: [
        Container(width: 64, height: 64, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: Center(child: Text(name[0], style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)))),
        const SizedBox(height: 14),
        Text(name, style: AppTextStyles.h3.copyWith(color: Colors.white)),
        const SizedBox(height: 10),
        balAsync.when(
          loading: () => const CircularProgressIndicator(color: Colors.white),
          error: (_, __) => const Text('Error', style: TextStyle(color: Colors.white)),
          data: (bal) => Column(children: [
            Text(bal > 0 ? '₹${bal.toStringAsFixed(0)}' : '✓ Settled', style: AppTextStyles.h1.copyWith(color: Colors.white)),
            Text(bal > 0 ? 'outstanding balance' : 'No dues', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
          ]),
        ),
        const SizedBox(height: 14),
        Text('Read-only · Contact $contact for changes', style: AppTextStyles.caption.copyWith(color: Colors.white60), textAlign: TextAlign.center),
      ]),
    );
  }
}
