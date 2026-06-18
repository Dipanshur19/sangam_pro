import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// The Sangam brand mark: an app-icon style squircle with a "confluence" symbol —
/// three streams (UPI · Cash · Udhar) merging into one node — finished with a
/// glossy highlight for depth. Set [animate] to gently rotate the streams.
class SangamLogo extends StatefulWidget {
  final double size;
  final bool animate;
  final bool showBackground;

  const SangamLogo({
    super.key,
    this.size = 96,
    this.animate = true,
    this.showBackground = true,
  });

  @override
  State<SangamLogo> createState() => _SangamLogoState();
}

class _SangamLogoState extends State<SangamLogo> with SingleTickerProviderStateMixin {
  AnimationController? _ctrl;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.size * 0.26;
    final mark = AnimatedBuilder(
      animation: _ctrl ?? const AlwaysStoppedAnimation(0),
      builder: (_, __) => CustomPaint(
        size: Size.square(widget.size),
        painter: _ConfluencePainter(_ctrl?.value ?? 0),
      ),
    );

    if (!widget.showBackground) {
      return SizedBox(width: widget.size, height: widget.size, child: mark);
    }

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        gradient: AppGradients.saffron,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(color: AppColors.saffron.withOpacity(0.38), blurRadius: widget.size * 0.28, offset: Offset(0, widget.size * 0.08)),
        ],
      ),
      child: Stack(children: [
        // Glossy top highlight
        Positioned(
          top: 0, left: 0, right: 0, height: widget.size * 0.5,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.white.withOpacity(0.22), Colors.white.withOpacity(0.0)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
            ),
          ),
        ),
        // Soft inner ring
        Center(
          child: Container(
            width: widget.size * 0.74,
            height: widget.size * 0.74,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.16), width: widget.size * 0.012),
            ),
          ),
        ),
        mark,
      ]),
    );
  }
}

class _ConfluencePainter extends CustomPainter {
  final double t;
  _ConfluencePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r = size.width * 0.30;
    final spin = t * 2 * math.pi;

    final stream = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.058
      ..strokeCap = StrokeCap.round
      ..color = Colors.white;

    final tipColors = [
      Colors.white,
      Colors.white.withOpacity(0.92),
      Colors.white.withOpacity(0.82),
    ];

    // Three streams curving from the rim into the centre.
    for (int i = 0; i < 3; i++) {
      final angle = (i * 2 * math.pi / 3) + spin * 0.15;
      final start = Offset(cx + math.cos(angle) * r, cy + math.sin(angle) * r);
      final control = Offset(
        cx + math.cos(angle + 0.9) * r * 0.55,
        cy + math.sin(angle + 0.9) * r * 0.55,
      );
      final end = Offset(cx, cy);

      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
      stream.color = tipColors[i];
      canvas.drawPath(path, stream);

      // Source node at each stream tip.
      canvas.drawCircle(start, size.width * 0.045, Paint()..color = tipColors[i]);
    }

    // Central confluence node with a subtle inner accent.
    canvas.drawCircle(Offset(cx, cy), size.width * 0.105, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(cx, cy), size.width * 0.052, Paint()..color = AppColors.saffron);
  }

  @override
  bool shouldRepaint(_ConfluencePainter old) => old.t != t;
}
