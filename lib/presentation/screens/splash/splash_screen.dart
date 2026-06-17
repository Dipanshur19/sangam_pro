import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../providers/providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _fadeCtrl;
  late AnimationController _textCtrl;

  late Animation<double> _logoScale;
  late Animation<double> _logoRotate;
  late Animation<double> _logoOpacity;
  late Animation<double> _particleProgress;
  late Animation<double> _textOpacity;
  late Animation<double> _textSlide;
  late Animation<double> _bgFade;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _particleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    _logoScale   = CurvedAnimation(parent: _logoCtrl, curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)).drive(Tween(begin: 0.0, end: 1.0));
    _logoRotate  = CurvedAnimation(parent: _logoCtrl, curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack)).drive(Tween(begin: -0.5, end: 0.0));
    _logoOpacity = CurvedAnimation(parent: _logoCtrl, curve: const Interval(0.0, 0.3)).drive(Tween(begin: 0.0, end: 1.0));
    _particleProgress = _particleCtrl.drive(Tween(begin: 0.0, end: 1.0));
    _textOpacity = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut).drive(Tween(begin: 0.0, end: 1.0));
    _textSlide   = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut).drive(Tween(begin: 20.0, end: 0.0));
    _bgFade      = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn).drive(Tween(begin: 1.0, end: 0.0));

    _startSequence();
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    _textCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 1800));
    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;

    // Route based on whether the shop has been set up yet.
    final profile = await ref.read(localSourceProvider).getStoreProfile();
    if (profile.isConfigured) {
      if (mounted) context.go('/dashboard');
      return;
    }

    final onboarded = await ref.read(onboardedProvider.future);
    if (mounted) context.go(onboarded ? '/store-setup' : '/onboarding');
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _particleCtrl.dispose();
    _fadeCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.saffron),
        child: Stack(children: [
          // Animated particle background
          AnimatedBuilder(
            animation: _particleProgress,
            builder: (_, __) => CustomPaint(
              painter: _ParticlePainter(_particleProgress.value),
              child: const SizedBox.expand(),
            ),
          ),

          // Logo + text center
          Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            // 3D Logo
            AnimatedBuilder(
              animation: _logoCtrl,
              builder: (_, __) => Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(_logoRotate.value * math.pi)
                  ..scale(_logoScale.value),
                child: Opacity(
                  opacity: _logoOpacity.value.clamp(0.0, 1.0),
                  child: _SangamLogo(size: 100),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Text
            AnimatedBuilder(
              animation: _textCtrl,
              builder: (_, __) => Opacity(
                opacity: _textOpacity.value,
                child: Transform.translate(
                  offset: Offset(0, _textSlide.value),
                  child: Column(children: [
                    Text('Sangam', style: AppTextStyles.h1.copyWith(color: Colors.white, letterSpacing: 0)),
                    const SizedBox(height: 4),
                    Text('Sab ka ek hisaab', style: AppTextStyles.body.copyWith(color: Colors.white.withOpacity(0.8))),
                  ]),
                ),
              ),
            ),
          ])),

          // Version
          Positioned(
            bottom: 32, left: 0, right: 0,
            child: AnimatedBuilder(
              animation: _textCtrl,
              builder: (_, __) => Opacity(
                opacity: _textOpacity.value * 0.6,
                child: Text('v2.0', textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(color: Colors.white70)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Sangam Logo Widget ──────────────────────────────────
class _SangamLogo extends StatefulWidget {
  final double size;
  const _SangamLogo({required this.size});
  @override
  State<_SangamLogo> createState() => _SangamLogoState();
}

class _SangamLogoState extends State<_SangamLogo> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (_, __) => Container(
      width: widget.size, height: widget.size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 30, spreadRadius: 5)],
      ),
      child: CustomPaint(painter: _LogoPainter(_anim.value)),
    ),
  );
}

class _LogoPainter extends CustomPainter {
  final double t;
  _LogoPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r = size.width * 0.28;
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.055
      ..strokeCap = StrokeCap.round;

    // Three arcs converging — Paytm, GPay, PhonePe = Sangam
    for (int i = 0; i < 3; i++) {
      final angle = (i * 2 * math.pi / 3) + (t * 2 * math.pi * 0.3);
      final startAngle = angle - math.pi * 0.6;
      final sweepAngle = math.pi * 1.0;

      final arcPath = Path()
        ..addArc(Rect.fromCircle(center: Offset(cx + math.cos(angle) * r * 0.35, cy + math.sin(angle) * r * 0.35), radius: r * 0.7), startAngle, sweepAngle);

      canvas.drawPath(arcPath, paint..color = Colors.white.withOpacity(0.85 + 0.15 * math.sin(t * math.pi * 2 + i)));
    }

    // Center confluence dot
    canvas.drawCircle(Offset(cx, cy), size.width * 0.07, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.t != t;
}

// ── Particle Painter ────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final double t;
  _ParticlePainter(this.t);

  static final _rng = math.Random(42);
  static final _particles = List.generate(40, (i) => [
    _rng.nextDouble(), _rng.nextDouble(),
    _rng.nextDouble() * 0.4 + 0.1,
    _rng.nextDouble() * 2 * math.pi,
    _rng.nextDouble() * 0.3 + 0.1,
  ]);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in _particles) {
      final phase = (t + p[3] / (2 * math.pi)) % 1.0;
      final opacity = math.sin(phase * math.pi) * p[4];
      if (opacity <= 0) continue;
      final x = (p[0] + math.cos(p[3]) * phase * 0.15) * size.width;
      final y = (p[1] - phase * 0.6) * size.height;
      paint.color = Colors.white.withOpacity(opacity * 0.5);
      canvas.drawCircle(Offset(x, y), p[2] * 4, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.t != t;
}
