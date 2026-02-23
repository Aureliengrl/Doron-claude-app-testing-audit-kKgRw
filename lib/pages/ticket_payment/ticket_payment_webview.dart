import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '/services/ticket_session_service.dart';
import '/utils/app_logger.dart';

/// WebView sécurisée pour la billetterie LYF PAY
/// - Session temporaire unique
/// - Pas de partage possible
/// - Pas de navigation externe
class TicketPaymentWebView extends StatefulWidget {
  const TicketPaymentWebView({super.key});

  static String routeName = 'TicketPayment';
  static String routePath = '/ticket-payment';

  @override
  State<TicketPaymentWebView> createState() => _TicketPaymentWebViewState();
}

class _TicketPaymentWebViewState extends State<TicketPaymentWebView> {
  late WebViewController _webViewController;
  String? _sessionId;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  double _loadingProgress = 0.0;

  final Color violetColor = const Color(0xFF8A2BE2);
  final Color goldColor = const Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  @override
  void dispose() {
    // Annuler la session si l'utilisateur quitte sans payer
    if (_sessionId != null) {
      TicketSessionService.cancelSession(_sessionId!);
    }
    super.dispose();
  }

  /// Initialise la session de billetterie
  Future<void> _initializeSession() async {
    try {
      // Récupérer l'ID de l'appareil
      final deviceInfo = DeviceInfoPlugin();
      String deviceId;

      if (Theme.of(context).platform == TargetPlatform.android) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
      } else if (Theme.of(context).platform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'unknown';
      } else {
        deviceId = 'web-${DateTime.now().millisecondsSinceEpoch}';
      }

      // Créer la session
      final sessionId = await TicketSessionService.createSession(
        deviceId: deviceId,
        appVersion: '1.0.0', // TODO: Récupérer depuis package_info
      );

      if (sessionId == null) {
        _showError('Impossible de créer une session sécurisée');
        return;
      }

      setState(() {
        _sessionId = sessionId;
      });

      // Initialiser la WebView
      _initializeWebView(sessionId);
    } catch (e) {
      AppLogger.error('Erreur initialisation session billetterie', 'TicketPayment', e);
      _showError('Erreur lors de l\'initialisation');
    }
  }

  /// Initialise la WebView avec la session
  void _initializeWebView(String sessionId) {
    final url = TicketSessionService.generateLyfPayUrl(sessionId);

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            setState(() {
              _loadingProgress = progress / 100;
            });
          },
          onPageStarted: (url) {
            AppLogger.info('Page démarrée: $url', 'TicketPayment');
          },
          onPageFinished: (url) {
            setState(() {
              _isLoading = false;
            });
            AppLogger.info('Page chargée: $url', 'TicketPayment');
          },
          onWebResourceError: (error) {
            AppLogger.error('Erreur WebView', 'TicketPayment', error.description);
            _showError('Erreur de chargement');
          },
          onNavigationRequest: (request) {
            final url = request.url;

            // Intercepter les callbacks LYF PAY
            if (TicketSessionService.isValidCallbackUrl(url)) {
              _handleCallback(url);
              return NavigationDecision.prevent;
            }

            // Bloquer la navigation externe
            if (!url.contains('lyf.eu') && !url.contains('doron')) {
              AppLogger.warning('Navigation externe bloquée: $url', 'TicketPayment');
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  /// Gère le callback de LYF PAY
  Future<void> _handleCallback(String url) async {
    final sessionId = TicketSessionService.extractSessionIdFromCallback(url);

    if (sessionId == null || sessionId != _sessionId) {
      AppLogger.error('Session ID invalide dans callback', 'TicketPayment', null);
      _showError('Session invalide');
      return;
    }

    // Vérifier que la session est toujours valide
    final isValid = await TicketSessionService.isSessionValid(sessionId);
    if (!isValid) {
      _showError('Session expirée');
      return;
    }

    if (url.contains('ticket-success')) {
      // Paiement réussi
      await TicketSessionService.completeSession(sessionId);
      if (mounted) {
        context.go('/ticket-success?session=$sessionId');
      }
    } else if (url.contains('ticket-cancelled')) {
      // Paiement annulé
      await TicketSessionService.cancelSession(sessionId);
      if (mounted) {
        context.go('/gala-ticket');
      }
    }
  }

  void _showError(String message) {
    setState(() {
      _hasError = true;
      _errorMessage = message;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Confirmation avant de quitter
        final shouldPop = await _showExitConfirmation();
        if (shouldPop && _sessionId != null) {
          await TicketSessionService.cancelSession(_sessionId!);
        }
        return shouldPop;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: violetColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () async {
              final shouldPop = await _showExitConfirmation();
              if (shouldPop && mounted) {
                if (_sessionId != null) {
                  await TicketSessionService.cancelSession(_sessionId!);
                }
                context.go('/gala-ticket');
              }
            },
          ),
          title: Row(
            children: [
              const Icon(Icons.lock, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Paiement sécurisé',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        body: Stack(
          children: [
            // WebView
            if (!_hasError && _sessionId != null)
              WebViewWidget(controller: _webViewController),

            // Erreur
            if (_hasError)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 80,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () => context.go('/gala-ticket'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: violetColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Retour',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Loading indicator
            if (_isLoading)
              Container(
                color: Colors.white,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [violetColor, goldColor],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Chargement sécurisé...',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: 200,
                        child: LinearProgressIndicator(
                          value: _loadingProgress,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(violetColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Bandeau de sécurité en bas
            if (!_hasError && !_isLoading)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: goldColor.withOpacity(0.1),
                    border: Border(
                      top: BorderSide(
                        color: goldColor.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified_user,
                        color: goldColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Paiement 100% sécurisé par LYF PAY',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showExitConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Quitter le paiement ?',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir quitter ? Votre paiement ne sera pas finalisé.',
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: const Color(0xFF6B7280),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Continuer le paiement',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: violetColor,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Quitter',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    ) ?? false;
  }
}
