import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/winter_arc_theme.dart';

class ProgressRing extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final Widget? centerChild;

  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 104,
    this.strokeWidth = 10,
    this.centerChild,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: progress.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: _ProgressRingPainter(
                  progress: value,
                  strokeWidth: strokeWidth,
                ),
              ),
              if (centerChild != null)
                centerChild!
              else
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(value * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: WinterArcTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'DONE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: WinterArcTheme.neoYellow,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;

  _ProgressRingPainter({
    required this.progress,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track Paint (Dark Charcoal Track with black border effect)
    final trackPaint = Paint()
      ..color = WinterArcTheme.surfaceElevated
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0.0) return;

    // Active Neubrutalist Arc
    final activePaint = Paint()
      ..color = WinterArcTheme.neoYellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.strokeWidth != strokeWidth;
  }
}
