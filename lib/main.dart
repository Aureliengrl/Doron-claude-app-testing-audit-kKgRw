import '/utils/app_logger.dart';
import 'package:device_preview/device_preview.dart';
import '/custom_code/actions/index.dart' as actions;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui';
import 'dart:async';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth/firebase_auth/firebase_user_provider.dart';
import 'auth/firebase_auth/auth_util.dart';

import 'backend/firebase/firebase_config.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/theme/doron_theme.dart';
import 'flutter_flow/flutter_flow_util.dart';
import 'flutter_flow/internationalization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'flutter_flow/nav/nav.dart';
import 'package:showcaseview/showcaseview.dart';
import '/components/modern_nav_bar.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import '/components/offline_banner.dart';
import '/services/push_notifications_service.dart';
import '/services/presence_service.dart';
import '/services/friend_service.dart';
import '/utils/user_display_helper.dart';
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
    AppLogger.debug('🔴 ERROR CAPTURED [$source]: $error', 'Debug');
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

    // Initialize presence service (online/offline status)
    if (FirebaseAuth.instance.currentUser != null) {
      PresenceService.instance.initialize();
    }
    // Listen for auth changes to start/stop presence tracking
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        PresenceService.instance.initialize();
      } else {
        PresenceService.instance.dispose();
        UserProfileCache.instance.clear();
      }
    });

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
      DevicePreview(
        enabled: kDebugMode,
        defaultDevice: Devices.ios.iPhone13,
        builder: (context) => ProviderScope(
          child: provider_pkg.ChangeNotifierProvider(
            create: (context) => appState,
            child: MyApp(),
          ),
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
      locale: DevicePreview.locale(context) ?? _locale,
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
        // BUG 5 FIX: DevicePreview.appBuilder était toujours actif, même en release.
        // Il est maintenant conditionné à kDebugMode pour ne jamais apparaître
        // sur TestFlight ou l'App Store.
        final showcase = ShowCaseWidget(
          builder: (context) => OfflineBannerWrapper(child: child),
        );
        if (kDebugMode) {
          return DevicePreview.appBuilder(context, showcase);
        }
        return showcase;
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

  // Badge counts
  int _friendRequestBadge = 0;
  int _unreadChatBadge = 0;

  // Streams for badge counts
  StreamSubscription? _friendRequestSub;
  StreamSubscription? _chatUnreadSub;

  // Track previous friend request count for in-app notification
  int _previousFriendRequestCount = -1; // -1 = not yet initialized

  // BUG 13 FIX: abonnement aux changements d'authentification pour
  // réinitialiser les streams de badges après un re-login.
  StreamSubscription? _authSub;

  @override
  void initState() {
    super.initState();

    _pageNames = ['HomePinterest', 'SearchPage', 'Inspiration', 'UserProfile'];
    _pages = [
      HomePinterestWidget(),
      SearchPageWidget(),
      TikTokInspirationPageWidget(),
      UserProfileWidget(),
    ];

    _currentPageName = widget.initialPage ?? _currentPageName;
    _currentPage = widget.page;
    _currentIndex = _pageNames.indexOf(_currentPageName).clamp(0, 3);
    _loadedPages.add(_currentIndex);

    _initBadgeStreams();

    // BUG 13 FIX: Re-init les streams de badges à chaque changement d'auth
    // (connexion / déconnexion / changement de compte).
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;
      // Annuler les anciens streams (liés à l'uid précédent)
      _friendRequestSub?.cancel();
      _chatUnreadSub?.cancel();
      _previousFriendRequestCount = -1;
      if (user != null) {
        // Nouvel utilisateur connecté : réabonner les streams
        _initBadgeStreams();
      } else {
        // Déconnecté : remettre les badges à zéro
        safeSetState(() {
          _friendRequestBadge = 0;
          _unreadChatBadge = 0;
        });
      }
    });
  }

  void _initBadgeStreams() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Listen for pending friend requests
    _friendRequestSub = FriendService.getPendingRequestsStream().listen(
      (requests) {
        if (!mounted) return;
        final newCount = requests.length;

        // Show in-app notification for new friend requests
        if (_previousFriendRequestCount >= 0 && newCount > _previousFriendRequestCount) {
          // Find the newest request to show its name
          final newestRequest = requests.isNotEmpty ? requests.first : null;
          if (newestRequest != null) {
            _showFriendRequestBanner(newestRequest['displayName'] ?? 'Quelqu\'un');
          }
        }
        _previousFriendRequestCount = newCount;

        safeSetState(() {
          _friendRequestBadge = newCount;
        });
      },
      onError: (e) {
        AppLogger.debug('Badge friendRequest stream error: $e', 'NavBar');
      },
    );

    // Listen for unread chat messages
    _chatUnreadSub = FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: uid)
        .snapshots()
        .listen(
      (snapshot) {
        if (!mounted) return;
        int totalUnread = 0;
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final unreadCount = data['unreadCount'] as Map<String, dynamic>?;
          if (unreadCount != null && unreadCount.containsKey(uid)) {
            final count = unreadCount[uid];
            if (count is int) {
              totalUnread += count;
            } else if (count is num) {
              totalUnread += count.toInt();
            }
          }
        }
        safeSetState(() {
          _unreadChatBadge = totalUnread;
        });
      },
      onError: (e) {
        AppLogger.debug('Badge chat unread stream error: $e', 'NavBar');
      },
    );
  }

  void _showFriendRequestBanner(String senderName) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(IconlyLight.addUser, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Nouvelle demande d\'ami de $senderName',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF8A2BE2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Voir',
          textColor: Colors.white,
          onPressed: () {
            // Navigate to profile tab where friend requests are visible
            safeSetState(() {
              _currentPage = null;
              _currentIndex = 3;
              _currentPageName = _pageNames[3];
              _loadedPages.add(3);
            });
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _friendRequestSub?.cancel();
    _chatUnreadSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
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

          // Navbar flottante moderne — Tab Scrubbing
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingModernNavBar(
              currentIndex: _currentIndex,
              onTap: (i) async {
                safeSetState(() {
                  _currentPage = null;
                  _currentIndex = i;
                  _currentPageName = _pageNames[i];
                  _loadedPages.add(i);
                });
              },
              onTabScrub: (i) {
                // Scrub en cours — pré-charger la page cible
                if (!_loadedPages.contains(i)) {
                  safeSetState(() => _loadedPages.add(i));
                }
              },
              items: [
                NavBarItem(
                  icon: IconlyLight.home,
                  activeIcon: IconlyBold.home,
                  label: 'Accueil',
                  iconSize: 24.0,
                  badgeCount: _unreadChatBadge,
                ),
                const NavBarItem(
                  icon: IconlyLight.search,
                  activeIcon: IconlyBold.search,
                  label: 'Recherche',
                  iconSize: 24.0,
                ),
                const NavBarItem(
                  icon: IconlyLight.discovery,
                  activeIcon: IconlyBold.discovery,
                  label: 'Inspo',
                  iconSize: 24.0,
                ),
                NavBarItem(
                  icon: IconlyLight.profile,
                  activeIcon: IconlyBold.profile,
                  label: 'Profil',
                  iconSize: 24.0,
                  badgeCount: _friendRequestBadge,
                ),
              ],
              primaryColor: const Color(0xFF8A2BE2),
            ),
          ),
        ],
      ),
    );
  }
}
