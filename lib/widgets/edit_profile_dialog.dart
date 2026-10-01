import 'package:flutter/material.dart';
import '../theme/winter_arc_theme.dart';

class EditProfileDialog extends StatefulWidget {
  final String currentName;
  final int currentAge;
  final Function(String name, int age) onSave;

  const EditProfileDialog({
    super.key,
    required this.currentName,
    required this.currentAge,
    required this.onSave,
  });

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _ageController = TextEditingController(text: widget.currentAge.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    final age = int.tryParse(_ageController.text.trim()) ?? widget.currentAge;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name cannot be empty'),
          backgroundColor: WinterArcTheme.dangerRed,
        ),
      );
      return;
    }

    widget.onSave(name, age);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: WinterArcTheme.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: WinterArcTheme.borderBlack, width: 2.4),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                      border: Border.all(color: WinterArcTheme.borderBlack, width: 2.0),
                      boxShadow: const [
                        BoxShadow(
                          color: WinterArcTheme.borderBlack,
                          offset: Offset(2.5, 2.5),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: const Text('👤', style: TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'USER PROFILE',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              color: WinterArcTheme.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          'Update your identity & age',
                          style: TextStyle(fontSize: 12, color: WinterArcTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 22),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person_rounded, color: WinterArcTheme.neoYellow),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(
                labelText: 'Age',
                prefixIcon: Icon(Icons.cake_rounded, color: WinterArcTheme.neoMint),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: WinterArcTheme.borderBlack, width: 2.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      'CANCEL',
                      style: TextStyle(color: WinterArcTheme.textSecondary, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: WinterArcTheme.neoYellow,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: WinterArcTheme.borderBlack, width: 2.0),
                      ),
                    ),
                    child: const Text(
                      'SAVE',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    ),
  );
  }
}
