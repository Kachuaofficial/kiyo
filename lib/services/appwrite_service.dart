import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter/foundation.dart';
import '../appwrite_client.dart';
import '../models/user_profile.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';

class AppwriteService {
  static final AppwriteService _instance = AppwriteService._internal();
  factory AppwriteService() => _instance;
  AppwriteService._internal();

 
  static const String databaseId = '6abd2fe9001725cc16f1';
  static const String tableProfiles = 'profiles';
  static const String tableHabits = 'habits';
  static const String tableLogs = 'habit_logs';

  bool _isCloudDatabaseReady = true;
  bool get isCloudDatabaseReady => _isCloudDatabaseReady;

  Future<models.User?> getCurrentUser() async {
    try {
      final user = await account.get();
      return user;
    } catch (e) {
      debugPrint('No active Appwrite session: $e');
      return null;
    }
  }

  
  Future<String> sendEmailOtp({required String email}) async {
    try {
      final token = await account.createEmailToken(
        userId: ID.unique(),
        email: email.trim().toLowerCase(),
      );
      debugPrint('Appwrite Email OTP sent successfully to: $email (userId: ${token.userId})');
      return token.userId;
    } on AppwriteException catch (e) {
      debugPrint('Appwrite OTP Error: ${e.code} - ${e.message}');
      throw Exception(e.message ?? 'Failed to send OTP code. Please check your email.');
    } catch (e) {
      debugPrint('Send OTP generic error: $e');
      final errStr = e.toString();
      if (errStr.contains('SocketException') ||
          errStr.contains('Failed host lookup') ||
          errStr.contains('ClientException')) {
        throw Exception('No internet connection. Please check your network and try again.');
      }
      throw Exception('Failed to send OTP: $e');
    }
  }

  Future<models.Session> verifyEmailOtp({
    required String userId,
    required String secret,
  }) async {
    try {
      final session = await account.createSession(
        userId: userId,
        secret: secret.trim(),
      );
      debugPrint('Appwrite Session created successfully for user: ${session.userId}');
      return session;
    } on AppwriteException catch (e) {
      debugPrint('Appwrite Verify Error: ${e.code} - ${e.message}');
      throw Exception(e.message ?? 'Invalid or expired OTP code.');
    } catch (e) {
      debugPrint('Verify OTP error: $e');
      final errStr = e.toString();
      if (errStr.contains('SocketException') ||
          errStr.contains('Failed host lookup') ||
          errStr.contains('ClientException')) {
        throw Exception('No internet connection. Please check your network and try again.');
      }
      throw Exception('Verification failed: $e');
    }
  }

  Future<void> updateAccountName(String name) async {
    try {
      await account.updateName(name: name.trim());
    } catch (e) {
      debugPrint('Could not update account name in Appwrite: $e');
    }
  }

  Future<void> logout() async {
    try {
      await account.deleteSession(sessionId: 'current');
    } catch (e) {
      debugPrint('Appwrite logout error: $e');
    }
  }



  Future<bool> saveProfile(UserProfile profile) async {
    try {
      await tablesDB.upsertRow(
        databaseId: databaseId,
        tableId: tableProfiles,
        rowId: profile.userId,
        data: profile.toJson(),
      );
      _isCloudDatabaseReady = true;
      return true;
    } catch (e) {
      _isCloudDatabaseReady = false;
      debugPrint('TablesDB saveProfile notice (local cache active): $e');
      return false;
    }
  }

  Future<UserProfile?> getProfile(String userId) async {
    try {
      final row = await tablesDB.getRow(
        databaseId: databaseId,
        tableId: tableProfiles,
        rowId: userId,
      );
      return UserProfile.fromJson(row.data);
    } catch (e) {
      debugPrint('TablesDB getProfile notice: $e');
      return null;
    }
  }

  /// Fetch all habits for user from TablesDB
  Future<List<Habit>?> getHabits(String userId) async {
    try {
      final res = await tablesDB.listRows(
        databaseId: databaseId,
        tableId: tableHabits,
        queries: [
          Query.equal('userId', userId),
        ],
      );
      return res.rows.map((r) => Habit.fromJson(r.data)).toList();
    } catch (e) {
      debugPrint('TablesDB getHabits notice (falling back to local cache if needed): $e');
      return null;
    }
  }

  /// Upsert habit to TablesDB - adds if not present!
  Future<bool> createHabit(Habit habit) async {
    try {
      await tablesDB.upsertRow(
        databaseId: databaseId,
        tableId: tableHabits,
        rowId: habit.id,
        data: habit.toJson(),
      );
      return true;
    } catch (e) {
      debugPrint('TablesDB createHabit notice: $e');
      return false;
    }
  }

  /// Delete habit from TablesDB
  Future<bool> deleteHabit(String habitId) async {
    try {
      await tablesDB.deleteRow(
        databaseId: databaseId,
        tableId: tableHabits,
        rowId: habitId,
      );
      return true;
    } catch (e) {
      debugPrint('TablesDB deleteHabit notice: $e');
      return false;
    }
  }

  /// Fetch habit logs for user from TablesDB with query bounds to minimize reads and cost
  Future<List<HabitLog>?> getHabitLogs(
    String userId, {
    String? date,
    String? minDate,
    int limit = 365,
  }) async {
    try {
      final queries = [
        Query.equal('userId', userId),
        Query.orderDesc('date'),
        Query.limit(limit),
      ];
      if (date != null) {
        queries.add(Query.equal('date', date));
      } else if (minDate != null) {
        queries.add(Query.greaterThanEqual('date', minDate));
      }
      final res = await tablesDB.listRows(
        databaseId: databaseId,
        tableId: tableLogs,
        queries: queries,
      );
      return res.rows.map((r) => HabitLog.fromJson(r.data)).toList();
    } catch (e) {
      debugPrint('TablesDB getHabitLogs notice: $e');
      return null;
    }
  }

  /// Save or toggle habit log in TablesDB using upsertRow
  Future<bool> saveHabitLog(HabitLog log) async {
    try {
      await tablesDB.upsertRow(
        databaseId: databaseId,
        tableId: tableLogs,
        rowId: log.id,
        data: log.toJson(),
      );
      return true;
    } catch (e) {
      debugPrint('TablesDB saveHabitLog notice: $e');
      return false;
    }
  }

  /// Batch sync helper for queued writes
  Future<void> saveHabitLogsBatch(List<HabitLog> logs) async {
    for (final log in logs) {
      await saveHabitLog(log);
    }
  }
}
