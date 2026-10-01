import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/winter_arc_theme.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../services/habit_service.dart';
import '../services/appwrite_service.dart';
import '../services/quotes_service.dart';
import '../widgets/frost_card.dart';
import '../widgets/animated_check_button.dart';
import '../widgets/progress_ring.dart';
import '../widgets/streak_badge.dart';
import '../widgets/add_habit_sheet.dart';
import '../widgets/edit_profile_dialog.dart';
import '../widgets/log_reflection_sheet.dart';
import '../widgets/habit_graph_matrix.dart';
import '../widgets/github_heatmap.dart';
import '../widgets/arc_date_range_dialog.dart';
import 'auth_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final HabitService _habitService = HabitService();
  final AppwriteService _appwrite = AppwriteService();

  int _currentTabIndex = 0; // 0: Habits, 1: Streaks & Analytics, 2: Profile
  String _selectedCategory = 'All';
  String _selectedQuoteCategory = 'All';

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  int _dailyQuoteIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    _habitService.addListener(_onHabitServiceChanged);
    _dailyQuoteIndex = DateTime.now().day % QuotesService.quotes.length;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _habitService.flushPendingWrites();
    _habitService.removeListener(_onHabitServiceChanged);
    _fadeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _habitService.flushPendingWrites();
    }
  }

  void _onHabitServiceChanged() {
    if (mounted) setState(() {});
  }

  void _openAddHabit() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddHabitSheet(
        onAdd: ({
          required String title,
          required String description,
          required String category,
          required String icon,
        }) {
          _habitService.addHabit(
            title: title,
            description: description,
            category: category,
            icon: icon,
          );
        },
      ),
    );
  }

  void _openEditProfile() {
    final profile = _habitService.currentProfile;
    if (profile == null) return;

    showDialog(
      context: context,
      builder: (_) => EditProfileDialog(
        currentName: profile.name,
        currentAge: profile.age,
        onSave: (name, age) {
          _habitService.updateProfile(name: name, age: age);
        },
      ),
    );
  }

  void _openArcDateRangeDialog() {
    final profile = _habitService.currentProfile;
    if (profile == null) return;

    showDialog(
      context: context,
      builder: (_) => ArcDateRangeDialog(
        currentStart: profile.arcStartDate,
        currentEnd: profile.arcEndDate,
        onSave: (start, end) {
          _habitService.updateArcTimeline(start: start, end: end);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: WinterArcTheme.neoYellow,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: WinterArcTheme.borderBlack, width: 2.0),
              ),
              content: const Text(
                'Winter Arc timeline updated! 🗓️',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleHabitTap(Habit habit, bool isDone) {
    if (isDone) {
      // Toggle back to incomplete
      _habitService.toggleHabitCompletion(habit.id);
    } else {
      // Open Context Bottom Sheet to add reflection / exercise notes!
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => LogReflectionSheet(
          habit: habit,
          date: _habitService.selectedDate,
          existingNote: _habitService.getHabitLog(habit.id)?.note ?? '',
          onConfirm: (note) {
            _habitService.toggleHabitCompletion(habit.id, note: note);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: WinterArcTheme.neoMint,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: WinterArcTheme.borderBlack, width: 2.0),
                ),
                content: Text(
                  '${habit.title} protocol completed! ⚡',
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
                ),
              ),
            );
          },
        ),
      );
    }
  }

  void _copyQuoteToClipboard(String text, String author) {
    Clipboard.setData(ClipboardData(text: '"$text" — $author'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: WinterArcTheme.neoYellow,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: WinterArcTheme.borderBlack, width: 2.0),
        ),
        content: const Row(
          children: [
            Icon(Icons.copy_rounded, color: Colors.black, size: 18),
            SizedBox(width: 8),
            Text(
              'Quote copied to clipboard! 📋',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: WinterArcTheme.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: WinterArcTheme.borderBlack, width: 2.2),
        ),
        title: const Text('Log Out?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        content: const Text(
          'Are you sure you want to exit your habit tracking session?',
          style: TextStyle(color: WinterArcTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('CANCEL', style: TextStyle(color: WinterArcTheme.textMuted, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: WinterArcTheme.dangerRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: WinterArcTheme.borderBlack, width: 2.0),
              ),
            ),
            child: const Text('LOG OUT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _appwrite.logout();
      _habitService.clear();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }

  String _formatDisplayDate() {
    final now = DateTime.now();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekday = weekdays[now.weekday - 1];
    final month = months[now.month - 1];
    return '$weekday, $month ${now.day}';
  }

  String _formatDateShort(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final profile = _habitService.currentProfile;

    return Scaffold(
      backgroundColor: WinterArcTheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: WinterArcTheme.surfaceCard,
                shape: BoxShape.circle,
                border: Border.all(color: WinterArcTheme.borderBlack, width: 1.8),
                boxShadow: const [
                  BoxShadow(
                    color: WinterArcTheme.borderBlack,
                    offset: Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset('assets/logo.png', fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'KIYO',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          if (profile != null)
            GestureDetector(
              onTap: _openEditProfile,
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: WinterArcTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: WinterArcTheme.borderBlack, width: 1.8),
                  boxShadow: const [
                    BoxShadow(
                      color: WinterArcTheme.borderBlack,
                      offset: Offset(2, 2),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 100),
                      child: Text(
                        '${profile.name}, ${profile.age}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: WinterArcTheme.neoYellow,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.edit_outlined, size: 13, color: WinterArcTheme.textMuted),
                  ],
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: WinterArcTheme.textMuted, size: 20),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: IndexedStack(
          index: _currentTabIndex,
          children: [
            _buildHabitsTab(),
            _buildHeatmapTab(),
            _buildAnalyticsTab(),
            _buildQuotesTab(),
            _buildProfileTab(),
          ],
        ),
      ),
      bottomNavigationBar: _buildSoftNeubrutalistNavBar(),
      floatingActionButton: _currentTabIndex == 0
          ? Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton.icon(
                onPressed: _openAddHabit,
                icon: const Icon(Icons.add_rounded, size: 22, color: Colors.black),
                label: const Text(
                  'NEW HABIT',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: Colors.black,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: WinterArcTheme.neoYellow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: WinterArcTheme.borderBlack, width: 2.2),
                  ),
                  elevation: 0,
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // ==========================================
  // TAB 1: HABITS TRACKER
  // ==========================================
  Widget _buildHabitsTab() {
    final profile = _habitService.currentProfile;
    final habits = _habitService.habits;
    final filteredHabits = _selectedCategory == 'All'
        ? habits
        : habits.where((h) => h.category == _selectedCategory).toList();

    final completedCount = _habitService.completedCountForDate();
    final totalCount = habits.length;
    final ratio = _habitService.completionRatioForDate();
    final dailyQuote = QuotesService.quotes[_dailyQuoteIndex];

    return RefreshIndicator(
      color: WinterArcTheme.neoYellow,
      backgroundColor: WinterArcTheme.surfaceElevated,
      onRefresh: () async {
        if (profile != null) {
          await _habitService.loadUserData(
            userId: profile.userId,
            email: profile.email,
            forceRefresh: true,
          );
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date & Streak Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDisplayDate().toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: WinterArcTheme.neoMint,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile != null
                          ? 'DAY ${profile.currentArcDay} OF ${profile.totalArcDays}'
                          : 'DAY 1 OF 90',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: WinterArcTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                if (profile != null)
                  StreakBadge(
                    streakDays: profile.currentStreak,
                    isFire: profile.currentStreak >= 3,
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Hero Daily Progress Card
            FrostCard(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  ProgressRing(
                    progress: ratio,
                    size: 96,
                    strokeWidth: 9,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: WinterArcTheme.neoYellow,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: WinterArcTheme.borderBlack, width: 1.6),
                          ),
                          child: Text(
                            profile?.rankTitle ?? 'Arc Initiate 🐺',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          totalCount == 0
                              ? 'NO HABITS CREATED YET'
                              : (ratio == 1.0
                                  ? 'ALL PROTOCOLS CRUSHED! 🔥'
                                  : '$completedCount of $totalCount Completed'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: WinterArcTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          totalCount == 0
                              ? 'Tap "+ New Habit" to begin your challenge.'
                              : (ratio == 1.0
                                  ? 'Iron discipline forged today.'
                                  : '${totalCount - completedCount} habits remaining today.'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: WinterArcTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Motivational Quote Banner (Feature: Shows motivation quotes to all users)
            GestureDetector(
              onTap: () {
                setState(() {
                  _dailyQuoteIndex = (_dailyQuoteIndex + 1) % QuotesService.quotes.length;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: WinterArcTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: WinterArcTheme.borderBlack, width: 2.0),
                  boxShadow: const [
                    BoxShadow(
                      color: WinterArcTheme.borderBlack,
                      offset: Offset(3, 3),
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: WinterArcTheme.neoYellow,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: WinterArcTheme.borderBlack, width: 1.4),
                          ),
                          child: Text(
                            dailyQuote.tag,
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.black),
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, size: 16, color: WinterArcTheme.textSecondary),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Copy Quote',
                              onPressed: () => _copyQuoteToClipboard(dailyQuote.text, dailyQuote.author),
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.refresh_rounded, size: 16, color: WinterArcTheme.neoYellow),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '“${dailyQuote.text}”',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                        color: WinterArcTheme.textPrimary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '— ${dailyQuote.author}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: WinterArcTheme.neoYellow,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Category Filter Pills
            if (habits.isNotEmpty) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    'All',
                    'Discipline',
                    'Workout',
                    'Nutrition',
                    'Mindset',
                    'Focus'
                  ].map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? WinterArcTheme.neoYellow : WinterArcTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: WinterArcTheme.borderBlack, width: 2.0),
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
                              color: isSelected ? Colors.black : WinterArcTheme.textSecondary,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Habits List
            if (_habitService.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: WinterArcTheme.neoYellow),
                ),
              )
            else if (habits.isEmpty)
              _buildEmptyHabitsView()
            else if (filteredHabits.isEmpty)
              _buildNoHabitsInCategoryView()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredHabits.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final habit = filteredHabits[index];
                  final isDone = _habitService.isHabitCompleted(habit.id);
                  final log = _habitService.getHabitLog(habit.id);
                  return _buildHabitCard(habit, isDone, log);
                },
              ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyHabitsView() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: WinterArcTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: WinterArcTheme.borderBlack, width: 2.2),
        boxShadow: const [
          BoxShadow(
            color: WinterArcTheme.borderBlack,
            offset: Offset(3.5, 3.5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: WinterArcTheme.surfaceCard,
              shape: BoxShape.circle,
              border: Border.all(color: WinterArcTheme.borderBlack, width: 2.2),
              boxShadow: const [
                BoxShadow(
                  color: WinterArcTheme.borderBlack,
                  offset: Offset(3.5, 3.5),
                  blurRadius: 0,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset('assets/logo.png', fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'NO HABITS CREATED YET',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: WinterArcTheme.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your Winter Arc protocol is ready. Tap the button below to forge your first habit!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: WinterArcTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _openAddHabit,
            icon: const Icon(Icons.add_rounded, size: 20, color: Colors.black),
            label: const Text('ADD FIRST HABIT', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
            style: ElevatedButton.styleFrom(
              backgroundColor: WinterArcTheme.neoYellow,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: WinterArcTheme.borderBlack, width: 2.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoHabitsInCategoryView() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: WinterArcTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: WinterArcTheme.borderBlack, width: 2.0),
      ),
      child: Center(
        child: Text(
          'No habits found under "$_selectedCategory".',
          style: const TextStyle(
            color: WinterArcTheme.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildHabitCard(Habit habit, bool isDone, HabitLog? log) {
    final hasNote = log != null && log.note.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: isDone ? WinterArcTheme.surfaceElevated : WinterArcTheme.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDone ? WinterArcTheme.neoMint : WinterArcTheme.borderBlack,
          width: 2.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: WinterArcTheme.borderBlack,
            offset: Offset(3.5, 3.5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon Container
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDone ? WinterArcTheme.neoMint : WinterArcTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: WinterArcTheme.borderBlack, width: 2.0),
                  ),
                  child: Center(
                    child: Text(habit.icon, style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 14),

                // Title & Description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(habit.category),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: WinterArcTheme.borderBlack, width: 1.4),
                        ),
                        child: Text(
                          habit.category.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        habit.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: isDone ? WinterArcTheme.textSecondary : WinterArcTheme.textPrimary,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                          decorationColor: WinterArcTheme.neoMint,
                        ),
                      ),
                      if (habit.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          habit.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: WinterArcTheme.textMuted,
                            decoration: isDone ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Animated Check Button (Triggers log reflection sheet if not done!)
                AnimatedCheckButton(
                  isChecked: isDone,
                  onTap: () => _handleHabitTap(habit, isDone),
                ),

                // Delete option
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20, color: WinterArcTheme.textMuted),
                  color: WinterArcTheme.surfaceElevated,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: WinterArcTheme.borderBlack, width: 2.0),
                  ),
                  onSelected: (val) {
                    if (val == 'delete') {
                      _habitService.deleteHabit(habit.id);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 18, color: WinterArcTheme.dangerRed),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: WinterArcTheme.dangerRed, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // If note was logged, display in a neat soft neubrutalist tag!
            if (isDone && hasNote) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: WinterArcTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: WinterArcTheme.borderBlack, width: 1.5),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📝', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        log.note,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: WinterArcTheme.neoMint,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 2: GITHUB HEATMAP & CONSISTENCY LEDGER
  // ==========================================
  Widget _buildHeatmapTab() {
    final activeDays = _habitService.totalActiveDays;
    final longestStreak = _habitService.longestStreak;
    final totalCompletions = _habitService.totalCompletions;
    final habits = _habitService.habits;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'ACTIVITY HEATMAP',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: WinterArcTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'GitHub-style consistency graph',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: WinterArcTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: WinterArcTheme.neoMint,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: WinterArcTheme.borderBlack, width: 1.8),
                  boxShadow: const [
                    BoxShadow(color: WinterArcTheme.borderBlack, offset: Offset(2, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bolt_rounded, size: 16, color: Colors.black),
                    const SizedBox(width: 4),
                    Text(
                      '$totalCompletions DONE',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 4 Metric Highlight Cards
          Row(
            children: [
              Expanded(
                child: _buildHeatmapStatCard(
                  label: 'ACTIVE DAYS',
                  value: '$activeDays',
                  icon: '📅',
                  color: WinterArcTheme.neoYellow,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildHeatmapStatCard(
                  label: 'LONGEST STREAK',
                  value: '$longestStreak d',
                  icon: '🔥',
                  color: WinterArcTheme.neoMint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildHeatmapStatCard(
                  label: 'TOTAL CRUSHED',
                  value: '$totalCompletions',
                  icon: '⚡',
                  color: WinterArcTheme.neoCoral,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildHeatmapStatCard(
                  label: 'TRACKED HABITS',
                  value: '${habits.length}',
                  icon: '🎯',
                  color: WinterArcTheme.neoLavender,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Production-level GitHub Heatmap Widget
          GithubHeatmap(habitService: _habitService),
          const SizedBox(height: 22),

          // Recent Days Activity Ledger
          _buildRecentActivityLedger(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildHeatmapStatCard({
    required String label,
    required String value,
    required String icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: WinterArcTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WinterArcTheme.borderBlack, width: 2.0),
        boxShadow: const [
          BoxShadow(
            color: WinterArcTheme.borderBlack,
            offset: Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: WinterArcTheme.borderBlack, width: 1.6),
            ),
            child: Text(icon, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: WinterArcTheme.textPrimary,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: WinterArcTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityLedger() {
    final habits = _habitService.habits;
    final totalHabits = habits.length;
    final now = DateTime.now();

    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'RECENT ACTIVITY LEDGER',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
                color: WinterArcTheme.textPrimary,
              ),
            ),
            Text(
              'PAST 7 DAYS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: WinterArcTheme.neoMint,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...List.generate(7, (i) {
          final date = now.subtract(Duration(days: i));
          final dateKey = HabitLog.dateKey(date);
          final isToday = i == 0;
          final completed = _habitService.completedCountForDate(dateKey);
          final ratio = _habitService.completionRatioForDate(dateKey);
          final logsWithNotes = _habitService
              .getLogsForDate(dateKey)
              .where((l) => l.note.isNotEmpty)
              .toList();

          final dayName = isToday
              ? 'Today'
              : i == 1
                  ? 'Yesterday'
                  : '${date.day} ${monthNames[date.month - 1]}';

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: WinterArcTheme.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isToday ? WinterArcTheme.neoYellow : WinterArcTheme.borderBlack,
                width: isToday ? 2.0 : 1.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: WinterArcTheme.borderBlack,
                  offset: isToday ? const Offset(3, 3) : const Offset(2, 2),
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
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: completed > 0
                                ? (ratio >= 1.0
                                    ? WinterArcTheme.neoYellow
                                    : WinterArcTheme.neoMint)
                                : WinterArcTheme.textMuted,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dayName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isToday
                                ? WinterArcTheme.neoYellow
                                : WinterArcTheme.textPrimary,
                          ),
                        ),
                        if (isToday) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: WinterArcTheme.neoYellow,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'ACTIVE',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      totalHabits > 0 ? '$completed / $totalHabits' : '0 habits',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: completed > 0 ? WinterArcTheme.neoMint : WinterArcTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 6,
                    backgroundColor: Colors.white.withOpacity(0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ratio >= 1.0 ? WinterArcTheme.neoYellow : WinterArcTheme.neoMint,
                    ),
                  ),
                ),
                if (logsWithNotes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: logsWithNotes.map((l) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Text(
                          '📝 ${l.note}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                            color: WinterArcTheme.neoYellow,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  // ==========================================
  // TAB 3: STREAKS & GRAPH MATRIX
  // ==========================================
  Widget _buildAnalyticsTab() {
    final profile = _habitService.currentProfile;
    final habits = _habitService.habits;
    final streak = profile?.currentStreak ?? 0;
    final ratio = _habitService.completionRatioForDate();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          const Text(
            'STREAKS & ANALYTICS',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: WinterArcTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 14),

          // Streak Highlight Card
          FrostCard(
            fillColor: WinterArcTheme.neoYellow,
            borderColor: WinterArcTheme.borderBlack,
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text('🔥', style: TextStyle(fontSize: 32)),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$streak DAYS STREAK',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        streak > 0
                            ? 'Unbroken consistency. Keep the fire burning.'
                            : 'Complete your daily habits to ignite your streak!',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // FEATURE: Custom Winter Arc Timeline (From Day X to Final Day)
          FrostCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'WINTER ARC TIMELINE',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: WinterArcTheme.neoMint,
                        letterSpacing: 0.8,
                      ),
                    ),
                    GestureDetector(
                      onTap: _openArcDateRangeDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: WinterArcTheme.neoYellow,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: WinterArcTheme.borderBlack, width: 1.5),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.edit_calendar_rounded, size: 14, color: Colors.black),
                            SizedBox(width: 4),
                            Text(
                              'EDIT DATES',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Start to Final Day Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('START DAY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: WinterArcTheme.textMuted)),
                        const SizedBox(height: 2),
                        Text(
                          profile != null ? _formatDateShort(profile.arcStartDate) : 'Oct 1, 2026',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ],
                    ),
                    const Icon(Icons.arrow_forward_rounded, size: 18, color: WinterArcTheme.neoYellow),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('FINAL DAY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: WinterArcTheme.textMuted)),
                        const SizedBox(height: 2),
                        Text(
                          profile != null ? _formatDateShort(profile.arcEndDate) : 'Jan 1, 2027',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: WinterArcTheme.neoMint),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Linear Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: WinterArcTheme.borderBlack, width: 2.0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: LinearProgressIndicator(
                      value: profile?.arcProgressRatio ?? 0.05,
                      minHeight: 18,
                      backgroundColor: WinterArcTheme.surfaceElevated,
                      valueColor: const AlwaysStoppedAnimation(WinterArcTheme.neoMint),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Day ${profile?.currentArcDay ?? 1} of ${profile?.totalArcDays ?? 90}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: WinterArcTheme.neoYellow),
                    ),
                    Text(
                      '${profile?.daysRemaining ?? 90} Days Remaining',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: WinterArcTheme.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // FEATURE: 7-Day Habit Graph Matrix (Interactive)
          if (habits.isNotEmpty) ...[
            HabitGraphMatrix(
              habits: habits,
              habitService: _habitService,
            ),
            const SizedBox(height: 18),
          ],

          // Total Stats Grid
          Row(
            children: [
              Expanded(
                child: FrostCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TOTAL HABITS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: WinterArcTheme.textMuted)),
                      const SizedBox(height: 6),
                      Text(
                        '${habits.length}',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: WinterArcTheme.neoCyan),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: FrostCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TODAY DONE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: WinterArcTheme.textMuted)),
                      const SizedBox(height: 6),
                      Text(
                        '${(ratio * 100).toInt()}%',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: WinterArcTheme.neoMint),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 4: MOTIVATIONAL QUOTES HUB
  // ==========================================
  Widget _buildQuotesTab() {
    final filteredQuotes = QuotesService.getByCategory(_selectedQuoteCategory);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'MOTIVATIONAL HUB',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: WinterArcTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Fuel for the Winter Arc discipline',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: WinterArcTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: WinterArcTheme.neoYellow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: WinterArcTheme.borderBlack, width: 1.8),
                  boxShadow: const [
                    BoxShadow(color: WinterArcTheme.borderBlack, offset: Offset(2, 2)),
                  ],
                ),
                child: Text(
                  '${filteredQuotes.length} QUOTES',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quote Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                'All',
                'Discipline',
                'Mental Toughness',
                'Action & Focus',
                'Winter Arc',
                'Grit'
              ].map((qCat) {
                final isSelected = _selectedQuoteCategory == qCat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedQuoteCategory = qCat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected ? WinterArcTheme.neoMint : WinterArcTheme.surfaceElevated,
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
                        qCat,
                        style: TextStyle(
                          color: isSelected ? Colors.black : WinterArcTheme.textSecondary,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Quotes List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredQuotes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final q = filteredQuotes[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: WinterArcTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: WinterArcTheme.borderBlack, width: 2.0),
                  boxShadow: const [
                    BoxShadow(
                      color: WinterArcTheme.borderBlack,
                      offset: Offset(3, 3),
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: WinterArcTheme.neoYellow,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: WinterArcTheme.borderBlack, width: 1.4),
                          ),
                          child: Text(
                            q.tag,
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.black),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 16, color: WinterArcTheme.textSecondary),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Copy Quote',
                          onPressed: () => _copyQuoteToClipboard(q.text, q.author),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '“${q.text}”',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: WinterArcTheme.textPrimary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '— ${q.author}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: WinterArcTheme.neoMint,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 3: USER PROFILE
  // ==========================================
  Widget _buildProfileTab() {
    final profile = _habitService.currentProfile;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Profile Card
          FrostCard(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: WinterArcTheme.surfaceCard,
                    shape: BoxShape.circle,
                    border: Border.all(color: WinterArcTheme.borderBlack, width: 2.4),
                    boxShadow: const [
                      BoxShadow(
                        color: WinterArcTheme.borderBlack,
                        offset: Offset(4, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  profile?.name ?? 'Warrior',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: WinterArcTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Age: ${profile?.age ?? 21} • ${profile?.email ?? ""}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: WinterArcTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _openEditProfile,
                        icon: const Icon(Icons.edit_rounded, size: 16, color: Colors.black),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('NAME & AGE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: WinterArcTheme.neoMint,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _openArcDateRangeDialog,
                        icon: const Icon(Icons.calendar_month_rounded, size: 16, color: Colors.black),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('ARC DATES', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: WinterArcTheme.neoYellow,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Winter Arc Creed Card
          FrostCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Text('⚔️', style: TextStyle(fontSize: 16)),
                        SizedBox(width: 8),
                        Text(
                          'THE WINTER ARC CODE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: WinterArcTheme.neoYellow,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: WinterArcTheme.neoMint.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: WinterArcTheme.neoMint, width: 1.2),
                      ),
                      child: const Text(
                        'DISCIPLINE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: WinterArcTheme.neoMint,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildCreedItem('1', 'Zero Excuses', 'Show up every single day, no matter the conditions.'),
                const SizedBox(height: 10),
                _buildCreedItem('2', 'Silent Execution', 'Let your daily discipline make all the noise.'),
                const SizedBox(height: 10),
                _buildCreedItem('3', 'Never Skip Twice', 'One slip is an accident. Two slips is a choice.'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // App Info Badge
          const Center(
            child: Text(
              'KIYO • Winter Arc Edition v1.0.0',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: WinterArcTheme.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Logout Action
          ElevatedButton(
            onPressed: _handleLogout,
            style: ElevatedButton.styleFrom(
              backgroundColor: WinterArcTheme.dangerRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'LOG OUT',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildCreedItem(String number, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: WinterArcTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: WinterArcTheme.borderBlack, width: 1.5),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: WinterArcTheme.neoYellow,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: WinterArcTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // SOFT NEUBRUTALIST BOTTOM NAVIGATION BAR
  // ==========================================
  Widget _buildSoftNeubrutalistNavBar() {
    return Container(
      margin: const EdgeInsets.only(left: 14, right: 14, bottom: 18),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: WinterArcTheme.surface,
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
      child: Row(
        children: [
          _buildNavItem(index: 0, icon: Icons.check_circle_outline_rounded, label: 'Habits'),
          _buildNavItem(index: 1, icon: Icons.grid_on_rounded, label: 'Heatmap'),
          _buildNavItem(index: 2, icon: Icons.insights_rounded, label: 'Matrix'),
          _buildNavItem(index: 3, icon: Icons.format_quote_rounded, label: 'Quotes'),
          _buildNavItem(index: 4, icon: Icons.person_outline_rounded, label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentTabIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _currentTabIndex = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? WinterArcTheme.neoYellow : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: isSelected
                ? Border.all(color: WinterArcTheme.borderBlack, width: 1.8)
                : Border.all(color: Colors.transparent, width: 1.8),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.black : WinterArcTheme.textSecondary,
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                    color: isSelected ? Colors.black : WinterArcTheme.textSecondary,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Workout':
        return WinterArcTheme.neoCoral;
      case 'Nutrition':
        return WinterArcTheme.neoMint;
      case 'Mindset':
        return WinterArcTheme.neoLavender;
      case 'Focus':
        return WinterArcTheme.neoCyan;
      default:
        return WinterArcTheme.neoYellow;
    }
  }
}
