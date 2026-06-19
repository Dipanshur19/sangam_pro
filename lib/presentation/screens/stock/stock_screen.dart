import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme.dart';
import '../../../domain/entities/product.dart';
import '../../providers/providers.dart';
import '../auth/login_screen.dart' show ContextSnack;

class StockScreen extends ConsumerWidget {
  const StockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsStreamProvider);
    final canEdit = ref.watch(currentUserProvider)?.canEdit ?? true;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Stock Management'),
        leading: BackButton(onPressed: () => context.go('/dashboard')),
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.saffron)),
        error: (e, _) => Center(child: Text('$e')),
        data: (items) {
          if (items.isEmpty) return const _EmptyStock();
          final totalValue = items.fold<double>(0, (s, p) => s + p.price * p.quantity);
          return Column(children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(gradient: AppGradients.saffron, borderRadius: BorderRadius.circular(AppRadius.xl), boxShadow: AppShadows.saffron),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${items.length} items in stock', style: AppTextStyles.label.copyWith(color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text('\u20b9${totalValue.toStringAsFixed(0)}', style: AppTextStyles.h2.copyWith(color: Colors.white)),
                  Text('total inventory value', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                ])),
                const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 36),
              ]),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _ProductTile(product: items[i], canEdit: canEdit),
              ),
            ),
          ]);
        },
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () => _editSheet(context, ref, null),
              backgroundColor: AppColors.saffron,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Add New Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }
}

class _EmptyStock extends StatelessWidget {
  const _EmptyStock();
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 96, height: 96,
              decoration: BoxDecoration(color: AppColors.saffronLight, borderRadius: BorderRadius.circular(28)),
              child: const Icon(Icons.inventory_2_outlined, size: 44, color: AppColors.saffron),
            ),
            const SizedBox(height: 20),
            Text('Manage your Inventory', style: AppTextStyles.h3, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Create a list of items you sell and track them here.',
                textAlign: TextAlign.center, style: AppTextStyles.body),
          ]),
        ),
      );
}

class _ProductTile extends ConsumerWidget {
  final Product product;
  final bool canEdit;
  const _ProductTile({required this.product, required this.canEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: canEdit ? () => _editSheet(context, ref, product) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.borderLight, width: 0.5),
          boxShadow: AppShadows.sm,
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: AppColors.surfaceTinted, borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(product.name.isEmpty ? '?' : product.name[0].toUpperCase(),
                style: TextStyle(color: AppColors.saffron, fontWeight: FontWeight.w700, fontSize: 16))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(product.name, style: AppTextStyles.bodyMd, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Row(children: [
              Text('\u20b9${product.price.toStringAsFixed(0)}', style: AppTextStyles.caption),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: product.isLowStock ? AppColors.warningBg : AppColors.successBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${product.quantity.toStringAsFixed(product.quantity % 1 == 0 ? 0 : 1)} ${product.unit}',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                        color: product.isLowStock ? AppColors.warning : AppColors.success)),
              ),
            ]),
          ])),
          if (canEdit) const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.text4),
        ]),
      ),
    );
  }
}

void _editSheet(BuildContext context, WidgetRef ref, Product? existing) {
  final nameCtrl = TextEditingController(text: existing?.name ?? '');
  final priceCtrl = TextEditingController(text: existing == null ? '' : existing.price.toStringAsFixed(0));
  final qtyCtrl = TextEditingController(text: existing == null ? '' : existing.quantity.toStringAsFixed(existing.quantity % 1 == 0 ? 0 : 1));
  String unit = existing?.unit ?? 'pcs';
  const units = ['pcs', 'kg', 'gm', 'ltr', 'ml', 'pkt', 'box'];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(existing == null ? 'Add new item' : 'Edit item', style: AppTextStyles.h3),
            const Spacer(),
            if (existing != null)
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                onPressed: () async {
                  await ref.read(deleteProductProvider)(existing.id);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) context.showSnack('Item deleted');
                },
              ),
          ]),
          const SizedBox(height: 12),
          TextField(controller: nameCtrl, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Item name *')),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(controller: priceCtrl, keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                decoration: const InputDecoration(labelText: 'Price', prefixText: '\u20b9 '))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: qtyCtrl, keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                decoration: const InputDecoration(labelText: 'Quantity'))),
          ]),
          const SizedBox(height: 14),
          Text('UNIT', style: AppTextStyles.labelCaps),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: units.map((u) {
            final sel = unit == u;
            return GestureDetector(
              onTap: () => setSheet(() => unit = u),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? AppColors.saffron : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(color: sel ? AppColors.saffron : AppColors.border),
                ),
                child: Text(u, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : AppColors.text2)),
              ),
            );
          }).toList()),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) { context.showSnack('Enter an item name', isError: true); return; }
                final item = Product(
                  id: existing?.id ?? const Uuid().v4(),
                  name: name,
                  price: double.tryParse(priceCtrl.text.trim()) ?? 0,
                  quantity: double.tryParse(qtyCtrl.text.trim()) ?? 0,
                  unit: unit,
                  createdAt: existing?.createdAt ?? DateTime.now(),
                );
                await ref.read(saveProductProvider)(item);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) context.showSnack(existing == null ? 'Item added' : 'Item updated');
              },
              child: Text(existing == null ? 'Add item' : 'Save changes'),
            ),
          ),
        ]),
      ),
    ),
  );
}
