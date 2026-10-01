import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/winter_arc_theme.dart';

class AnimatedCheckButton extends StatefulWidget {
  final bool isChecked;
  final VoidCallback onTap;
  final double size;

  const AnimatedCheckButton({
    super.key,
    required this.isChecked,
    required this.onTap,
    this.size = 42,
  });

  @override
  State<AnimatedCheckButton> createState() => _AnimatedCheckButtonState();
}

class _AnimatedCheckButtonState extends State<AnimatedCheckButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.82), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.82, end: 1.18), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.18, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.mediumImpact();
    _controller.forward(from: 0.0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: widget.isChecked
                    ? WinterArcTheme.neoMint
                    : WinterArcTheme.surfaceElevated,
                border: const Border.fromBorderSide(
                  BorderSide(
                    color: WinterArcTheme.borderBlack,
                    width: 2.2,
                  ),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: WinterArcTheme.borderBlack,
                    offset: Offset(2.5, 2.5),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: anim,
                    child: child,
                  ),
                  child: widget.isChecked
                      ? const Icon(
                          Icons.check_rounded,
                          key: ValueKey('checked'),
                          color: Colors.black,
                          size: 24,
                          weight: 900,
                        )
                      : Icon(
                          Icons.circle_outlined,
                          key: const ValueKey('unchecked'),
                          color: Colors.white.withOpacity(0.3),
                          size: 16,
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
