import 'package:flutter/material.dart';
import '../theme/winter_arc_theme.dart';

class ArcDateRangeDialog extends StatefulWidget {
  final DateTime currentStart;
  final DateTime currentEnd;
  final Function(DateTime start, DateTime end) onSave;

  const ArcDateRangeDialog({
    super.key,
    required this.currentStart,
    required this.currentEnd,
    required this.onSave,
  });

  @override
  State<ArcDateRangeDialog> createState() => _ArcDateRangeDialogState();
}

class _ArcDateRangeDialogState extends State<ArcDateRangeDialog> {
  late DateTime _start;
  late DateTime _end;

  @override
  void initState() {
    super.initState();
    _start = widget.currentStart;
    _end = widget.currentEnd;
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: WinterArcTheme.neoYellow,
              onPrimary: Colors.black,
              surface: WinterArcTheme.surfaceElevated,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _start = picked;
        if (_end.isBefore(_start)) {
          _end = _start.add(const Duration(days: 90));
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _end.isAfter(_start) ? _end : _start.add(const Duration(days: 90)),
      firstDate: _start,
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: WinterArcTheme.neoMint,
              onPrimary: Colors.black,
              surface: WinterArcTheme.surfaceElevated,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _end = picked);
    }
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final totalDays = _end.difference(_start).inDays;
    final now = DateTime.now();
    final currentDay = now.isBefore(_start) ? 1 : now.difference(_start).inDays + 1;
    final remainingDays = _end.difference(now).inDays;

    return Dialog(
      backgroundColor: WinterArcTheme.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: WinterArcTheme.borderBlack, width: 2.4),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: WinterArcTheme.neoYellow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: WinterArcTheme.borderBlack, width: 1.8),
                    boxShadow: const [
                      BoxShadow(
                        color: WinterArcTheme.borderBlack,
                        offset: Offset(2, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: const Text('🗓️', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'CUSTOM WINTER ARC DATES',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Text(
                        'Define your start and final day',
                        style: TextStyle(fontSize: 12, color: WinterArcTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Start Date Picker Button
            const Text(
              'START DAY',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: WinterArcTheme.neoYellow, letterSpacing: 0.8),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _pickStartDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: WinterArcTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: WinterArcTheme.borderBlack, width: 2.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDate(_start), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.white)),
                    const Icon(Icons.calendar_today_rounded, size: 18, color: WinterArcTheme.neoYellow),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // End Date Picker Button
            const Text(
              'FINAL DAY (TARGET)',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: WinterArcTheme.neoMint, letterSpacing: 0.8),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _pickEndDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: WinterArcTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: WinterArcTheme.borderBlack, width: 2.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDate(_end), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.white)),
                    const Icon(Icons.flag_rounded, size: 18, color: WinterArcTheme.neoMint),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Timeline Calculation Summary
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: WinterArcTheme.surfaceCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: WinterArcTheme.borderBlack, width: 1.8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Challenge:', style: TextStyle(fontSize: 12, color: WinterArcTheme.textSecondary)),
                      Text('$totalDays Days', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Current Progress:', style: TextStyle(fontSize: 12, color: WinterArcTheme.textSecondary)),
                      Text('Day $currentDay of $totalDays', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: WinterArcTheme.neoYellow)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Days Remaining:', style: TextStyle(fontSize: 12, color: WinterArcTheme.textSecondary)),
                      Text('${remainingDays < 0 ? 0 : remainingDays} Days', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: WinterArcTheme.neoMint)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: WinterArcTheme.borderBlack, width: 1.8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('CANCEL', style: TextStyle(color: WinterArcTheme.textSecondary, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onSave(_start, _end);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WinterArcTheme.neoYellow,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: WinterArcTheme.borderBlack, width: 2.0),
                      ),
                    ),
                    child: const Text('SAVE TIMELINE', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  }
}
