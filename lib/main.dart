import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/winter_arc_theme.dart';
import 'services/appwrite_service.dart';
import 'services/habit_service.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: WinterArcTheme.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const WinterArcApp());
}

class WinterArcApp extends StatelessWidget {
  const WinterArcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Winter Arc - Habit Tracker',
      debugShowCheckedModeBanner: false,
      theme: WinterArcTheme.themeData,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _appwrite = AppwriteService();
  final _habitService = HabitService();
  bool _checkingAuth = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkInitialAuth();
  }

  Future<void> _checkInitialAuth() async {
    try {
      final user = await _appwrite.getCurrentUser();
      if (user != null) {
        await _habitService.loadUserData(
          userId: user.$id,
          email: user.email,
          defaultName: user.name.isNotEmpty ? user.name : 'Winter Warrior',
        );
        if (mounted) {
          setState(() {
            _isAuthenticated = true;
            _checkingAuth = false;
          });
        }
        return;
      }
    } catch (e) {
      debugPrint('Auth check error: $e');
    }

    if (mounted) {
      setState(() {
        _isAuthenticated = false;
        _checkingAuth = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAuth) {
      return Scaffold(
        backgroundColor: WinterArcTheme.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
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
              const SizedBox(height: 24),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.8,
                  color: WinterArcTheme.neoYellow,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'AWAKENING THE ARC...',
                style: TextStyle(
                  color: WinterArcTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _isAuthenticated ? const HomeScreen() : const AuthScreen();
  }
}
