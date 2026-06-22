import 'package:flutter/foundation.dart';

/// Logger simple et structuré pour l'application DORÕN
/// Remplace les print() pour une meilleure gestion des logs
class AppLogger {
  static const String _appName = 'DORÕN';

  /// Active/désactive les logs en production
  static bool get _isEnabled => kDebugMode;

  /// Log de niveau INFO (🔵)
  static void info(String message, [String? tag]) {
    if (!_isEnabled) return;
    final tagStr = tag != null ✨ '[$tag] ' : '';
    debugPrint('🔵 $_appName $tagStr$message');
  }

  /// Log de niveau SUCCESS (✅)
  static void success(String message, [String? tag]) {
    if (!_isEnabled) return;
    final tagStr = tag != null ✨ '[$tag] ' : '';
    debugPrint('✅ $_appName $tagStr$message');
  }

  /// Log de niveau WARNING (⚠️)
  static void warning(String message, [String? tag]) {
    if (!_isEnabled) return;
    final tagStr = tag != null ✨ '[$tag] ' : '';
    debugPrint('⚠️ $_appName $tagStr$message');
  }

  /// Log de niveau ERROR (❌)
  static void error(String message, [String? tag, dynamic error, StackTrace? stackTrace]) {
    if (!_isEnabled) return;
    final tagStr = tag != null ✨ '[$tag] ' : '';
    debugPrint('❌ $_appName $tagStr$message');
    if (error != null) {
      debugPrint('   Error: $error');
    }
    if (stackTrace != null) {
      debugPrint('   Stack: ${stackTrace.toString().split('\n').take(5).join('\n   ')}');
    }
  }

  /// Log de niveau DEBUG (🔍)
  static void debug(String message, [String? tag]) {
    if (!_isEnabled) return;
    final tagStr = tag != null ✨ '[$tag] ' : '';
    debugPrint('🔍 $_appName $tagStr$message');
  }

  /// Log pour Firebase operations (🔥)
  static void firebase(String message, [String? tag]) {
    if (!_isEnabled) return;
    final tagStr = tag != null ✨ '[$tag] ' : '';
    debugPrint('🔥 $_appName $tagStr$message');
  }

  /// Log pour API calls (🌐)
  static void api(String message, [String? tag]) {
    if (!_isEnabled) return;
    final tagStr = tag != null ✨ '[$tag] ' : '';
    debugPrint('🌐 $_appName $tagStr$message');
  }
}
