// ═══════════ REPORT SCREEN ═══════════
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme.dart';
import '../../providers/providers.dart';
import '../../widgets/bottom_nav.dart';

class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalsAsync = ref.watch(todayTotalsProvider);
    final overdueAsync = ref.watch(overdueCustomersProvider);
    final store = ref.watch(storeProfileProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('End-of-Day Report'), leading: BackButton(onPressed: () => context.go('/dashboard')),
        actions: [totalsAsync.when(loading: ()=>const SizedBox(), error: (_,__)=>const SizedBox(),
          data: (t) => IconButton(icon: const Icon(Icons.share_outlined), onPressed: () => Share.share(
            '*${store.name.isEmpty ? 'Sangam' : store.name} — Daily Report*\n\nCollected: \u20b9${t.totalIn.toStringAsFixed(0)}\nPaytm: \u20b9${t.paytm.toStringAsFixed(0)}\nGPay: \u20b9${t.gpay.toStringAsFixed(0)}\nPhonePe: \u20b9${t.phonePe.toStringAsFixed(0)}\nCash: \u20b9${t.cash.toStringAsFixed(0)}\nUdhar given: \u20b9${t.creditOut.toStringAsFixed(0)}\n\n_Powered by Sangam_')))]),
      body: totalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.saffron)),
        error: (e,_) => Center(child: Text('$e')),
        data: (totals) => SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
          Container(width: double.infinity, padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(gradient: AppGradients.saffron, borderRadius: BorderRadius.circular(AppRadius.xxl), boxShadow: AppShadows.saffron),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('TOTAL COLLECTED TODAY', style: AppTextStyles.labelCaps.copyWith(color: Colors.white70)),
              const SizedBox(height: 6),
              Text('₹${totals.totalIn.toStringAsFixed(0)}', style: AppTextStyles.h1.copyWith(color: Colors.white)),
              Text('${totals.txnCount} transactions', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
            ]),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 14),

          _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('UPI BREAKDOWN', style: AppTextStyles.labelCaps), const SizedBox(height: 14),
            _Bar('Paytm', totals.paytm, totals.upiTotal, AppColors.paytm),
            _Bar('GPay', totals.gpay, totals.upiTotal, AppColors.gpay),
            _Bar('PhonePe', totals.phonePe, totals.upiTotal, AppColors.phonePe),
            const Divider(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Cash', style: AppTextStyles.bodyMd), Text('₹${totals.cash.toStringAsFixed(0)}', style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w700))]),
            const Divider(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total', style: AppTextStyles.h4), Text('₹${totals.totalIn.toStringAsFixed(0)}', style: AppTextStyles.h4)]),
          ])).animate(delay: 100.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: 14),

          _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('CREDIT (UDHAR)', style: AppTextStyles.labelCaps), const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Udhar given', style: AppTextStyles.bodySm), Text('₹${totals.creditOut.toStringAsFixed(0)}', style: AppTextStyles.bodyMd.copyWith(color: AppColors.udhar, fontWeight: FontWeight.w700))]),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Credit recovered', style: AppTextStyles.bodySm), Text('₹${totals.creditIn.toStringAsFixed(0)}', style: AppTextStyles.bodyMd.copyWith(color: AppColors.success, fontWeight: FontWeight.w700))]),
          ])).animate(delay: 200.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: 14),

          overdueAsync.when(loading: ()=>const SizedBox(), error: (_,__)=>const SizedBox(), data: (overdue) {
            if (overdue.isEmpty) return const SizedBox();
            return _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Text('OUTSTANDING DUES', style: AppTextStyles.labelCaps), const Spacer(), Text('₹${overdue.fold(0.0,(s,o)=>s+o.balance).toStringAsFixed(0)}', style: AppTextStyles.bodyMd.copyWith(color: AppColors.udhar, fontWeight: FontWeight.w700))]),
              const SizedBox(height: 12),
              ...overdue.map((o) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
                Expanded(child: Text(o.customerName, style: AppTextStyles.bodySm)),
                Text('₹${o.balance.toStringAsFixed(0)}', style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w700, color: AppColors.udhar)),
              ]))),
            ]));
          }).animate(delay: 300.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: 14),

          Container(padding: const EdgeInsets.all(18), width: double.infinity,
            decoration: BoxDecoration(color: AppColors.saffronLight, borderRadius: BorderRadius.circular(AppRadius.xl)),
            child: Column(children: [
              Text('TIME SAVED TODAY', style: AppTextStyles.labelCaps.copyWith(color: AppColors.saffronDark)),
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Without Sangam'), Text('~120 min', style: TextStyle(decoration: TextDecoration.lineThrough, color: AppColors.text3))]),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('With Sangam'), Text('<1 min', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.saffron))]),
            ]),
          ).animate(delay: 400.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: 90),
        ])),
      ),
      bottomNavigationBar: const SangamBottomNav(currentIndex: 3),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child; const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(width: double.infinity, padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: AppColors.borderLight, width: 0.5)), child: child);
}

class _Bar extends StatelessWidget {
  final String label; final double amt, total; final Color color;
  const _Bar(this.label, this.amt, this.total, this.color);
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [
    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 8),
    SizedBox(width: 64, child: Text(label, style: AppTextStyles.bodySm)),
    Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: total>0?amt/total:0, minHeight: 6, backgroundColor: AppColors.border, valueColor: AlwaysStoppedAnimation(color)))),
    const SizedBox(width: 10), Text('₹${amt.toStringAsFixed(0)}', style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w600)),
  ]));
}
