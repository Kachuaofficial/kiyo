import 'package:flutter/material.dart';
import '../theme/winter_arc_theme.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../services/habit_service.dart';

class HabitGraphMatrix extends StatelessWidget {
  final List<Habit> habits;
  final HabitService habitService;

  const HabitGraphMatrix({
    super.key,
    required this.habits,
    required this.habitService,
  });

  List<DateTime> _getLast7Days() {
    final now = DateTime.now();
    return List.generate(7, (i) {
      return now.subtract(Duration(days: 6 - i));
    });
  }

  void _showNoteDialog(BuildContext context, Habit habit, HabitLog log, DateTime date) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: WinterArcTheme.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: WinterArcTheme.borderBlack, width: 2.2),
        ),
        title: Row(
          children: [
            Text(habit.icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                habit.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: WinterArcTheme.neoYellow,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: WinterArcTheme.borderBlack, width: 1.5),
                ),
                child: Text(
                  'LOGGED ON: ${log.date}',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                log.note.isNotEmpty ? log.note : 'Completed with quick check (no note attached).',
                style: const TextStyle(fontSize: 14, color: WinterArcTheme.textPrimary, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(backgroundColor: WinterArcTheme.neoMint),
            child: const Text('CLOSE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (habits.isEmpty) {
      return const SizedBox.shrink();
    }

    final days = _getLast7Days();
    final weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: WinterArcTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: WinterArcTheme.borderBlack, width: 2.2),
        boxShadow: const [
          BoxShadow(
            color: WinterArcTheme.borderBlack,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '7-DAY HABIT MATRIX',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: WinterArcTheme.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: WinterArcTheme.neoMint,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: WinterArcTheme.borderBlack, width: 1.4),
                ),
                child: const Text(
                  'INTERACTIVE',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.black),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap any completed cell to view logged notes and exercise reps.',
            style: TextStyle(fontSize: 11, color: WinterArcTheme.textSecondary),
          ),
          const SizedBox(height: 16),

          // Days Header Row
          Row(
            children: [
              const SizedBox(width: 90), // Spacing for habit names column
              ...days.map((d) {
                final isToday = d.day == DateTime.now().day && d.month == DateTime.now().month;
                return Expanded(
                  child: Column(
                    children: [
                      Text(
                        weekdays[d.weekday - 1],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: isToday ? WinterArcTheme.neoYellow : WinterArcTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${d.day}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isToday ? Colors.white : WinterArcTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 12),

          if (habits.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No habits tracked yet.\nAdd your first habit to view the 7-day matrix!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: WinterArcTheme.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            // Habits Rows Matrix
            ...habits.map((habit) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  // Habit Label
                  SizedBox(
                    width: 90,
                    child: Row(
                      children: [
                        Text(habit.icon, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            habit.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: WinterArcTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 7 Days Matrix Cells
                  ...days.map((d) {
                    final dateKey = HabitLog.dateKey(d);
                    final isDone = habitService.isHabitCompleted(habit.id, dateKey);
                    final log = habitService.getHabitLog(habit.id, dateKey);
                    final hasNote = log?.note.isNotEmpty ?? false;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (isDone && log != null) {
                            _showNoteDialog(context, habit, log, d);
                          }
                        },
                        child: Container(
                          height: 32,
                          margin: const EdgeInsets.symmetric(horizontal: 2.5),
                          decoration: BoxDecoration(
                            color: isDone ? WinterArcTheme.neoMint : WinterArcTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDone ? WinterArcTheme.borderBlack : Colors.white.withOpacity(0.08),
                              width: isDone ? 1.8 : 1.0,
                            ),
                            boxShadow: isDone
                                ? const [
                                    BoxShadow(
                                      color: WinterArcTheme.borderBlack,
                                      offset: Offset(1.5, 1.5),
                                      blurRadius: 0,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: isDone
                                ? Icon(
                                    hasNote ? Icons.sticky_note_2_rounded : Icons.check_rounded,
                                    size: 14,
                                    color: Colors.black,
                                  )
                                : null,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
