import '/utils/app_logger.dart';
// device_preview removed "” not compatible with Dart 3.12+
import '/custom_code/actions/index.dart' as actions;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui';
import '/utils/iconly_pro.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:firebase_core/firebase_core.dart';
import 'auth/firebase_auth/firebase_user_provider.dart';
import 'auth/firebase_auth/auth_util.dart';

import 'backend/firebase/firebase_config.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/theme/doron_theme.dart';
import 'flutter_flow/flutter_flow_util.dart';
import 'flutter_flow/internationalization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'flutter_flow/nav/nav.dart';
import 'package:showcaseview/showcaseview.dart';
// import '/components/connection_required_dialog.dart';
import '/components/modern_nav_bar.dart';
import '/services/badge_service.dart';
import '/components/offline_banner.dart';
import '/pages/new_pages/social/social_page_widget.dart';
import '/pages/new_pages/chat/chat_list_page.dart';
import '/services/push_notifications_service.dart';
import '/pages/new_pages/birthday_calendar/birthday_calendar_page.dart';
import 'index.dart';

/// Service de logging d'erreurs global pour capturer les crashs en release
class ErrorLogService {
  static final List<String> _errorLogs = [];
  static const int _maxLogs = 50;

  static void logError(String source, dynamic error, StackTrace? stack) {
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = '''
[$timestamp] $source
Error: $error
Stack: ${stack?.toString().split('\n').take(10).join('\n') ?? 'No stack'}
---''';

    _errorLogs.add(logEntry);
    if (_errorLogs.length > _maxLogs) {
      _errorLogs.removeAt(0);
    }

    // Print pour debug console (visible dans Xcode logs)
    AppLogger.debug('ðŸ”´ ERROR CAPTURED [$source]: $error', 'Debug');
    if (stack != null) {
      AppLogger.debug('Stack trace:\n${stack.toString().split('\n').take(15).join('\n')}', 'Debug');
    }
  }

  static List<String> get logs => List.unmodifiable(_errorLogs);
  static String get logsAsString => _errorLogs.join('\n\n');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ============================================
  // FIX CRITIQUE: Capture d'erreurs globale
  // Pour voir les crashs en mode release sur iOS
  // ============================================

  // 1. Capture les erreurs de framework Flutter (widget build errors, etc.)
  FlutterError.onError = (FlutterErrorDetails details) {
    ErrorLogService.logError(
      'FlutterError',
      details.exceptionAsString(),
      details.stack,
    );
    // En debug, afficher normalement
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
  };

  // 2. Capture les erreurs async non-gérées (Future/Stream errors)
  PlatformDispatcher.instance.onError = (error, stack) {
    ErrorLogService.logError('PlatformDispatcher', error, stack);
    return true; // Indique qu'on a géré l'erreur
  };


  // 3. Widget d'erreur personnalisé - UNIQUEMENT en debug
  // En production (TestFlight), utiliser le widget d'erreur par défaut (silencieux)
  if (kDebugMode) {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Container(
        color: Colors.red.shade900,
        padding: const EdgeInsets.all(16),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'ERREUR WIDGET',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    details.exceptionAsString(),
                    style: const TextStyle(
                      color: Colors.yellow,
                      fontSize: 12,
                      fontFamily: 'monospace',
                      decoration: TextDecoration.none,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Stack: ${details.stack?.toString().split('\n').take(5).join('\n') ?? 'N/A'}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontFamily: 'monospace',
                    decoration: TextDecoration.none,
                  ),
                  textAlign: TextAlign.left,
                ),
              ],
            ),
          ),
        ),
      );
    };
  }

  try {
    GoRouter.optionURLReflectsImperativeAPIs = true;
    usePathUrlStrategy();

    try {
      final environmentValues = FFDevEnvironmentValues();
      await environmentValues.initialize().timeout(const Duration(seconds: 4), onTimeout: () => throw Exception('environmentValues timeout'));
    } catch (e) { AppLogger.debug('Init Error: $e', 'Main'); }

    await initFirebase().timeout(const Duration(seconds: 8), onTimeout: () => throw Exception('Firebase init timeout! Native iOS config is missing or blocking.'));
    
    // Do not await push notification setup, as the native permission prompt can block runApp and cause a white screen.
    PushNotificationsService.initialize();

    try {
      // Start initial custom actions code
      await actions.lockOrientation().timeout(const Duration(seconds: 2));
      // End initial custom actions code
    } catch (e) { AppLogger.debug('Init Error: $e', 'Main'); }

    try {
      await FlutterFlowTheme.initialize().timeout(const Duration(seconds: 4), onTimeout: () => throw Exception('FlutterFlowTheme (SharedPreferences) timeout!'));
    } catch (e) { AppLogger.debug('Init Error: $e', 'Main'); }

    final appState = FFAppState(); // Initialize FFAppState
    try {
      await appState.initializePersistedState().timeout(const Duration(seconds: 4));
    } catch (e, stack) {
      AppLogger.debug('Non-fatal error initializing persisted state: $e\n$stack', 'Main');
    }

    runApp(
      ProviderScope(
        child: provider_pkg.ChangeNotifierProvider(
          create: (context) => appState,
          child: MyApp(),
        ),
      ),
    );
  } catch (e, stack) {
    AppLogger.debug('FATAL ERROR DURING INIT: $e\n$stack', 'Main');
    ErrorLogService.logError('MainInitialization', e, stack);
    runApp(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.red.shade900,
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 48),
                  const SizedBox(height: 16),
                  const Text('CRITICAL INIT ERROR', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text(e.toString(), style: const TextStyle(color: Colors.yellow, fontSize: 14)),
                  const SizedBox(height: 16),
                  Text(stack.toString(), style: const TextStyle(color: Colors.white70, fontSize: 10)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class MyAppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  ThemeMode _themeMode = FlutterFlowTheme.themeMode;

  late AppStateNotifier _appStateNotifier;
  late GoRouter _router;
  String getRoute([RouteMatch? routeMatch]) {
    final RouteMatch lastMatch =
        routeMatch ?? _router.routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : _router.routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }

  List<String> getRouteStack() =>
      _router.routerDelegate.currentConfiguration.matches
          .map((e) => getRoute(e))
          .toList();
  late Stream<BaseAuthUser> userStream;

  final authUserSub = authenticatedUserStream.listen((_) {});

  @override
  void initState() {
    super.initState();

    _appStateNotifier = AppStateNotifier.instance;
    _router = createRouter(_appStateNotifier);
    userStream = doronFirebaseUserStream()
      ..listen((user) {
        _appStateNotifier.update(user);
      });
    jwtTokenStream.listen((_) {});
    Future.delayed(
      Duration.zero,
      () => _appStateNotifier.stopShowingSplashImage(),
    );

    // Initial check for pending routes from push notifications
    if (PushNotificationsService.pendingChatRoute != null) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _router.push('/chat-room/${PushNotificationsService.pendingChatRoute}');
          PushNotificationsService.pendingChatRoute = null;
        }
      });
    }

    // Listen to real-time notification clicks
    PushNotificationsService.onNotificationClick.stream.listen((chatId) {
      if (mounted) {
        _router.push('/chat-room/$chatId');
      }
    });
  }

  @override
  void dispose() {
    authUserSub.cancel();

    super.dispose();
  }

  void setLocale(String language) {
    safeSetState(() => _locale = createLocale(language));
  }

  void setThemeMode(ThemeMode mode) => safeSetState(() {
        _themeMode = mode;
        FlutterFlowTheme.saveThemeMode(mode);
      });

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'DORON',
      scrollBehavior: MyAppScrollBehavior(),
      locale: _locale,
      localizationsDelegates: [
        FFLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FallbackMaterialLocalizationDelegate(),
        FallbackCupertinoLocalizationDelegate(),
      ],
      supportedLocales: const [
        Locale('fr'),
        Locale('en'),
        Locale('es'),
      ],
      theme: DoronTheme.light,
      darkTheme: DoronTheme.dark,
      themeMode: _themeMode,
      routerConfig: _router,
      builder: (context, child) {
        if (child == null) {
          return const Scaffold(backgroundColor: Color(0xFF062248), body: Center(child: CircularProgressIndicator()));
        }
        return ShowCaseWidget(
          builder: (context) => OfflineBannerWrapper(
            child: child,
          ),
        );
      },
    );
  }
}

class NavBarPage extends StatefulWidget {
  NavBarPage({
    Key? key,
    this.initialPage,
    this.page,
    this.disableResizeToAvoidBottomInset = false,
  }) : super(key: key);

  final String? initialPage;
  final Widget? page;
  final bool disableResizeToAvoidBottomInset;

  @override
  _NavBarPageState createState() => _NavBarPageState();
}

/// This is the private State class that goes with NavBarPage.
class _NavBarPageState extends State<NavBarPage> {
  String _currentPageName = 'HomePinterest';
  late Widget? _currentPage;
  int _currentIndex = 0;

  // Créer les widgets UNE SEULE FOIS
  late final List<Widget> _pages;
  late final List<String> _pageNames;

  // Track historically loaded pages for lazy-loading IndexedStack behavior
  final Set<int> _loadedPages = {0}; // Always load the initial page

  @override
  void initState() {
    super.initState();

    _pageNames = ['HomePinterest', 'SearchPage', 'BirthdayCalendar', 'SocialPage', 'UserProfile'];
    _pages = [
      HomePinterestWidget(),
      SearchPageWidget(),
      const BirthdayCalendarPage(),
      const SocialPageWidget(),
      UserProfileWidget(),
    ];

    _currentPageName = widget.initialPage ?? _currentPageName;
    _currentPage = widget.page;
    _currentIndex = _pageNames.indexOf(_currentPageName).clamp(0, 4);
    _loadedPages.add(_currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: !widget.disableResizeToAvoidBottomInset,
      body: Stack(
        children: [
          // Contenu principal: Lazy-loaded IndexedStack equivalent
          _currentPage ?? Stack(
            children: List.generate(_pages.length, (index) {
              final isCurrent = index == _currentIndex;
              final isLoaded = _loadedPages.contains(index);

              if (!isLoaded) return const SizedBox.shrink();

              return Offstage(
                offstage: !isCurrent,
                child: TickerMode(
                  enabled: isCurrent,
                  child: _pages[index],
                ),
              );
            }),
          ),

          // Navbar flottante moderne
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: StreamBuilder<int>(stream: BadgeService.pendingInvitesCountStream, initialData: 0, builder: (context, snapshot) { final pendingCount = snapshot.data ?? 0; return FloatingModernNavBar(
              margin: const EdgeInsets.only(left: 20, right: 20, bottom: 4),
              currentIndex: _currentIndex,
              onTap: (i) async {
                safeSetState(() {
                  _currentPage = null;
                  _currentIndex = i;
                  _currentPageName = _pageNames[i];
                  _loadedPages.add(i); // Mark page as loaded when visited
                });
              },
              onTabScrub: (i) {
                safeSetState(() {
                  _currentPage = null;
                  _currentIndex = i;
                  _currentPageName = _pageNames[i];
                  _loadedPages.add(i); // Pre-load page during scrub
                });
              },
              items: [
                NavBarItem(
                  icon: IconlyPro.homeLight,
                  activeIcon: IconlyPro.homeBold,
                  label: 'Accueil',
                  tooltip: 'Accueil',
                  lottieAsset: 'assets/jsons/Shop Home_.json',
                ),
                NavBarItem(
                  icon: IconlyPro.searchLight,
                  activeIcon: IconlyPro.searchBold,
                  label: 'Recherche',
                  tooltip: 'Recherche',
                  lottieAsset: 'assets/jsons/Search edit.json',
                ),
                NavBarItem(
                  icon: IconlyPro.calendarLight,
                  activeIcon: IconlyPro.calendarBold,
                  label: 'Inspiration',
                  tooltip: 'Inspiration',
                  lottieAsset: 'assets/jsons/calendar_star.json',
                ),
                NavBarItem(
                  icon: IconlyPro.chatLight,
                  activeIcon: IconlyPro.chatBold,
                  label: 'Social',
                  tooltip: 'Social',
                  badgeCount: pendingCount,
                  lottieAsset: 'assets/jsons/Message chat like heart 4.json',
                ),
                NavBarItem(
                  icon: IconlyPro.profileLight,
                  activeIcon: IconlyPro.profileBold,
                  label: 'Profil',
                  tooltip: 'Profil',
                  lottieAsset: 'assets/jsons/iconly-icon-export-1780855916.json',
                ),
              ],
              primaryColor: const Color(0xFF8A2BE2),
            );
          },
        ),
          ),
        ],
      ),
    );
  }
}

