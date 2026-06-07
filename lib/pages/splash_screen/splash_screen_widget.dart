import '/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/services/first_time_service.dart';

class SplashScreenWidget extends StatefulWidget {
  const SplashScreenWidget({super.key});

  static const String routeName = 'SplashScreen';
  static const String routePath = '/splashScreen';

  @override
  State<SplashScreenWidget> createState() => _SplashScreenWidgetState();
}

class _SplashScreenWidgetState extends State<SplashScreenWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    try {
      // 1. Minimum display time for the splash screen (e.g. 2.5 seconds)
      // to let the animation play out beautifully.
      final timerFuture = Future.delayed(const Duration(milliseconds: 2500));

      final futures = await Future.wait([
        FirstTimeService.isFirstTime(),
        FirstTimeService.hasCompletedOnboarding(),
        timerFuture,
      ]);

      final isFirst = futures[0] as bool;
      final hasCompleted = futures[1] as bool;
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;

      if (!mounted) return;

      // Reverse animation for smooth exit
      await _animationController.reverse();

      if (!mounted) return;

      if (isFirst && !hasCompleted) {
        Navigator.pushReplacementNamed(context, '/onboarding-advanced');
      } else if (!isLoggedIn) {
        Navigator.pushReplacementNamed(context, '/authentification');
      } else {
        Navigator.pushReplacementNamed(context, '/homeAlgoace');
      }
    } catch (e) {
      AppLogger.debug('Splash Error: $e', 'Splash');
      if (mounted) Navigator.pushReplacementNamed(context, '/onboarding-advanced');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A), // Deep dark, premium background
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8A2BE2).withValues(alpha: 0.3),
                      blurRadius: 50,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/doron_logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Brand Name
              Text(
                'DORÕN',
                style: GoogleFonts.poppins(
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 12.0,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              // Tagline
              Text(
                'L\'art d\'offrir, réinventé.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 1.5,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 60),
              // Minimalist Loader
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  color: Color(0xFF8A2BE2),
                  strokeWidth: 2.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
