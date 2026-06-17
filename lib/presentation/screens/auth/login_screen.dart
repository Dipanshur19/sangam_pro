import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../core/theme.dart';
import '../../providers/providers.dart';

// ── Phone Entry Screen ──────────────────────────────────
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  final _phoneCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  late AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() { _phoneCtrl.dispose(); _shimmerCtrl.dispose(); super.dispose(); }

  Future<void> _sendOtp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      await ref.read(authServiceProvider).sendOtp('+91${_phoneCtrl.text.trim()}');
      if (mounted) context.go('/otp', extra: _phoneCtrl.text.trim());
    } catch (e) {
      if (mounted) context.showSnack('Could not send OTP. Try again.', isError: true);
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 40),

              // Sangam logo + wordmark
              Row(children: [
                _AnimatedSangamMark(size: 48),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Sangam', style: AppTextStyles.h3.copyWith(color: AppColors.saffron)),
                  Text('Sab ka ek hisaab', style: AppTextStyles.caption),
                ]),
              ]).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2, end: 0, duration: 600.ms, curve: Curves.easeOut),

              const SizedBox(height: 52),

              Text('Welcome back', style: AppTextStyles.h1)
                .animate(delay: 200.ms).fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0, duration: 500.ms),

              const SizedBox(height: 8),

              Text('Enter your mobile number to continue', style: AppTextStyles.body)
                .animate(delay: 300.ms).fadeIn(duration: 500.ms),

              const SizedBox(height: 40),

              // Phone input
              Text('MOBILE NUMBER', style: AppTextStyles.labelCaps)
                .animate(delay: 400.ms).fadeIn(),

              const SizedBox(height: 10),

              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: AppTextStyles.h3.copyWith(letterSpacing: 3),
                validator: (v) {
                  if (v == null || v.length != 10) return 'Enter a valid 10-digit number';
                  return null;
                },
                decoration: InputDecoration(
                  counterText: '',
                  prefixIcon: Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.saffronLight, borderRadius: BorderRadius.circular(8)),
                    child: Text('+91', style: AppTextStyles.bodyMd.copyWith(color: AppColors.saffron, fontWeight: FontWeight.w700)),
                  ),
                  hintText: '98765 43210',
                  hintStyle: AppTextStyles.h3.copyWith(color: AppColors.text4, letterSpacing: 2),
                ),
              ).animate(delay: 450.ms).fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 32),

              // Send OTP button
              _GradientButton(
                label: _loading ? '' : 'Send OTP →',
                loading: _loading,
                onTap: _sendOtp,
              ).animate(delay: 550.ms).fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 28),

              // Alternative: Demo login
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(children: [
                  Text('Quick access', style: AppTextStyles.label.copyWith(color: AppColors.text3)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _DemoBtn(label: 'Owner', onTap: () => context.go('/dashboard'))),
                    const SizedBox(width: 10),
                    Expanded(child: _DemoBtn(label: 'Staff', onTap: () => context.go('/staff'))),
                  ]),
                ]),
              ).animate(delay: 650.ms).fadeIn(duration: 500.ms),

              const SizedBox(height: 40),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── OTP Verification Screen ─────────────────────────────
class OtpScreen extends ConsumerStatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});
  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> with TickerProviderStateMixin {
  String _otp = '';
  bool _loading = false;
  bool _success = false;
  int _resendSeconds = 30;
  int _timerGen = 0;
  late AnimationController _successCtrl;

  @override
  void initState() {
    super.initState();
    _successCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _startTimer();
  }

  void _startTimer() async {
    final gen = ++_timerGen;
    setState(() => _resendSeconds = 30);
    for (int i = 30; i >= 0; i--) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || gen != _timerGen) return;
      setState(() => _resendSeconds = i);
    }
  }

  @override
  void dispose() { _successCtrl.dispose(); super.dispose(); }

  Future<void> _verify() async {
    if (_otp.length != 6) return;
    setState(() => _loading = true);
    try {
      final success = await ref.read(authServiceProvider).verifyOtp(_otp);
      if (success && mounted) {
        setState(() { _success = true; _loading = false; });
        _successCtrl.forward();
        await Future.delayed(const Duration(milliseconds: 1200));
        if (mounted) context.go('/dashboard');
      } else {
        setState(() => _loading = false);
        if (mounted) context.showSnack('Wrong OTP. Try again.', isError: true);
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) context.showSnack('Verification failed.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: BackButton(onPressed: () => context.go('/login')),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 16),

          Text('Verify your number', style: AppTextStyles.h2)
            .animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),

          const SizedBox(height: 8),

          Text('We sent a 6-digit OTP to +91 ${widget.phone}', style: AppTextStyles.body)
            .animate(delay: 100.ms).fadeIn(),

          const SizedBox(height: 44),

          // OTP boxes
          PinCodeTextField(
            appContext: context,
            length: 6,
            obscureText: false,
            animationType: AnimationType.fade,
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              borderRadius: BorderRadius.circular(AppRadius.md),
              fieldHeight: 56,
              fieldWidth: 46,
              activeFillColor: AppColors.surface,
              selectedFillColor: AppColors.saffronLight,
              inactiveFillColor: AppColors.surface,
              activeColor: AppColors.saffron,
              selectedColor: AppColors.saffron,
              inactiveColor: AppColors.border,
            ),
            animationDuration: const Duration(milliseconds: 200),
            enableActiveFill: true,
            keyboardType: TextInputType.number,
            onCompleted: (v) { setState(() => _otp = v); _verify(); },
            onChanged: (v) => setState(() => _otp = v),
            beforeTextPaste: (t) => true,
            textStyle: AppTextStyles.h3.copyWith(letterSpacing: 2),
          ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.3, end: 0),

          const SizedBox(height: 32),

          // Verify button
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _success
              ? Container(
                  height: 56, width: double.infinity,
                  decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(AppRadius.xl)),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.check_circle_rounded, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Verified!', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  ]),
                ).animate().scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), curve: Curves.elasticOut)
              : _GradientButton(label: 'Verify OTP', loading: _loading, onTap: _otp.length == 6 ? _verify : null),
          ),

          const SizedBox(height: 24),

          // Resend
          Center(child: _resendSeconds > 0
            ? Text('Resend OTP in $_resendSeconds seconds', style: AppTextStyles.bodySm.copyWith(color: AppColors.text3))
            : GestureDetector(
                onTap: () async {
                  try {
                    await ref.read(authServiceProvider).sendOtp('+91${widget.phone}');
                    _startTimer();
                    if (mounted) context.showSnack('OTP resent');
                  } catch (e) {
                    if (mounted) context.showSnack('Could not resend OTP', isError: true);
                  }
                },
                child: Text('Resend OTP', style: AppTextStyles.bodySm.copyWith(color: AppColors.saffron, fontWeight: FontWeight.w600)),
              )),
        ]),
      ),
    );
  }
}

// ── Shared widgets ──────────────────────────────────────

class _AnimatedSangamMark extends StatefulWidget {
  final double size;
  const _AnimatedSangamMark({required this.size});
  @override
  State<_AnimatedSangamMark> createState() => _AnimatedSangamMarkState();
}

class _AnimatedSangamMarkState extends State<_AnimatedSangamMark> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() { super.initState(); _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (_, __) => Container(
      width: widget.size, height: widget.size,
      decoration: BoxDecoration(
        gradient: AppGradients.saffron,
        borderRadius: BorderRadius.circular(widget.size * 0.28),
        boxShadow: AppShadows.saffron,
      ),
      child: CustomPaint(painter: _MiniLogoPainter(_ctrl.value)),
    ),
  );
}

class _MiniLogoPainter extends CustomPainter {
  final double t;
  _MiniLogoPainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r = size.width * 0.28;
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07
      ..strokeCap = StrokeCap.round;
    // Three converging arcs — Paytm, GPay, PhonePe = Sangam.
    for (int i = 0; i < 3; i++) {
      final angle = (i * 2 * math.pi / 3) + (t * 2 * math.pi * 0.25);
      final center = Offset(cx + (r * 0.35) * math.cos(angle), cy + (r * 0.35) * math.sin(angle));
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r * 0.65),
        angle - math.pi / 2, math.pi, false, paint,
      );
    }
    canvas.drawCircle(Offset(cx, cy), size.width * 0.08, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_MiniLogoPainter old) => old.t != t;
}

class _GradientButton extends StatefulWidget {
  final String label; final bool loading; final VoidCallback? onTap;
  const _GradientButton({required this.label, required this.loading, this.onTap});
  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() { super.initState(); _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: widget.onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 58,
      decoration: BoxDecoration(
        gradient: widget.onTap != null ? AppGradients.saffron : const LinearGradient(colors: [Color(0xFFCCCCCC), Color(0xFFBBBBBB)]),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: widget.onTap != null ? AppShadows.saffron : [],
      ),
      child: Center(child: widget.loading
        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
        : Text(widget.label, style: AppTextStyles.btn.copyWith(color: Colors.white))),
    ),
  );
}

class _DemoBtn extends StatelessWidget {
  final String label; final VoidCallback onTap;
  const _DemoBtn({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.saffronLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.saffron.withOpacity(0.3)),
      ),
      child: Text(label, textAlign: TextAlign.center, style: AppTextStyles.btnSm.copyWith(color: AppColors.saffron)),
    ),
  );
}

extension ContextSnack on BuildContext {
  void showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.text1,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      margin: const EdgeInsets.all(16),
    ));
  }
}
