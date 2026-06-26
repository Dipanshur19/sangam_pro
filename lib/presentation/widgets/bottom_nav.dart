// lib/presentation/widgets/bottom_nav.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/l10n.dart';
import '../providers/providers.dart';

class SangamBottomNav extends ConsumerWidget {
  final int currentIndex;
  const SangamBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = ref.watch(languageProvider);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.borderLight, width: 0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            _NavItem(icon: Icons.grid_view_rounded, label: tr('Home', 'होम', hi),         index: 0, current: currentIndex, route: '/dashboard'),
            _NavItem(icon: Icons.people_outline_rounded, label: tr('Customers', 'ग्राहक', hi), index: 1, current: currentIndex, route: '/customers'),
            _NavItem(icon: Icons.add_circle_outline_rounded, label: tr('Add', 'जोड़ें', hi),  index: 2, current: currentIndex, route: '/add'),
            _NavItem(icon: Icons.description_outlined, label: tr('Report', 'रिपोर्ट', hi),  index: 3, current: currentIndex, route: '/report'),
          ]),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon; final String label; final int index, current; final String route;
  const _NavItem({required this.icon, required this.label, required this.index, required this.current, required this.route});

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => active ? null : context.go(route),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: active ? 16 : 0, vertical: 4),
              decoration: BoxDecoration(
                color: active ? AppColors.saffronLight : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Icon(icon, size: 22, color: active ? AppColors.saffron : AppColors.text4),
            ),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(
              fontFamily: 'Poppins', fontSize: 10, fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? AppColors.saffron : AppColors.text4,
            )),
          ]),
        ),
      ),
    );
  }
}
