import 'package:flutter/material.dart';
import '../theme/winter_arc_theme.dart';
import '../models/habit.dart';

class LogReflectionSheet extends StatefulWidget {
  final Habit habit;
  final String date;
  final String existingNote;
  final Function(String note) onConfirm;

  const LogReflectionSheet({
    super.key,
    required this.habit,
    required this.date,
    this.existingNote = '',
    required this.onConfirm,
  });

  @override
  State<LogReflectionSheet> createState() => _LogReflectionSheetState();
}

class _LogReflectionSheetState extends State<LogReflectionSheet> {
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.existingNote);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _getPromptText() {
    final cat = widget.habit.category.toLowerCase();
    final title = widget.habit.title.toLowerCase();

    if (cat.contains('workout') || title.contains('gym') || title.contains('run') || title.contains('pushup')) {
      return 'What exercises, sets, weights, or distance did you crush?';
    }
    if (cat.contains('mindset') || title.contains('read') || title.contains('book')) {
      return 'What chapters, pages, or concepts did you absorb?';
    }
    if (cat.contains('nutrition') || title.contains('water') || title.contains('sugar')) {
      return 'What did you fuel your body with today?';
    }
    if (cat.contains('focus') || title.contains('screen') || title.contains('work')) {
      return 'What deep work or milestone did you accomplish?';
    }
    return 'What did you achieve for this protocol today?';
  }

  String _getPlaceholderText() {
    final cat = widget.habit.category.toLowerCase();
    final title = widget.habit.title.toLowerCase();

    if (cat.contains('workout') || title.contains('gym') || title.contains('squat')) {
      return 'e.g. Squats 4x10 @ 100kg, 50 pushups, 20 pullups...';
    }
    if (cat.contains('mindset') || title.contains('read') || title.contains('book')) {
      return 'e.g. Read chapters 3 & 4: Focus on internal locus of control...';
    }
    if (cat.contains('nutrition') || title.contains('water')) {
      return 'e.g. Hit 3.5L cold water, zero processed sugar, clean diet...';
    }
    return 'e.g. Executed without hesitation. 100% consistency...';
  }

  List<String> _getQuickChips() {
    final cat = widget.habit.category.toLowerCase();
    if (cat.contains('workout')) {
      return ['🔥 High Intensity', '🦾 Hit New PR', '🦵 Leg Day', '🏃 Cardio Done'];
    }
    if (cat.contains('mindset') || cat.contains('read')) {
      return ['📖 10 Pages', '🧠 Key Insights', '✍️ Took Notes', '⚡ Deep Focus'];
    }
    if (cat.contains('nutrition')) {
      return ['💧 3.5L Water', '🥗 Clean Meals', '🚫 Zero Sugar', '🥩 High Protein'];
    }
    return ['⚡ 100% Done', '🔥 Felt Great', '🛡️ Zero Excuses', '❄️ Conquered Cold'];
  }

  void _appendChip(String text) {
    final current = _noteController.text.trim();
    if (current.isEmpty) {
      _noteController.text = text;
    } else {
      _noteController.text = '$current • $text';
    }
  }

  void _submit([bool isQuick = false]) {
    final note = isQuick ? '' : _noteController.text.trim();
    widget.onConfirm(note);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: WinterArcTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: WinterArcTheme.borderBlack, width: 2.4),
        boxShadow: const [
          BoxShadow(
            color: WinterArcTheme.borderBlack,
            offset: Offset(0, -4),
            blurRadius: 0,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Header Row
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: WinterArcTheme.neoMint,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: WinterArcTheme.borderBlack, width: 2.0),
                    boxShadow: const [
                      BoxShadow(
                        color: WinterArcTheme.borderBlack,
                        offset: Offset(2.5, 2.5),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(widget.habit.icon, style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.habit.title.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: WinterArcTheme.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'LOG PROTOCOL DETAILS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: WinterArcTheme.neoMint,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Context Prompt
            Text(
              _getPromptText(),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: WinterArcTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 10),

            // Quick Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _getQuickChips().map((chip) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => _appendChip(chip),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: WinterArcTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: WinterArcTheme.borderBlack, width: 1.6),
                        ),
                        child: Text(
                          chip,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: WinterArcTheme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Context Input Field
            TextField(
              controller: _noteController,
              autofocus: true,
              maxLines: 4,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
              decoration: InputDecoration(
                hintText: _getPlaceholderText(),
                hintStyle: const TextStyle(color: WinterArcTheme.textMuted, fontSize: 13),
              ),
            ),
            const SizedBox(height: 22),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _submit(true),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: WinterArcTheme.borderBlack, width: 2.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'QUICK CHECK',
                        style: TextStyle(
                          color: WinterArcTheme.textSecondary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => _submit(false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WinterArcTheme.neoMint,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: WinterArcTheme.borderBlack, width: 2.2),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 20, color: Colors.black),
                        SizedBox(width: 8),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'LOG COMPLETION',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
