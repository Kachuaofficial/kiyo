import 'package:flutter/material.dart';
import '../theme/winter_arc_theme.dart';

class AddHabitSheet extends StatefulWidget {
  final Function({
    required String title,
    required String description,
    required String category,
    required String icon,
  }) onAdd;

  const AddHabitSheet({super.key, required this.onAdd});

  @override
  State<AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends State<AddHabitSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedCategory = 'Discipline';
  String _selectedIcon = '⚡';

  final List<String> _categories = [
    'Discipline',
    'Workout',
    'Nutrition',
    'Mindset',
    'Focus',
  ];

  final List<String> _icons = [
    '⚡', '🏋️', '⏰', '💧', '📖', '📵', '🔥', '🧘', '🏃', '🥗', '🧠', '🛡️'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a habit title'),
          backgroundColor: WinterArcTheme.dangerRed,
        ),
      );
      return;
    }

    widget.onAdd(
      title: title,
      description: _descController.text.trim(),
      category: _selectedCategory,
      icon: _selectedIcon,
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 26,
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
            const SizedBox(height: 20),

            // Sheet Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: WinterArcTheme.neoYellow,
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
                  child: const Text('⚡', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CREATE NEW HABIT',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: WinterArcTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Commit to your Winter Arc discipline',
                      style: TextStyle(
                        fontSize: 12,
                        color: WinterArcTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Title Field
            TextField(
              controller: _titleController,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(
                labelText: 'Habit Title',
                hintText: 'e.g. Read 20 Pages of Book',
                prefixIcon: Icon(Icons.bookmark_add_rounded, color: WinterArcTheme.neoYellow),
              ),
            ),
            const SizedBox(height: 14),

            // Description Field
            TextField(
              controller: _descController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'Description / Goal (Optional)',
                hintText: 'e.g. Daily non-fiction before sleep',
                prefixIcon: Icon(Icons.notes_rounded, color: WinterArcTheme.neoMint),
              ),
            ),
            const SizedBox(height: 18),

            // Category Chips
            const Text(
              'CATEGORY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: WinterArcTheme.neoYellow,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? WinterArcTheme.neoYellow : WinterArcTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: WinterArcTheme.borderBlack, width: 1.8),
                      boxShadow: isSelected
                          ? const [
                              BoxShadow(
                                color: WinterArcTheme.borderBlack,
                                offset: Offset(2, 2),
                                blurRadius: 0,
                              ),
                            ]
                          : [],
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: isSelected ? Colors.black : WinterArcTheme.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // Icon Chips
            const Text(
              'ICON BADGE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: WinterArcTheme.neoYellow,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: _icons.map((ic) {
                final isSelected = _selectedIcon == ic;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = ic),
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: isSelected ? WinterArcTheme.neoMint : WinterArcTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: WinterArcTheme.borderBlack,
                        width: 2.0,
                      ),
                      boxShadow: isSelected
                          ? const [
                              BoxShadow(
                                color: WinterArcTheme.borderBlack,
                                offset: Offset(2, 2),
                                blurRadius: 0,
                              ),
                            ]
                          : [],
                    ),
                    child: Text(ic, style: const TextStyle(fontSize: 20)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 26),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: WinterArcTheme.neoYellow,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: WinterArcTheme.borderBlack, width: 2.2),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_task_rounded, color: Colors.black, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'FORGE HABIT ⚡',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
