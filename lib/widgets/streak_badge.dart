import 'package:flutter/material.dart';
import '../theme/winter_arc_theme.dart';

class StreakBadge extends StatelessWidget {
  final int streakDays;
  final String label;
  final bool isFire;

  const StreakBadge({
    super.key,
    required this.streakDays,
    this.label = 'STREAK',
    this.isFire = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isFire ? WinterArcTheme.neoOrange : WinterArcTheme.neoYellow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: WinterArcTheme.borderBlack,
          width: 2.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: WinterArcTheme.borderBlack,
            offset: Offset(2.5, 2.5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            '$streakDays ${streakDays == 1 ? 'DAY' : 'DAYS'}',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
              color: Colors.black,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
