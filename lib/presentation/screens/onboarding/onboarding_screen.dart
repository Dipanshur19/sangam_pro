import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final PageController _ctrl = PageController();
  int _page = 0;
  late AnimationController _bgCtrl;
  late Animation<double> _bgAnim;

  final _slides = [
    _Slide(
      title: 'One store.\nFour apps.\nTwo hours wasted.',
      subtitle: 'Most shop owners spend hours every night reconciling Paytm, GPay, PhonePe, khata and pen-paper. Manually.',
      color: AppColors.saffron,
      accent: AppColors.saffronLight,
      painter: _ConfusedPainter(),
    ),
    _Slide(
      title: 'Sangam brings it\nall together.',
      subtitle: 'One tap shows today\'s complete picture — UPI from every app, cash, and credit — in under 3 seconds.',
      color: AppColors.gpay,
      accent: AppColors.gpayBg,
      painter: _UnifiedPainter(),
    ),
    _Slide(
      title: 'Staff. Customers.\nReminders. Done.',
      subtitle: 'Staff check balances without calling you. WhatsApp reminders send in one tap. Photos of your khata import automatically.',
      color: AppColors.cash,
      accent: AppColors.cashBg,
      painter: _HappyPainter(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _bgAnim = _bgCtrl.drive(Tween(begin: 0.0, end: 1.0));
  }

  @override
  void dispose() { _bgCtrl.dispose(); _ctrl.dispose(); super.dispose(); }

  Future<void> _finish() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('sangam_onboarded', true);
    if (mounted) context.go('/store-setup');
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_page];
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(color: slide.accent),
        child: Stack(children: [
          // Background animation
          AnimatedBuilder(animation: _bgAnim, builder: (_, __) =>
            CustomPaint(painter: _BgPainter(_bgAnim.value, slide.color), child: const SizedBox.expand())),

          SafeArea(child: Column(children: [
            // Skip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                if (_page < 2)
                  TextButton(onPressed: _finish,
                    child: Text('Skip', style: AppTextStyles.bodySm.copyWith(color: slide.color, fontWeight: FontWeight.w600))),
              ]),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _slides.length,
                itemBuilder: (_, i) => _SlidePage(slide: _slides[i], isActive: i == _page),
              ),
            ),

            // Indicators + button
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 40),
              child: Column(children: [
                // Dots
                Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(_slides.length, (i) =>
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 24 : 8, height: 8,
                    decoration: BoxDecoration(
                      color: i == _page ? slide.color : slide.color.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ))),
                const SizedBox(height: 28),

                // CTA Button
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [slide.color.withRed(slide.color.red + 30), slide.color]),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    boxShadow: AppShadows.glow(slide.color),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      onTap: () {
                        if (_page < 2) {
                          _ctrl.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOutCubic);
                        } else {
                          _finish();
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        child: Text(_page < 2 ? 'Next →' : 'Get Started →',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.btn.copyWith(color: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ])),
        ]),
      ),
    );
  }
}

class _SlidePage extends StatelessWidget {
  final _Slide slide; final bool isActive;
  const _SlidePage({required this.slide, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(children: [
        const SizedBox(height: 16),
        // Illustration
        Expanded(
          flex: 5,
          child: isActive
            ? CustomPaint(painter: slide.painter, child: const SizedBox.expand())
                .animate().scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), duration: 600.ms, curve: Curves.elasticOut)
                .fadeIn(duration: 400.ms)
            : CustomPaint(painter: slide.painter, child: const SizedBox.expand()),
        ),
        const SizedBox(height: 24),

        // Title
        if (isActive)
          Text(slide.title, style: AppTextStyles.h2.copyWith(color: AppColors.text1, height: 1.2), textAlign: TextAlign.center)
            .animate().slideY(begin: 0.3, end: 0, duration: 500.ms, delay: 200.ms, curve: Curves.easeOut)
            .fadeIn(duration: 400.ms, delay: 200.ms)
        else
          Text(slide.title, style: AppTextStyles.h2.copyWith(color: AppColors.text1, height: 1.2), textAlign: TextAlign.center),

        const SizedBox(height: 16),

        // Subtitle
        if (isActive)
          Text(slide.subtitle, style: AppTextStyles.body.copyWith(color: AppColors.text2, height: 1.6), textAlign: TextAlign.center)
            .animate().slideY(begin: 0.3, end: 0, duration: 500.ms, delay: 350.ms, curve: Curves.easeOut)
            .fadeIn(duration: 400.ms, delay: 350.ms)
        else
          Text(slide.subtitle, style: AppTextStyles.body.copyWith(color: AppColors.text2, height: 1.6), textAlign: TextAlign.center),

        const SizedBox(height: 16),
      ]),
    );
  }
}

class _Slide {
  final String title, subtitle; final Color color, accent;
  final CustomPainter painter;
  const _Slide({required this.title, required this.subtitle, required this.color, required this.accent, required this.painter});
}

// ── Custom Painters for illustrations ───────────────────

class _ConfusedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final p = Paint()..style = PaintingStyle.fill;

    // Draw 4 overlapping chaotic circles representing 4 apps
    final colors = [AppColors.paytm, AppColors.gpay, AppColors.phonePe, AppColors.cash];
    final positions = [Offset(cx - 70, cy - 40), Offset(cx + 70, cy - 40), Offset(cx - 40, cy + 60), Offset(cx + 50, cy + 50)];
    for (int i = 0; i < 4; i++) {
      p.color = colors[i].withOpacity(0.15);
      canvas.drawCircle(positions[i], 70, p);
      p.color = colors[i].withOpacity(0.4);
      p.style = PaintingStyle.stroke;
      p.strokeWidth = 3;
      canvas.drawCircle(positions[i], 70, p);
      p.style = PaintingStyle.fill;
    }

    // Question mark in center
    p.color = AppColors.text1.withOpacity(0.3);
    canvas.drawCircle(Offset(cx, cy), 28, p);
    final tp = TextPainter(text: TextSpan(text: '?', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.text1.withOpacity(0.6))), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }
  @override
  bool shouldRepaint(_) => false;
}

class _UnifiedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final p = Paint()..style = PaintingStyle.fill;

    // Central hub
    p.color = AppColors.saffron.withOpacity(0.15);
    canvas.drawCircle(Offset(cx, cy), 55, p);
    p.color = AppColors.saffron;
    p.style = PaintingStyle.stroke; p.strokeWidth = 3;
    canvas.drawCircle(Offset(cx, cy), 55, p);
    p.style = PaintingStyle.fill;

    // Sangam symbol in center
    p.color = AppColors.saffron;
    canvas.drawCircle(Offset(cx, cy), 16, p);

    // 4 source circles connected by lines
    final colors = [AppColors.paytm, AppColors.gpay, AppColors.phonePe, AppColors.cash];
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2 - math.pi / 4;
      final ox = cx + math.cos(angle) * 110;
      final oy = cy + math.sin(angle) * 110;

      // Connection line
      final linePaint = Paint()..color = colors[i].withOpacity(0.5)..strokeWidth = 2.5..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(cx, cy), Offset(ox, oy), linePaint);

      // Source circle
      p.color = colors[i].withOpacity(0.2);
      canvas.drawCircle(Offset(ox, oy), 32, p);
      p.color = colors[i]; p.style = PaintingStyle.stroke; p.strokeWidth = 2.5;
      canvas.drawCircle(Offset(ox, oy), 32, p);
      p.style = PaintingStyle.fill;

      p.color = colors[i];
      canvas.drawCircle(Offset(ox, oy), 10, p);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

class _HappyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final p = Paint()..style = PaintingStyle.fill;

    // Central happy store icon
    p.color = AppColors.success.withOpacity(0.12);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy), width: 120, height: 100), const Radius.circular(20)), p);
    p.color = AppColors.success;
    p.style = PaintingStyle.stroke; p.strokeWidth = 3;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy), width: 120, height: 100), const Radius.circular(20)), p);

    // Checkmarks orbiting
    p.style = PaintingStyle.fill;
    for (int i = 0; i < 3; i++) {
      final angle = i * 2 * math.pi / 3 - math.pi / 2;
      final ox = cx + math.cos(angle) * 110;
      final oy = cy + math.sin(angle) * 110;
      p.color = AppColors.success.withOpacity(0.15);
      canvas.drawCircle(Offset(ox, oy), 28, p);
      final tp = TextPainter(text: const TextSpan(text: '✓', style: TextStyle(fontSize: 22, color: AppColors.success, fontWeight: FontWeight.w700)), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(ox - tp.width / 2, oy - tp.height / 2));
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

class _BgPainter extends CustomPainter {
  final double t; final Color color;
  _BgPainter(this.t, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color.withOpacity(0.05)..style = PaintingStyle.fill;
    for (int i = 0; i < 3; i++) {
      final phase = (t + i / 3) % 1.0;
      final r = size.width * (0.3 + phase * 0.5);
      canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.2), r, p);
    }
  }
  @override
  bool shouldRepaint(_BgPainter old) => old.t != t;
}
