import 'package:flutter/material.dart';
import '../theme/winter_arc_theme.dart';

class FrostCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final bool glow;
  final Color? glowColor;
  final Color? borderColor;
  final Color? fillColor;
  final Gradient? gradient;
  final VoidCallback? onTap;

  const FrostCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.radius = 18,
    this.glow = false,
    this.glowColor,
    this.borderColor,
    this.fillColor,
    this.gradient,
    this.onTap,
  });

  @override
  State<FrostCard> createState() => _FrostCardState();
}

class _FrostCardState extends State<FrostCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveBorder = widget.borderColor ?? WinterArcTheme.borderBlack;
    final effectiveFill = widget.fillColor ?? WinterArcTheme.surfaceCard;
    final double offsetVal = _isPressed ? 1.5 : 4.0;

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      margin: widget.margin,
      transform: Matrix4.translationValues(
        _isPressed ? 2.5 : 0.0,
        _isPressed ? 2.5 : 0.0,
        0.0,
      ),
      padding: widget.padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: effectiveFill,
        gradient: widget.gradient,
        borderRadius: BorderRadius.circular(widget.radius),
        border: Border.all(
          color: widget.glow ? (widget.glowColor ?? WinterArcTheme.neoYellow) : effectiveBorder,
          width: 2.2,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.glow ? (widget.glowColor ?? WinterArcTheme.neoYellow) : WinterArcTheme.borderBlack,
            offset: Offset(offsetVal, offsetVal),
            blurRadius: 0,
          ),
        ],
      ),
      child: widget.child,
    );

    if (widget.onTap != null) {
      return GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap!();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: content,
      );
    }

    return content;
  }
}
