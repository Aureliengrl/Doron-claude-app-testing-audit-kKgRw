import '/utils/app_logger.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/backend/schema/enums/enums.dart';

import '/auth/base_auth_user_provider.dart';

import '/main.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/lat_lng.dart';
import '/flutter_flow/place.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'serialization_util.dart';

import '/index.dart';
import '/pages/voice_assistant/voice_listening_page_widget.dart';
import '/pages/voice_assistant/voice_analysis_page_widget.dart';
import '/pages/voice_assistant/voice_guided_onboarding_widget.dart';
import '/pages/tiktok_inspiration/tiktok_inspiration_page_widget.dart';
import '/pages/admin/admin_products_page.dart';
import '/pages/new_pages/public_profile/public_profile_page.dart';
import '/pages/wishlists/wishlist_details_widget.dart';
import '/pages/new_pages/chat/chat_list_page.dart';
import '/pages/new_pages/chat/chat_room_page.dart';
import '/pages/authentification/choose_handle_widget.dart';

export 'package:go_router/go_router.dart';
export 'serialization_util.dart';

const kTransitionInfoKey = '__transition_info__';

GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class AppStateNotifier extends ChangeNotifier {
  AppStateNotifier._();

  static AppStateNotifier? _instance;
  static AppStateNotifier get instance => _instance ??= AppStateNotifier._();

  BaseAuthUser? initialUser;
  BaseAuthUser? user;
  bool showSplashImage = true;
  String? _redirectLocation;

  /// Determines whether the app will refresh and build again when a sign
  /// in or sign out happens. This is useful when the app is launched or
  /// on an unexpected logout. However, this must be turned off when we
  /// intend to sign in/out and then navigate or perform any actions after.
  /// Otherwise, this will trigger a refresh and interrupt the action(s).
  bool notifyOnAuthChange = true;

  bool get loading => user == null || showSplashImage;
  bool get loggedIn => user?.loggedIn ?? false;
  bool get initiallyLoggedIn => initialUser?.loggedIn ?? false;
  bool get shouldRedirect => loggedIn && _redirectLocation != null;

  String getRedirectLocation() => _redirectLocation!;
  bool hasRedirect() => _redirectLocation != null;
  void setRedirectLocationIfUnset(String loc) => _redirectLocation ??= loc;
  void clearRedirectLocation() => _redirectLocation = null;

  /// Mark as not needing to notify on a sign in / out when we intend
  /// to perform subsequent actions (such as navigation) afterwards.
  void updateNotifyOnAuthChange(bool notify) => notifyOnAuthChange = notify;

  void update(BaseAuthUser newUser) {
    final shouldUpdate =
        user?.uid == null || newUser.uid == null || user?.uid != newUser.uid;
    initialUser ??= newUser;
    user = newUser;
    // Refresh the app on auth change unless explicitly marked otherwise.
    // No need to update unless the user has changed.
    if (notifyOnAuthChange && shouldUpdate) {
      notifyListeners();
    }
    // Once again mark the notifier as needing to update on auth change
    // (in order to catch sign in / out events).
    updateNotifyOnAuthChange(true);
  }

  void stopShowingSplashImage() {
    showSplashImage = false;
    notifyListeners();
  }
}

/// Détermine la route initiale de façon binaire et immédiate
Future<String> _determineInitialRoute() async {
  try {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? currentUser = auth.currentUser;
    final bool isLoggedIn = currentUser != null;

    AppLogger.debug('🔍 Route initiale — loggedIn:$isLoggedIn', 'Nav');

    // Routage Binaire: Si connecté -> Accueil. Sinon -> Auth. Plus de tutoriel.
    if (isLoggedIn) {
        return '/home-pinterest';
    } else {
        return '/authentification';
    }
  } catch (e) {
    AppLogger.debug('❌ Erreur détermination route: $e', 'Nav');
    return '/authentification';
  }
}

GoRouter createRouter(AppStateNotifier appStateNotifier) => GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: kDebugMode, // Logs de navigation uniquement en debug
      refreshListenable: appStateNotifier,
      navigatorKey: appNavigatorKey,
      errorBuilder: (context, state) =>
          appStateNotifier.loggedIn ? NavBarPage() : AuthentificationWidget(),
      routes: [
        FFRoute(
          name: '_initialize',
          path: '/',
          builder: (context, _) => const RootSplashWidget(),
        ),
        FFRoute(
          name: WelcomeScreen.routeName,
          path: WelcomeScreen.routePath,
          builder: (context, params) => WelcomeScreen(),
        ),
        // ModeChoiceScreen removed — flow now goes directly Welcome → Auth
        FFRoute(
          name: AuthentificationWidget.routeName,
          path: AuthentificationWidget.routePath,
          builder: (context, params) => AuthentificationWidget(),
        ),
        FFRoute(
          name: ChooseHandleWidget.routeName,
          path: ChooseHandleWidget.routePath,
          requireAuth: true,
          builder: (context, params) => ChooseHandleWidget(
            returnTo: params.getParam('returnTo', ParamType.String),
            personId: params.getParam('personId', ParamType.String),
          ),
        ),
        FFRoute(
          name: GiftGeneratorWidget.routeName,
          path: GiftGeneratorWidget.routePath,
          builder: (context, params) => GiftGeneratorWidget(),
        ),
        FFRoute(
          name: FavouritesWidget.routeName,
          path: FavouritesWidget.routePath,
          requireAuth: true,
          builder: (context, params) => params.isEmpty
              ? NavBarPage(initialPage: 'Favourites')
              : FavouritesWidget(),
        ),
        // Chat routes removed - files no longer exist
        // FFRoute(
        //     name: ChatHistoryWidget.routeName,
        //     path: ChatHistoryWidget.routePath,
        //     requireAuth: true,
        //     builder: (context, params) => params.isEmpty
        //         ? NavBarPage(initialPage: 'ChatHistory')
        //         : NavBarPage(
        //             initialPage: 'ChatHistory',
        //             page: ChatHistoryWidget(),
        //           )),
        FFRoute(
          name: OpenAiSuggestedGiftsWidget.routeName,
          path: OpenAiSuggestedGiftsWidget.routePath,
          requireAuth: true,
          builder: (context, params) => OpenAiSuggestedGiftsWidget(
            fetchproducts: params.getParam<ProductsStruct>(
              'fetchproducts',
              ParamType.DataStruct,
              isList: true,
              structBuilder: ProductsStruct.fromSerializableMap,
            ),
          ),
        ),
        // FFRoute(
        //   name: PreviewChatWidget.routeName,
        //   path: PreviewChatWidget.routePath,
        //   builder: (context, params) => PreviewChatWidget(
        //     products: params.getParam<ProductsStruct>(
        //       'products',
        //       ParamType.DataStruct,
        //       isList: true,
        //       structBuilder: ProductsStruct.fromSerializableMap,
        //     ),
        //     chat: params.getParam<OpenAiResponseStruct>(
        //       'chat',
        //       ParamType.DataStruct,
        //       isList: true,
        //       structBuilder: OpenAiResponseStruct.fromSerializableMap,
        //     ),
        //   ),
        // ),
        FFRoute(
          name: ForgotPasswordWidget.routeName,
          path: ForgotPasswordWidget.routePath,
          builder: (context, params) => ForgotPasswordWidget(),
        ),
        // New pages
        FFRoute(
          name: OnboardingAdvancedWidget.routeName,
          path: OnboardingAdvancedWidget.routePath,
          requireAuth: true,
          builder: (context, params) => OnboardingAdvancedWidget(),
        ),
        FFRoute(
          name: OnboardingGiftsResultWidget.routeName,
          path: OnboardingGiftsResultWidget.routePath,
          requireAuth: true,
          builder: (context, params) => OnboardingGiftsResultWidget(),
        ),
        FFRoute(
          name: HomePinterestWidget.routeName,
          path: HomePinterestWidget.routePath,
          requireAuth: true,
          builder: (context, params) => params.isEmpty
              ? NavBarPage(initialPage: 'HomePinterest')
              : HomePinterestWidget(),
        ),
        FFRoute(
          name: SearchPageWidget.routeName,
          path: SearchPageWidget.routePath,
          requireAuth: true,
          builder: (context, params) => params.isEmpty
              ? NavBarPage(initialPage: 'SearchPage')
              : SearchPageWidget(),
        ),
        FFRoute(
          name: GiftResultsWidget.routeName,
          path: GiftResultsWidget.routePath,
          requireAuth: true,
          builder: (context, params) => GiftResultsWidget(),
        ),
        FFRoute(
          name: 'ChatList',
          path: '/chat-list',
          requireAuth: true,
          builder: (context, params) => const ChatListPage(),
        ),
        FFRoute(
          name: 'ChatRoom',
          path: '/chat-room/:chatId',
          requireAuth: true,
          builder: (context, params) => ChatRoomPage(
            chatId: params.getParam<String>('chatId', ParamType.String) ?? '',
            chatData: null,
          ),
        ),
        // ── Voice Module ────────────────────────────────────────────────────
        FFRoute(
          name: VoiceGuidedOnboardingWidget.routeName,
          path: VoiceGuidedOnboardingWidget.routePath,
          builder: (context, params) => const VoiceGuidedOnboardingWidget(),
        ),
        FFRoute(
          name: 'VoiceListening',
          path: '/voiceListening',
          requireAuth: true,
          builder: (context, params) => const VoiceListeningPageWidget(),
        ),
        FFRoute(
          name: 'VoiceAnalysis',
          path: '/voiceAnalysis',
          requireAuth: true,
          builder: (context, params) => VoiceAnalysisPageWidget(
            transcript: params.getParam<String>('transcript', ParamType.String) ?? '',
          ),
        ),
        // ── Splash / TikTok / Admin ──────────────────────────────────────────
        FFRoute(
          name: SplashScreenWidget.routeName,
          path: SplashScreenWidget.routePath,
          builder: (context, params) => SplashScreenWidget(),
        ),
        // TikTok Inspiration (BÊTA)
        FFRoute(
          name: TikTokInspirationPageWidget.routeName,
          path: TikTokInspirationPageWidget.routePath,
          requireAuth: true,
          builder: (context, params) => TikTokInspirationPageWidget(),
        ),
        // Admin Products Page
        FFRoute(
          name: AdminProductsPage.routeName,
          path: AdminProductsPage.routePath,
          builder: (context, params) => AdminProductsPage(),
        ),
        // Wishlists & Liked Products
        FFRoute(
          name: WishlistsPageWidget.routeName,
          path: WishlistsPageWidget.routePath,
          requireAuth: true,
          builder: (context, params) => WishlistsPageWidget(),
        ),
        FFRoute(
          name: LikedProductsPageWidget.routeName,
          path: LikedProductsPageWidget.routePath,
          requireAuth: true,
          builder: (context, params) => LikedProductsPageWidget(),
        ),
        FFRoute(
          name: WishlistDetailsWidget.routeName,
          path: WishlistDetailsWidget.routePath,
          requireAuth: true,
          builder: (context, params) => WishlistDetailsWidget(
            wishlistId: params.getParam<String>('wishlistId', ParamType.String) ?? '',
          ),
        ),
        // Profil public @handle
        FFRoute(
          name: PublicProfilePage.routeName,
          path: PublicProfilePage.routePath,
          builder: (context, params) => PublicProfilePage(
            handle: params.getParam<String>('handle', ParamType.String),
          ),
        ),
      ].map((r) => r.toRoute(appStateNotifier)).toList(),
    );

extension NavParamExtensions on Map<String, String?> {
  Map<String, String> get withoutNulls => Map.fromEntries(
        entries
            .where((e) => e.value != null)
            .map((e) => MapEntry(e.key, e.value!)),
      );
}

extension NavigationExtensions on BuildContext {
  void goNamedAuth(
    String name,
    bool mounted, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, String> queryParameters = const <String, String>{},
    Object? extra,
    bool ignoreRedirect = false,
  }) =>
      !mounted || GoRouter.of(this).shouldRedirect(ignoreRedirect)
          ? null
          : goNamed(
              name,
              pathParameters: pathParameters,
              queryParameters: queryParameters,
              extra: extra,
            );

  void pushNamedAuth(
    String name,
    bool mounted, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, String> queryParameters = const <String, String>{},
    Object? extra,
    bool ignoreRedirect = false,
  }) =>
      !mounted || GoRouter.of(this).shouldRedirect(ignoreRedirect)
          ? null
          : pushNamed(
              name,
              pathParameters: pathParameters,
              queryParameters: queryParameters,
              extra: extra,
            );

  void safePop() {
    // If there is only one route on the stack, navigate to the initial
    // page instead of popping.
    if (canPop()) {
      pop();
    } else {
      go('/');
    }
  }
}

extension GoRouterExtensions on GoRouter {
  AppStateNotifier get appState => AppStateNotifier.instance;
  void prepareAuthEvent([bool ignoreRedirect = false]) =>
      appState.hasRedirect() && !ignoreRedirect
          ? null
          : appState.updateNotifyOnAuthChange(false);
  bool shouldRedirect(bool ignoreRedirect) =>
      !ignoreRedirect && appState.hasRedirect();
  void clearRedirectLocation() => appState.clearRedirectLocation();
  void setRedirectLocationIfUnset(String location) =>
      appState.updateNotifyOnAuthChange(false);
}

extension _GoRouterStateExtensions on GoRouterState {
  Map<String, dynamic> get extraMap =>
      extra != null ? extra as Map<String, dynamic> : {};
  Map<String, dynamic> get allParams => <String, dynamic>{}
    ..addAll(pathParameters)
    ..addAll(uri.queryParameters)
    ..addAll(extraMap);
  TransitionInfo get transitionInfo => extraMap.containsKey(kTransitionInfoKey)
      ? extraMap[kTransitionInfoKey] as TransitionInfo
      : TransitionInfo.appDefault();
}

class FFParameters {
  FFParameters(this.state, [this.asyncParams = const {}]);

  final GoRouterState state;
  final Map<String, Future<dynamic> Function(String)> asyncParams;

  Map<String, dynamic> futureParamValues = {};

  // Parameters are empty if the params map is empty or if the only parameter
  // present is the special extra parameter reserved for the transition info.
  bool get isEmpty =>
      state.allParams.isEmpty ||
      (state.allParams.length == 1 &&
          state.extraMap.containsKey(kTransitionInfoKey));
  bool isAsyncParam(MapEntry<String, dynamic> param) =>
      asyncParams.containsKey(param.key) && param.value is String;
  bool get hasFutures => state.allParams.entries.any(isAsyncParam);
  Future<bool> completeFutures() => Future.wait(
        state.allParams.entries.where(isAsyncParam).map(
          (param) async {
            final doc = await asyncParams[param.key]!(param.value)
                .onError((_, __) => null);
            if (doc != null) {
              futureParamValues[param.key] = doc;
              return true;
            }
            return false;
          },
        ),
      ).onError((_, __) => [false]).then((v) => v.every((e) => e));

  dynamic getParam<T>(
    String paramName,
    ParamType type, {
    bool isList = false,
    List<String>? collectionNamePath,
    StructBuilder<T>? structBuilder,
  }) {
    if (futureParamValues.containsKey(paramName)) {
      return futureParamValues[paramName];
    }
    if (!state.allParams.containsKey(paramName)) {
      return null;
    }
    final param = state.allParams[paramName];
    // Got parameter from `extras`, so just directly return it.
    if (param is! String) {
      return param;
    }
    // Return serialized value.
    return deserializeParam<T>(
      param,
      type,
      isList,
      collectionNamePath: collectionNamePath,
      structBuilder: structBuilder,
    );
  }
}

class FFRoute {
  const FFRoute({
    required this.name,
    required this.path,
    required this.builder,
    this.requireAuth = false,
    this.asyncParams = const {},
    this.routes = const [],
  });

  final String name;
  final String path;
  final bool requireAuth;
  final Map<String, Future<dynamic> Function(String)> asyncParams;
  final Widget Function(BuildContext, FFParameters) builder;
  final List<GoRoute> routes;

  GoRoute toRoute(AppStateNotifier appStateNotifier) => GoRoute(
        name: name,
        path: path,
        redirect: (context, state) {
          if (appStateNotifier.shouldRedirect) {
            final redirectLocation = appStateNotifier.getRedirectLocation();
            appStateNotifier.clearRedirectLocation();
            return redirectLocation;
          }

          if (requireAuth && !appStateNotifier.loggedIn) {
            appStateNotifier.setRedirectLocationIfUnset(state.uri.toString());
            return '/authentification';
          }
          return null;
        },
        pageBuilder: (context, state) {
          fixStatusBarOniOS16AndBelow(context);
          final ffParams = FFParameters(state, asyncParams);
          final page = ffParams.hasFutures
              ? FutureBuilder(
                  future: ffParams.completeFutures(),
                  builder: (context, _) => builder(context, ffParams),
                )
              : builder(context, ffParams);
          final child = appStateNotifier.loading
              ? Container(
                  color: const Color(0xFF062248),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF8A2BE2),
                    ),
                  ),
                )
              : page;

          final transitionInfo = state.transitionInfo;
          return transitionInfo.hasTransition
              ? CustomTransitionPage(
                  key: state.pageKey,
                  child: child,
                  transitionDuration: transitionInfo.duration,
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) =>
                          PageTransition(
                    type: transitionInfo.transitionType,
                    duration: transitionInfo.duration,
                    reverseDuration: transitionInfo.duration,
                    alignment: transitionInfo.alignment,
                    child: child,
                  ).buildTransitions(
                    context,
                    animation,
                    secondaryAnimation,
                    child,
                  ),
                )
              : MaterialPage(key: state.pageKey, child: child);
        },
        routes: routes,
      );
}

class TransitionInfo {
  const TransitionInfo({
    required this.hasTransition,
    this.transitionType = PageTransitionType.fade,
    this.duration = const Duration(milliseconds: 300),
    this.alignment,
  });

  final bool hasTransition;
  final PageTransitionType transitionType;
  final Duration duration;
  final Alignment? alignment;

  static TransitionInfo appDefault() => TransitionInfo(hasTransition: false);
}

class RootPageContext {
  const RootPageContext(this.isRootPage, [this.errorRoute]);
  final bool isRootPage;
  final String? errorRoute;

  static bool isInactiveRootPage(BuildContext context) {
    final rootPageContext = context.read<RootPageContext?>();
    final isRootPage = rootPageContext?.isRootPage ?? false;
    final location = GoRouterState.of(context).uri.toString();
    return isRootPage &&
        location != '/' &&
        location != rootPageContext?.errorRoute;
  }

  static Widget wrap(Widget child, {String? errorRoute}) => Provider.value(
        value: RootPageContext(true, errorRoute),
        child: child,
      );
}

extension GoRouterLocationExtension on GoRouter {
  String getCurrentLocation() {
    final RouteMatch lastMatch = routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }
}

class RootSplashWidget extends StatefulWidget {
  const RootSplashWidget({Key? key}) : super(key: key);

  @override
  State<RootSplashWidget> createState() => _RootSplashWidgetState();
}

class _RootSplashWidgetState extends State<RootSplashWidget> {
  String _status = "Initialisation...";

  @override
  void initState() {
    super.initState();
    _resolveRoute();
  }

  Future<void> _resolveRoute() async {
    try {
      safeSetState(() => _status = "[1] Détermination...");
      final route = await _determineInitialRoute();
      
      safeSetState(() => _status = "[2] Route = $route. Pause 500ms...");
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        safeSetState(() => _status = "[3] Avant context.go()");
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          // Attempting navigation. If GoRouter is deadlocking, it will show [3]. 
          // If GoRouter succeeds but the destination deadlocks, it will briefly show [4] or be completely replaced by the destination frame.
          safeSetState(() => _status = "[4] Exécution context.go($route)...");
          
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              try {
                context.go(route);
                
                // If context.go returns successfully, queue another frame update to prove it executed.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                   if (mounted) {
                     safeSetState(() => _status = "[5] SUCCESS context.go() returned! Waiting for new Page to paint...");
                   }
                });
              } catch (e) {
                safeSetState(() => _status = "[FATAL] Exception dans context.go: $e");
              }
            }
          });
        }
      } else {
        safeSetState(() => _status = "Erreur: Widget démonté avant navigation.");
      }
    } catch (e, stack) {
      if (mounted) {
        safeSetState(() => _status = "CRASH DANS SPLASH: $e\n$stack");
      }
    }
  }

  void safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF062248), // Dark blue from DoronTheme
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/splash_screen.jpeg',
                width: 150,
                height: 150,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(
                color: Color(0xFF8A2BE2), // Violet color
              ),
              const SizedBox(height: 32),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.yellow,
                  fontFamily: 'monospace',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
