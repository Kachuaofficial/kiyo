import 'package:flutter/material.dart';
import '../theme/winter_arc_theme.dart';
import '../models/habit_log.dart';
import '../services/habit_service.dart';

enum HeatmapRange {
  days60(weeks: 9, label: '60 Days'),
  arc90(weeks: 14, label: '90-Day Arc'),
  year(weeks: 52, label: '1 Year');

  final int weeks;
  final String label;
  const HeatmapRange({required this.weeks, required this.label});
}

class GithubHeatmap extends StatefulWidget {
  final HabitService habitService;

  const GithubHeatmap({
    super.key,
    required this.habitService,
  });

  @override
  State<GithubHeatmap> createState() => _GithubHeatmapState();
}

class _GithubHeatmapState extends State<GithubHeatmap> {
  HeatmapRange _selectedRange = HeatmapRange.arc90;
  final ScrollController _scrollController = ScrollController();

  static const List<String> _weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const List<String> _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToLatest();
    });
  }

  @override
  void didUpdateWidget(covariant GithubHeatmap oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToLatest();
    });
  }

  void _scrollToLatest() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Color _getCellColor(int count, int total, double ratio, bool isToday, bool isFuture) {
    if (isFuture) {
      return Colors.transparent;
    }
    if (count == 0 || total == 0) {
      return const Color(0xFF181C26);
    }
    if (ratio >= 1.0) {
      return WinterArcTheme.neoYellow; // 100% Perfect Arc Day
    }
    if (ratio >= 0.75) {
      return WinterArcTheme.neoMint; // Radiant mint
    }
    if (ratio >= 0.50) {
      return const Color(0xFF2FA87E); // Vibrant green
    }
    if (ratio >= 0.25) {
      return const Color(0xFF1E6B50); // Medium emerald
    }
    return const Color(0xFF144735); // Subtle dark mint
  }

  void _showDayDetailsDialog(DateTime date, String dateKey) {
    final habits = widget.habitService.habits;
    final total = habits.length;
    final completedCount = widget.habitService.completedCountForDate(dateKey);
    final ratio = widget.habitService.completionRatioForDate(dateKey);
    final isToday = dateKey == HabitLog.dateKey(DateTime.now());

    final formattedDate =
        '${_monthNames[date.month - 1]} ${date.day}, ${date.year}';

    String statusBadge;
    Color badgeColor;
    if (completedCount == 0) {
      statusBadge = 'REST / MISSED ❄️';
      badgeColor = WinterArcTheme.textMuted;
    } else if (ratio >= 1.0) {
      statusBadge = 'PERFECT ARC DAY 🌟';
      badgeColor = WinterArcTheme.neoYellow;
    } else if (ratio >= 0.5) {
      statusBadge = 'STRONG PROGRESS 🔥';
      badgeColor = WinterArcTheme.neoMint;
    } else {
      statusBadge = 'PARTIAL FOCUS ⚡';
      badgeColor = WinterArcTheme.neoCoral;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: WinterArcTheme.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: WinterArcTheme.borderBlack, width: 2.4),
        ),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: WinterArcTheme.borderBlack, width: 1.5),
                  ),
                  child: Text(
                    statusBadge,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'TODAY',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              formattedDate,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: WinterArcTheme.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              total > 0
                  ? '$completedCount of $total habits crushed (${(ratio * 100).toInt()}%)'
                  : 'No habits configured for this date',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: WinterArcTheme.textSecondary,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(color: Colors.white12, height: 20),
              if (habits.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'No habits created yet.',
                      style: TextStyle(fontSize: 13, color: WinterArcTheme.textMuted),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: habits.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final habit = habits[index];
                      final isDone = widget.habitService.isHabitCompleted(habit.id, dateKey);
                      final log = widget.habitService.getHabitLog(habit.id, dateKey);
                      final hasNote = log != null && log.note.isNotEmpty;

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDone ? const Color(0xFF1E2430) : WinterArcTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDone ? WinterArcTheme.neoMint : WinterArcTheme.borderBlack,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(habit.icon, style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    habit.title,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: isDone ? Colors.white : WinterArcTheme.textMuted,
                                      decoration: isDone ? null : TextDecoration.lineThrough,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDone ? WinterArcTheme.neoMint : Colors.white10,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isDone ? 'DONE' : 'MISSED',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: isDone ? Colors.black : Colors.white60,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (hasNote) ...[
                              const SizedBox(height: 6),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.black26,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: Text(
                                  '📝 ${log.note}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: WinterArcTheme.neoYellow,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => Navigator.of(ctx).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: WinterArcTheme.neoYellow,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: WinterArcTheme.borderBlack, width: 1.8),
                      boxShadow: const [
                        BoxShadow(
                          color: WinterArcTheme.borderBlack,
                          offset: Offset(2, 2),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: const Text(
                      'CLOSE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final numWeeks = _selectedRange.weeks;

    // Calculate start date aligned to Monday of the starting week
    // We want the current week to be the last week (column)
    final daysSinceMonday = (today.weekday - 1);
    final currentWeekMonday = today.subtract(Duration(days: daysSinceMonday));
    final startMonday = currentWeekMonday.subtract(Duration(days: (numWeeks - 1) * 7));

    // Generate week columns: each has 7 days (Monday=0 to Sunday=6)
    final List<List<DateTime>> weekColumns = [];
    for (int w = 0; w < numWeeks; w++) {
      final weekStart = startMonday.add(Duration(days: w * 7));
      final List<DateTime> weekDays = [];
      for (int d = 0; d < 7; d++) {
        weekDays.add(weekStart.add(Duration(days: d)));
      }
      weekColumns.add(weekDays);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Adapt cell size based on screen width
        final double cellSize = constraints.maxWidth > 600 ? 16.0 : 13.5;
        final double cellGap = constraints.maxWidth > 600 ? 4.0 : 3.0;

        return Container(
          decoration: BoxDecoration(
            color: WinterArcTheme.surfaceCard,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: WinterArcTheme.borderBlack, width: 2.2),
            boxShadow: const [
              BoxShadow(
                color: WinterArcTheme.borderBlack,
                offset: Offset(4, 4),
                blurRadius: 0,
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Heatmap Header with Range Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: WinterArcTheme.neoMint,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: WinterArcTheme.borderBlack, width: 1.8),
                        ),
                        child: const Text('🟩', style: TextStyle(fontSize: 16)),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ACTIVITY HEATMAP',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                              color: WinterArcTheme.textPrimary,
                            ),
                          ),
                          Text(
                            'GitHub-style consistency graph',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: WinterArcTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Filter Range Chips (60 Days / 90-Day Arc / 1 Year)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: HeatmapRange.values.map((range) {
                    final isSelected = _selectedRange == range;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedRange = range);
                        _scrollToLatest();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? WinterArcTheme.neoYellow : WinterArcTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: WinterArcTheme.borderBlack, width: 1.8),
                          boxShadow: isSelected
                              ? const [
                                  BoxShadow(
                                    color: WinterArcTheme.borderBlack,
                                    offset: Offset(2, 2),
                                    blurRadius: 0,
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          range.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? Colors.black : WinterArcTheme.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Main Heatmap Grid with Weekday Column & Scrollable Weeks
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Weekday Labels on Left (M, W, F)
                  Padding(
                    padding: const EdgeInsets.only(top: 20, right: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (i) {
                        final showLabel = (i == 0 || i == 2 || i == 4); // Mon, Wed, Fri
                        return Container(
                          height: cellSize,
                          margin: EdgeInsets.only(bottom: cellGap),
                          alignment: Alignment.centerRight,
                          child: Text(
                            showLabel ? _weekdays[i] : '',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: WinterArcTheme.textMuted,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  // Horizontal Scrollable Grid of Week Columns
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Month Labels Row
                          SizedBox(
                            height: 18,
                            child: Row(
                              children: List.generate(weekColumns.length, (wIdx) {
                                final firstDayOfWeek = weekColumns[wIdx][0];
                                // Show month label if 1st day of month falls in this week
                                bool isFirstWeekOfMonth = false;
                                for (var d in weekColumns[wIdx]) {
                                  if (d.day == 1) {
                                    isFirstWeekOfMonth = true;
                                    break;
                                  }
                                }
                                if (wIdx == 0) isFirstWeekOfMonth = true;

                                return Container(
                                  width: cellSize + cellGap,
                                  alignment: Alignment.centerLeft,
                                  child: isFirstWeekOfMonth
                                      ? Text(
                                          _monthNames[firstDayOfWeek.month - 1],
                                          style: const TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            color: WinterArcTheme.textMuted,
                                          ),
                                        )
                                      : null,
                                );
                              }),
                            ),
                          ),
                          const SizedBox(height: 2),

                          // 7 Days Grid Rows
                          Row(
                            children: weekColumns.map((weekDays) {
                              return Container(
                                margin: EdgeInsets.only(right: cellGap),
                                child: Column(
                                  children: weekDays.map((date) {
                                    final dateKey = HabitLog.dateKey(date);
                                    final isToday = dateKey == HabitLog.dateKey(today);
                                    final isFuture = date.isAfter(today);

                                    final habits = widget.habitService.habits;
                                    final total = habits.length;
                                    final completed =
                                        widget.habitService.completedCountForDate(dateKey);
                                    final ratio =
                                        widget.habitService.completionRatioForDate(dateKey);

                                    final cellColor = _getCellColor(
                                      completed,
                                      total,
                                      ratio,
                                      isToday,
                                      isFuture,
                                    );

                                    return GestureDetector(
                                      onTap: isFuture
                                          ? null
                                          : () => _showDayDetailsDialog(date, dateKey),
                                      child: Container(
                                        width: cellSize,
                                        height: cellSize,
                                        margin: EdgeInsets.only(bottom: cellGap),
                                        decoration: BoxDecoration(
                                          color: cellColor,
                                          borderRadius: BorderRadius.circular(3.5),
                                          border: Border.all(
                                            color: isToday
                                                ? WinterArcTheme.neoYellow
                                                : isFuture
                                                    ? Colors.transparent
                                                    : WinterArcTheme.borderBlack.withOpacity(0.6),
                                            width: isToday ? 1.6 : 0.8,
                                          ),
                                          boxShadow: (completed > 0 && !isFuture)
                                              ? [
                                                  BoxShadow(
                                                    color: WinterArcTheme.borderBlack,
                                                    offset: const Offset(1, 1),
                                                    blurRadius: 0,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Bottom Legend Row: Less [■][■][■][■][■] More
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tap any cell for day breakdown',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: WinterArcTheme.textMuted,
                    ),
                  ),
                  Row(
                    children: [
                      const Text(
                        'Less',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: WinterArcTheme.textMuted,
                        ),
                      ),
                      const SizedBox(width: 5),
                      ...[
                        const Color(0xFF181C26),
                        const Color(0xFF144735),
                        const Color(0xFF1E6B50),
                        const Color(0xFF2FA87E),
                        WinterArcTheme.neoMint,
                        WinterArcTheme.neoYellow,
                      ].map((color) => Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2.5),
                              border: Border.all(
                                color: WinterArcTheme.borderBlack,
                                width: 0.8,
                              ),
                            ),
                          )),
                      const SizedBox(width: 5),
                      const Text(
                        'More',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: WinterArcTheme.textMuted,
                        ),
                      ),
                    ],
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
