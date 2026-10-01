import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiyo/theme/winter_arc_theme.dart';
import 'package:kiyo/widgets/frost_card.dart';
import 'package:kiyo/widgets/progress_ring.dart';
import 'package:kiyo/widgets/streak_badge.dart';
import 'package:kiyo/widgets/github_heatmap.dart';
import 'package:kiyo/services/habit_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  testWidgets('FrostCard renders child with winter arc theme', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: WinterArcTheme.themeData,
        home: const Scaffold(
          body: FrostCard(
            child: Text('Winter Arc Protocol'),
          ),
        ),
      ),
    );

    expect(find.text('Winter Arc Protocol'), findsOneWidget);
    expect(find.byType(FrostCard), findsOneWidget);
  });

  testWidgets('StreakBadge displays streak count', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StreakBadge(streakDays: 7),
        ),
      ),
    );

    expect(find.text('7 DAYS'), findsOneWidget);
  });

  testWidgets('ProgressRing renders smoothly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProgressRing(progress: 0.75),
        ),
      ),
    );
    expect(find.byType(ProgressRing), findsOneWidget);
  });

  testWidgets('GithubHeatmap renders activity grid', (WidgetTester tester) async {
    final habitService = HabitService();

    await tester.pumpWidget(
      MaterialApp(
        theme: WinterArcTheme.themeData,
        home: Scaffold(
          body: SingleChildScrollView(
            child: GithubHeatmap(habitService: habitService),
          ),
        ),
      ),
    );

    expect(find.text('ACTIVITY HEATMAP'), findsOneWidget);
    expect(find.text('90-Day Arc'), findsOneWidget);
    expect(find.byType(GithubHeatmap), findsOneWidget);
  });

  test('HabitService local-first toggling and write queuing works', () async {
    final service = HabitService();
    // Verify initial state
    expect(service.isHabitCompleted('habit_test_1', '2026-10-01'), false);

    // Toggle habit
    await service.toggleHabitCompletion('habit_test_1', date: '2026-10-01', note: 'Read 20 pages');
    expect(service.isHabitCompleted('habit_test_1', '2026-10-01'), true);
    expect(service.hasPendingWrites, true);

    // Clean up
    service.clear();
    expect(service.hasPendingWrites, false);
  });
}
