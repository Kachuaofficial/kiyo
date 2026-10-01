import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/winter_arc_theme.dart';
import '../services/appwrite_service.dart';
import '../services/habit_service.dart';
import '../widgets/frost_card.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  final _appwrite = AppwriteService();
  final _habitService = HabitService();

  bool _isSignUp = true; // true = Sign Up, false = Log In
  bool _otpSent = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Controllers
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _emailController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  String _currentUserId = '';
  int _resendCountdown = 60;
  Timer? _timer;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fadeController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _resendCountdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _handleSendOtp() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Please enter a valid email address';
      });
      return;
    }

    if (_isSignUp) {
      final name = _nameController.text.trim();
      final ageText = _ageController.text.trim();
      if (name.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Please enter your name';
        });
        return;
      }
      final age = int.tryParse(ageText);
      if (age == null || age <= 0 || age > 120) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Please enter a valid age (e.g. 22)';
        });
        return;
      }
    }

    try {
      final userId = await _appwrite.sendEmailOtp(email: email);
      _currentUserId = userId;

      setState(() {
        _otpSent = true;
        _isLoading = false;
      });
      _startResendTimer();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_otpFocusNodes.isNotEmpty) {
          _otpFocusNodes[0].requestFocus();
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = _cleanErrorMessage(e);
      });
    }
  }

  String _cleanErrorMessage(dynamic e) {
    final str = e.toString();
    if (str.contains('SocketException') ||
        str.contains('Failed host lookup') ||
        str.contains('ClientException') ||
        str.contains('Network is unreachable')) {
      return 'Unable to reach server. Please check your internet connection and try again.';
    }
    return str.replaceFirst('Exception: ', '').trim();
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpControllers.map((c) => c.text.trim()).join();
    if (otp.length < 6) {
      setState(() => _errorMessage = 'Please enter all 6 digits of the code');
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      await _appwrite.verifyEmailOtp(userId: _currentUserId, secret: otp);

      final email = _emailController.text.trim();
      final name = _nameController.text.trim();
      final age = int.tryParse(_ageController.text.trim());

      if (name.isNotEmpty) {
        await _appwrite.updateAccountName(name);
      }

      await _habitService.loadUserData(
        userId: _currentUserId,
        email: email,
        defaultName: name.isNotEmpty ? name : 'Warrior',
        defaultAge: age,
        forceRefresh: true,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (context, anim, secondaryAnim) => const HomeScreen(),
          transitionsBuilder: (context, anim, secondaryAnim, child) {
            return FadeTransition(opacity: anim, child: child);
          },
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = _cleanErrorMessage(e);
      });
    }
  }

  void _onOtpDigitChanged(int index, String value) {
    if (value.length == 1) {
      if (index < 5) {
        _otpFocusNodes[index + 1].requestFocus();
      } else {
        _otpFocusNodes[index].unfocus();
        _handleVerifyOtp();
      }
    } else if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WinterArcTheme.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // App Logo
                    Center(
                      child: Container(
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
                    ),
                    const SizedBox(height: 14),

                    // Neubrutalist App Title Badge
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                        decoration: BoxDecoration(
                          color: WinterArcTheme.neoYellow,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: WinterArcTheme.borderBlack, width: 2.0),
                          boxShadow: const [
                            BoxShadow(
                              color: WinterArcTheme.borderBlack,
                              offset: Offset(3, 3),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: const Text(
                          'KIYO • WINTER ARC',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    const Center(
                      child: Text(
                        '90 Days of Iron Discipline & Daily Tracking',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: WinterArcTheme.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Error Banner
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: WinterArcTheme.dangerRed,
                          borderRadius: BorderRadius.circular(14),
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
                            const Icon(Icons.error_outline_rounded, color: Colors.black, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Main Card
                    FrostCard(
                      padding: const EdgeInsets.all(24),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _otpSent ? _buildOtpView() : _buildCredentialsView(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: WinterArcTheme.neoMint,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Discipline Over Motivation • Winter Arc',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: WinterArcTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCredentialsView() {
    return Column(
      key: const ValueKey('credentials_view'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Soft Neubrutalist Pill Toggle
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: WinterArcTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: WinterArcTheme.borderBlack, width: 2.0),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isSignUp = true;
                      _errorMessage = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _isSignUp ? WinterArcTheme.neoYellow : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: _isSignUp
                          ? Border.all(color: WinterArcTheme.borderBlack, width: 2.0)
                          : null,
                      boxShadow: _isSignUp
                          ? const [
                              BoxShadow(
                                color: WinterArcTheme.borderBlack,
                                offset: Offset(2, 2),
                                blurRadius: 0,
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        'SIGN UP',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                          color: _isSignUp ? Colors.black : WinterArcTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isSignUp = false;
                      _errorMessage = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: !_isSignUp ? WinterArcTheme.neoYellow : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: !_isSignUp
                          ? Border.all(color: WinterArcTheme.borderBlack, width: 2.0)
                          : null,
                      boxShadow: !_isSignUp
                          ? const [
                              BoxShadow(
                                color: WinterArcTheme.borderBlack,
                                offset: Offset(2, 2),
                                blurRadius: 0,
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        'LOG IN',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                          color: !_isSignUp ? Colors.black : WinterArcTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        if (_isSignUp) ...[
          // Name Field
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(
              labelText: 'Full Name',
              hintText: 'e.g. Alex Hunter',
              prefixIcon: Icon(Icons.person_rounded, color: WinterArcTheme.neoYellow),
            ),
          ),
          const SizedBox(height: 14),

          // Age Field
          TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(
              labelText: 'Age',
              hintText: 'e.g. 23',
              prefixIcon: Icon(Icons.cake_rounded, color: WinterArcTheme.neoMint),
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Email Field
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          decoration: const InputDecoration(
            labelText: 'Email Address',
            hintText: 'user@example.com',
            prefixIcon: Icon(Icons.email_rounded, color: WinterArcTheme.neoCyan),
          ),
        ),
        const SizedBox(height: 24),

        // CTA Button
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleSendOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: WinterArcTheme.neoYellow,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: WinterArcTheme.borderBlack, width: 2.2),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.black,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isSignUp ? 'RECEIVE OTP CODE ⚡' : 'SEND LOGIN CODE ⚡',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpView() {
    return Column(
      key: const ValueKey('otp_view'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: WinterArcTheme.neoYellow),
              onPressed: () {
                setState(() {
                  _otpSent = false;
                  _errorMessage = null;
                });
              },
            ),
            const SizedBox(width: 4),
            const Text(
              'ENTER OTP CODE',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
                color: WinterArcTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Text(
          'A 6-digit code has been emailed to:',
          style: const TextStyle(
            fontSize: 13,
            color: WinterArcTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _emailController.text.trim(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: WinterArcTheme.neoYellow,
          ),
        ),
        const SizedBox(height: 24),

        // 6-Digit Rounded Soft Neubrutalist Boxes (Responsive for all screens)
        LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            // 6 boxes with 5 gaps of 6px
            final boxWidth = ((availableWidth - 30) / 6).clamp(34.0, 48.0);
            final boxHeight = (boxWidth * 1.25).clamp(44.0, 58.0);

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: boxWidth,
                  height: boxHeight,
                  child: TextField(
                    controller: _otpControllers[index],
                    focusNode: _otpFocusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: TextStyle(
                      fontSize: (boxWidth * 0.45).clamp(16.0, 22.0),
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      contentPadding: EdgeInsets.zero,
                      filled: true,
                      fillColor: WinterArcTheme.surfaceElevated,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: WinterArcTheme.borderBlack, width: 2.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: WinterArcTheme.neoYellow, width: 2.4),
                      ),
                    ),
                    onChanged: (val) => _onOtpDigitChanged(index, val),
                  ),
                );
              }),
            );
          },
        ),
        const SizedBox(height: 26),

        // Verify Button
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleVerifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: WinterArcTheme.neoMint,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: WinterArcTheme.borderBlack, width: 2.2),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.black,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'CONFIRM & ENTER APP',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.check_rounded, size: 20),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 16),

        Center(
          child: _resendCountdown > 0
              ? Text(
                  'Resend code in ${_resendCountdown}s',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: WinterArcTheme.textMuted,
                  ),
                )
              : TextButton(
                  onPressed: _isLoading ? null : _handleSendOtp,
                  child: const Text(
                    'RESEND CODE 🔄',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: WinterArcTheme.neoYellow,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
