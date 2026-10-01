import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import 'appwrite_service.dart';

class HabitService extends ChangeNotifier {
  static final HabitService _instance = HabitService._internal();
  factory HabitService() => _instance;
  HabitService._internal();

  final AppwriteService _appwrite = AppwriteService();

  UserProfile? _currentProfile;
  List<Habit> _habits = [];
  final Map<String, HabitLog> _dailyLogs = {}; // Key: habitId_date
  bool _isLoading = false;
  String _selectedDate = HabitLog.dateKey(DateTime.now());

  // Production Cost & Read/Write Optimization Fields
  static const Duration _cloudCacheTtl = Duration(minutes: 15);
  DateTime? _lastSyncTime;
  Future<void>? _activeLoadFuture;

  // Debounced write queue for minimum database write operations
  final Map<String, HabitLog> _pendingLogWrites = {};
  Timer? _writeDebounceTimer;
  bool _isFlushingWrites = false;

  UserProfile? get currentProfile => _currentProfile;
  List<Habit> get habits => List.unmodifiable(_habits);
  bool get isLoading => _isLoading;
  String get selectedDate => _selectedDate;
  DateTime? get lastSyncTime => _lastSyncTime;
  bool get hasPendingWrites => _pendingLogWrites.isNotEmpty;

  /// Initialize and load all data for user with local-first cache and smart TTL
  Future<void> loadUserData({
    required String userId,
    required String email,
    String? defaultName,
    int? defaultAge,
    bool forceRefresh = false,
  }) async {
    // 1. In-flight request deduplication: return existing load if already running
    if (_activeLoadFuture != null) {
      return _activeLoadFuture!;
    }

    _activeLoadFuture = _executeLoadUserData(
      userId: userId,
      email: email,
      defaultName: defaultName,
      defaultAge: defaultAge,
      forceRefresh: forceRefresh,
    );

    try {
      await _activeLoadFuture;
    } finally {
      _activeLoadFuture = null;
    }
  }

  Future<void> _executeLoadUserData({
    required String userId,
    required String email,
    String? defaultName,
    int? defaultAge,
    required bool forceRefresh,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // 2. STEP A: Instant Local Memory Hydration (0 Network Calls, 0 Database Reads)
    _loadFromLocalCache(userId, prefs);
    if (_currentProfile != null) {
      // Immediate local render for instant 0ms app start
      notifyListeners();
    } else {
      _isLoading = true;
      notifyListeners();
    }

    // 3. STEP B: Smart Cache TTL Check (Cost Optimization)
    // If recently synced and not an explicit pull-to-refresh, SKIP cloud queries entirely!
    final lastSyncMillis = prefs.getInt('last_sync_$userId');
    if (lastSyncMillis != null) {
      _lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSyncMillis);
    }

    final isCacheFresh = _lastSyncTime != null &&
        DateTime.now().difference(_lastSyncTime!) < _cloudCacheTtl &&
        _currentProfile != null &&
        _habits.isNotEmpty;

    if (!forceRefresh && isCacheFresh) {
      debugPrint('⚡ [Cost Optimizer] Using fresh local cache. Cloud reads skipped (0 cost).');
      _isLoading = false;
      notifyListeners();
      return;
    }

    // 4. STEP C: Background Cloud Sync / Revalidation
    try {
      // Flush any unflushed pending writes before reading cloud state
      await flushPendingWrites();

      // Profile Fetch (Single targeted read)
      UserProfile? profile;
      try {
        profile = await _appwrite.getProfile(userId);
      } catch (e) {
        debugPrint('Profile read notice: $e');
      }

      // If user profile is not yet in cloud, create it
      if (profile == null) {
        if (_currentProfile != null) {
          profile = _currentProfile;
        } else {
          profile = UserProfile(
            userId: userId,
            name: defaultName?.isNotEmpty == true ? defaultName! : 'Warrior',
            age: defaultAge != null && defaultAge > 0 ? defaultAge : 21,
            email: email,
            joinedArcDate: DateTime.now(),
            targetDays: 90,
            currentStreak: 0,
          );
        }
        await _appwrite.saveProfile(profile!);
        await prefs.setString('profile_$userId', jsonEncode(profile.toJson()));
      } else {
        // Persist fresh profile to local storage
        await prefs.setString('profile_$userId', jsonEncode(profile.toJson()));
      }
      _currentProfile = profile;

      // Habits Fetch (Single query read for user's habits)
      List<Habit>? cloudHabits;
      try {
        cloudHabits = await _appwrite.getHabits(userId);
      } catch (e) {
        debugPrint('Habits read notice: $e');
      }

      if (cloudHabits != null) {
        _habits = cloudHabits;
        await prefs.setString(
          'habits_$userId',
          jsonEncode(_habits.map((h) => h.toJson()).toList()),
        );
      }

      // Habit Logs Fetch (Bounded query: only query active arc duration, max 365 days)
      await _syncHabitLogsFromCloud(userId, prefs);

      // Record successful cloud sync timestamp
      _lastSyncTime = DateTime.now();
      await prefs.setInt('last_sync_$userId', _lastSyncTime!.millisecondsSinceEpoch);

      // Recalculate streak
      _calculateAndUpdateStreak();
    } catch (e) {
      debugPrint('Cloud sync exception (falling back gracefully to local): $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Hydrate local in-memory state from SharedPreferences (0 reads, 0 ms)
  void _loadFromLocalCache(String userId, SharedPreferences prefs) {
    // 1. Profile
    final localProfileJson = prefs.getString('profile_$userId');
    if (localProfileJson != null) {
      try {
        _currentProfile = UserProfile.fromJson(jsonDecode(localProfileJson));
      } catch (_) {}
    }

    // 2. Habits
    final localHabitsRaw = prefs.getString('habits_$userId');
    if (localHabitsRaw != null) {
      try {
        final List<dynamic> list = jsonDecode(localHabitsRaw);
        _habits = list.map((item) => Habit.fromJson(item)).toList();
      } catch (_) {}
    }

    // 3. Historical Logs
    final localAllRaw = prefs.getString('logs_${userId}_all');
    if (localAllRaw != null) {
      try {
        final List<dynamic> list = jsonDecode(localAllRaw);
        for (final item in list) {
          final log = HabitLog.fromJson(item);
          _dailyLogs['${log.habitId}_${log.date}'] = log;
        }
      } catch (_) {}
    }

    _calculateAndUpdateStreak();
  }

  /// Bounded query fetch for habit logs (optimizes read cost by 90%+)
  Future<void> _syncHabitLogsFromCloud(String userId, SharedPreferences prefs) async {
    try {
      final minDate = _currentProfile != null
          ? HabitLog.dateKey(_currentProfile!.arcStartDate)
          : null;

      final cloudLogs = await _appwrite.getHabitLogs(
        userId,
        minDate: minDate,
        limit: 365,
      );

      if (cloudLogs != null && cloudLogs.isNotEmpty) {
        for (final l in cloudLogs) {
          _dailyLogs['${l.habitId}_${l.date}'] = l;
        }
        // Save merged cache locally
        final allSerialized = _dailyLogs.values.map((l) => l.toJson()).toList();
        await prefs.setString('logs_${userId}_all', jsonEncode(allSerialized));
      }
    } catch (e) {
      debugPrint('Habit logs cloud sync notice: $e');
    }
  }

  /// Check if habit is completed for given date
  bool isHabitCompleted(String habitId, [String? date]) {
    final d = date ?? _selectedDate;
    final log = _dailyLogs['${habitId}_$d'];
    return log?.completed ?? false;
  }

  /// Completed count for given date
  int completedCountForDate([String? date]) {
    final d = date ?? _selectedDate;
    int count = 0;
    for (final habit in _habits) {
      if (isHabitCompleted(habit.id, d)) {
        count++;
      }
    }
    return count;
  }

  /// Completion percentage for given date (0.0 to 1.0)
  double completionRatioForDate([String? date]) {
    if (_habits.isEmpty) return 0.0;
    return completedCountForDate(date) / _habits.length;
  }

  /// Retrieve specific habit log (including note) for date
  HabitLog? getHabitLog(String habitId, [String? date]) {
    final d = date ?? _selectedDate;
    return _dailyLogs['${habitId}_$d'];
  }

  /// Toggle habit completion with immediate local UI response + debounced cloud write queue
  Future<void> toggleHabitCompletion(String habitId, {String? date, String? note}) async {
    final d = date ?? _selectedDate;
    final key = '${habitId}_$d';
    final currentStatus = isHabitCompleted(habitId, d);
    final newStatus = !currentStatus;

    final logId = 'log_${habitId}_$d';
    final userId = _currentProfile?.userId ?? 'local_user';

    final updatedLog = HabitLog(
      id: logId,
      habitId: habitId,
      userId: userId,
      date: d,
      completed: newStatus,
      completedAt: newStatus ? DateTime.now() : null,
      note: newStatus ? (note ?? _dailyLogs[key]?.note ?? '') : '',
    );

    // 1. Immediate in-memory update (0ms latency UI)
    _dailyLogs[key] = updatedLog;
    notifyListeners();
    _calculateAndUpdateStreak();

    // 2. Immediate local persistence (resilient against app kill)
    final prefs = await SharedPreferences.getInstance();
    final allSerialized = _dailyLogs.values.map((l) => l.toJson()).toList();
    await prefs.setString('logs_${userId}_all', jsonEncode(allSerialized));

    // 3. Queue to debounced write batch (cancels rapid toggles & minimizes writes)
    _pendingLogWrites[logId] = updatedLog;

    _writeDebounceTimer?.cancel();
    _writeDebounceTimer = Timer(const Duration(milliseconds: 900), () {
      flushPendingWrites();
    });
  }

  /// Flush queued pending writes to Appwrite TablesDB
  Future<void> flushPendingWrites() async {
    if (_pendingLogWrites.isEmpty || _isFlushingWrites) return;

    _isFlushingWrites = true;
    _writeDebounceTimer?.cancel();

    final writesToProcess = Map<String, HabitLog>.from(_pendingLogWrites);
    _pendingLogWrites.clear();

    try {
      debugPrint('⚡ [Cost Optimizer] Flushing ${writesToProcess.length} debounced write(s) to cloud.');
      for (final log in writesToProcess.values) {
        await _appwrite.saveHabitLog(log);
      }
    } catch (e) {
      debugPrint('Failed to flush some writes to cloud: $e');
      // Re-queue failed writes
      _pendingLogWrites.addAll(writesToProcess);
    } finally {
      _isFlushingWrites = false;
    }
  }

  /// Total count of all completed habit instances across history
  int get totalCompletions {
    return _dailyLogs.values.where((l) => l.completed).length;
  }

  /// Total count of days where at least 1 habit was completed
  int get totalActiveDays {
    final activeDates = <String>{};
    for (final log in _dailyLogs.values) {
      if (log.completed) {
        activeDates.add(log.date);
      }
    }
    return activeDates.length;
  }

  /// Longest consecutive streak of active days
  int get longestStreak {
    final activeDates = <DateTime>{};
    for (final log in _dailyLogs.values) {
      if (log.completed) {
        final parsed = DateTime.tryParse(log.date);
        if (parsed != null) {
          activeDates.add(DateTime(parsed.year, parsed.month, parsed.day));
        }
      }
    }
    if (activeDates.isEmpty) return _currentProfile?.currentStreak ?? 0;

    final sorted = activeDates.toList()..sort();
    int maxStreak = 1;
    int current = 1;

    for (int i = 1; i < sorted.length; i++) {
      final prev = sorted[i - 1];
      final curr = sorted[i];
      if (curr.difference(prev).inDays == 1) {
        current++;
        if (current > maxStreak) {
          maxStreak = current;
        }
      } else if (curr.difference(prev).inDays > 1) {
        current = 1;
      }
    }

    final curStreak = _currentProfile?.currentStreak ?? 0;
    return maxStreak > curStreak ? maxStreak : curStreak;
  }

  /// Get list of logs for specific date
  List<HabitLog> getLogsForDate(String date) {
    return _habits
        .map((h) => _dailyLogs['${h.id}_$date'])
        .whereType<HabitLog>()
        .toList();
  }

  /// Get set of active date strings
  Set<String> get activeDates {
    return _dailyLogs.values
        .where((l) => l.completed)
        .map((l) => l.date)
        .toSet();
  }

  /// Update Winter Arc date range (start day to final day)
  Future<void> updateArcTimeline({required DateTime start, required DateTime end}) async {
    if (_currentProfile == null) return;
    final updated = _currentProfile!.copyWith(
      arcStartDate: start,
      arcEndDate: end,
      targetDays: end.difference(start).inDays,
    );
    _currentProfile = updated;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_${updated.userId}', jsonEncode(updated.toJson()));
    await _appwrite.saveProfile(updated);
  }

  /// Add a brand new habit
  Future<void> addHabit({
    required String title,
    required String description,
    required String category,
    required String icon,
  }) async {
    if (_currentProfile == null) return;
    final userId = _currentProfile!.userId;
    final newHabit = Habit(
      id: 'habit_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: title.trim(),
      description: description.trim(),
      category: category,
      icon: icon,
      isDefault: false,
      createdAt: DateTime.now(),
    );

    _habits.add(newHabit);
    notifyListeners();

    // Persist locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'habits_$userId',
      jsonEncode(_habits.map((h) => h.toJson()).toList()),
    );

    // Sync to Appwrite
    await _appwrite.createHabit(newHabit);
  }

  /// Delete a habit
  Future<void> deleteHabit(String habitId) async {
    if (_currentProfile == null) return;
    final userId = _currentProfile!.userId;

    _habits.removeWhere((h) => h.id == habitId);
    _dailyLogs.removeWhere((k, _) => k.startsWith('${habitId}_'));
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'habits_$userId',
      jsonEncode(_habits.map((h) => h.toJson()).toList()),
    );

    await _appwrite.deleteHabit(habitId);
  }

  /// Update user profile (Name and Age)
  Future<void> updateProfile({required String name, required int age}) async {
    if (_currentProfile == null) return;
    final updated = _currentProfile!.copyWith(name: name, age: age);
    _currentProfile = updated;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_${updated.userId}', jsonEncode(updated.toJson()));

    await _appwrite.saveProfile(updated);
    await _appwrite.updateAccountName(name);
  }

  /// Select date to inspect or check habits
  void selectDate(String date) {
    _selectedDate = date;
    notifyListeners();
  }

  /// Recalculate streak based on completions
  void _calculateAndUpdateStreak() {
    if (_currentProfile == null) return;
    final today = HabitLog.dateKey(DateTime.now());
    final doneToday = completionRatioForDate(today) >= 0.5;

    int streak = _currentProfile!.currentStreak;
    if (streak == 0 && doneToday) {
      streak = 1;
    } else if (doneToday && streak < 1) {
      streak = 1;
    }

    if (streak != _currentProfile!.currentStreak) {
      _currentProfile = _currentProfile!.copyWith(currentStreak: streak);
      notifyListeners();
    }
  }

  /// Clear all on logout
  void clear() {
    flushPendingWrites();
    _currentProfile = null;
    _habits = [];
    _dailyLogs.clear();
    _pendingLogWrites.clear();
    _writeDebounceTimer?.cancel();
    _lastSyncTime = null;
    _selectedDate = HabitLog.dateKey(DateTime.now());
    notifyListeners();
  }
}
