import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme.dart';
import '../../../domain/entities/customer.dart';
import '../../providers/providers.dart';
import '../../widgets/bottom_nav.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});
  @override
  ConsumerState<CustomersScreen> createState() => _S();
}

class _S extends ConsumerState<CustomersScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersStreamProvider);
    final canEdit = ref.watch(currentUserProvider)?.canEdit ?? true;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Customers'),
        leading: BackButton(onPressed: () => context.go('/dashboard')),
        actions: [
          if (canEdit)
            TextButton.icon(
              onPressed: () => _showAddSheet(context),
              icon: const Icon(Icons.person_add_outlined, size: 16, color: AppColors.saffron),
              label: Text('New', style: AppTextStyles.btnSm.copyWith(color: AppColors.saffron)),
            ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search customers…',
              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.text3),
              suffixIcon: _query.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 16), onPressed: () { _searchCtrl.clear(); setState(() => _query = ''); }) : null,
            ),
          ),
        ),
        Expanded(child: customersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.saffron)),
          error: (e, _) => Center(child: Text('$e')),
          data: (customers) {
            final filtered = customers.where((c) => c.name.toLowerCase().contains(_query.toLowerCase())).toList();
            if (filtered.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.people_outline, size: 48, color: AppColors.border),
              const SizedBox(height: 12),
              Text(_query.isEmpty ? 'No customers yet' : 'No match for "$_query"', style: AppTextStyles.caption),
            ]));
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _CustomerTile(customer: filtered[i])
                  .animate(delay: Duration(milliseconds: i * 40)).fadeIn(duration: 300.ms).slideX(begin: -0.05, end: 0),
            );
          },
        )),
      ]),
      bottomNavigationBar: const SangamBottomNav(currentIndex: 1),
    );
  }

  void _showAddSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Add new customer', style: AppTextStyles.h3),
          const SizedBox(height: 16),
          TextField(controller: nameCtrl, autofocus: true, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Customer name *')),
          const SizedBox(height: 12),
          TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone (optional)', prefixText: '+91 ')),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              await ref.read(addCustomerProvider)(Customer(id: const Uuid().v4(), name: nameCtrl.text.trim(), phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(), createdAt: DateTime.now()));
              if (ctx.mounted) Navigator.pop(ctx);
            }, child: const Text('Save'))),
          ]),
        ]),
      ),
    );
  }
}

class _CustomerTile extends ConsumerWidget {
  final Customer customer;
  const _CustomerTile({required this.customer});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balAsync = ref.watch(customerBalanceProvider(customer.id));
    return GestureDetector(
      onTap: () => context.push('/customer/${customer.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.borderLight, width: 0.5), boxShadow: AppShadows.sm),
        child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.saffronLight, shape: BoxShape.circle),
              child: Center(child: Text(customer.name[0].toUpperCase(), style: TextStyle(color: AppColors.saffron, fontWeight: FontWeight.w700, fontSize: 16)))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(customer.name, style: AppTextStyles.bodyMd, maxLines: 1, overflow: TextOverflow.ellipsis),
            balAsync.when(
              loading: () => const SizedBox(height: 12),
              error: (_, __) => const SizedBox(),
              data: (bal) {
                final settled = bal <= 0;
                return Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: settled ? AppColors.successBg : AppColors.warningBg, borderRadius: BorderRadius.circular(20)),
                  child: Text(settled ? 'Settled' : 'Pending', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: settled ? AppColors.success : AppColors.warning)));
              },
            ),
          ])),
          balAsync.when(
            loading: () => const SizedBox(width: 50, child: LinearProgressIndicator()),
            error: (_, __) => const SizedBox(),
            data: (bal) => Row(mainAxisSize: MainAxisSize.min, children: [
              Text(bal > 0 ? '₹${bal.toStringAsFixed(0)}' : '✓', style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w700, color: bal > 0 ? AppColors.udhar : AppColors.success)),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.text4),
            ]),
          ),
        ]),
      ),
    );
  }
}
