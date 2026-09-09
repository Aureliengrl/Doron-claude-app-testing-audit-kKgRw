import '/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/services/first_time_service.dart';
import '/components/doron_luxury_splash.dart';

class SplashScreenWidget extends StatefulWidget {
  const SplashScreenWidget({super.key});

  static const String routeName = 'SplashScreen';
  static const String routePath = '/splashScreen';

  @override
  State<SplashScreenWidget> createState() => _SplashScreenWidgetState();
}

class _SplashScreenWidgetState extends State<SplashScreenWidget> {
  String _destinationRoute = '/authentification';

  Future<void> _checkDestination() async {
    try {
      final futures = await Future.wait([
        FirstTimeService.isFirstTime(),
        FirstTimeService.hasCompletedOnboarding(),
      ]);

      final isFirst = futures[0] as bool;
      final hasCompleted = futures[1] as bool;
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;

      if (!isLoggedIn) {
        _destinationRoute = '/authentification';
      } else if (isFirst && !hasCompleted) {
        _destinationRoute = '/setup-profile';
      } else {
        _destinationRoute = '/search-page';
      }
    } catch (e) {
      AppLogger.debug('Splash Error: $e', 'Splash');
      _destinationRoute = '/authentification';
    }
  }

  void _onFinished() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, _destinationRoute);
  }

  @override
  Widget build(BuildContext context) {
    return DoronLuxurySplashIntro(
      onInitialize: _checkDestination,
      onFinished: _onFinished,
    );
  }
}
