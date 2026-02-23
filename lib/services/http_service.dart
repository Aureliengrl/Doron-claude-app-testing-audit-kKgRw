import '/utils/app_logger.dart';
import 'dart:async';
import 'package:http/http.dart' as http;

/// Service pour gérer les appels HTTP avec retry logic et timeout
class HttpService {
  static const int defaultTimeoutSeconds = 30;
  static const int defaultMaxRetries = 3;
  static const List<int> retryDelaysSeconds = [2, 4, 8]; // Exponential backoff

  /// Effectue un POST avec retry logic et timeout
  static Future<http.Response> postWithRetry({
    required Uri url,
    required Map<String, String> headers,
    required String body,
    int timeoutSeconds = defaultTimeoutSeconds,
    int maxRetries = defaultMaxRetries,
  }) async {
    int attempt = 0;
    Exception? lastException;

    while (attempt < maxRetries) {
      try {
        AppLogger.debug('📤 HTTP POST attempt ${attempt + 1}/$maxRetries to ${url.host}', 'Debug');

        final response = await http
            .post(
              url,
              headers: headers,
              body: body,
            )
            .timeout(
              Duration(seconds: timeoutSeconds),
              onTimeout: () {
                throw TimeoutException('Request timeout after $timeoutSeconds seconds');
              },
            );

        // Success - return response
        if (response.statusCode >= 200 && response.statusCode < 300) {
          AppLogger.debug('✅ HTTP POST successful (${response.statusCode})', 'Debug');
          return response;
        }

        // Server error (5xx) - retry
        if (response.statusCode >= 500) {
          AppLogger.debug('⚠️ Server error (${response.statusCode}), will retry...', 'Debug');
          lastException = Exception('Server error: ${response.statusCode}');
        } else {
          // Client error (4xx) - don't retry, return immediately
          AppLogger.debug('❌ Client error (${response.statusCode}), not retrying', 'Debug');
          return response;
        }
      } on TimeoutException catch (e) {
        AppLogger.debug('⏱️ Timeout on attempt ${attempt + 1}: $e', 'Debug');
        lastException = e;
      } on Exception catch (e) {
        AppLogger.debug('❌ Error on attempt ${attempt + 1}: $e', 'Debug');
        lastException = e;
      }

      // Increment attempt
      attempt++;

      // Wait before retry (exponential backoff)
      if (attempt < maxRetries) {
        final delaySeconds = retryDelaysSeconds[attempt - 1];
        AppLogger.debug('⏳ Waiting ${delaySeconds}s before retry...', 'Debug');
        await Future.delayed(Duration(seconds: delaySeconds));
      }
    }

    // All retries failed
    AppLogger.debug('❌ All $maxRetries attempts failed', 'Debug');
    throw lastException ?? Exception('Request failed after $maxRetries attempts');
  }

  /// Effectue un GET avec retry logic et timeout
  static Future<http.Response> getWithRetry({
    required Uri url,
    Map<String, String>? headers,
    int timeoutSeconds = defaultTimeoutSeconds,
    int maxRetries = defaultMaxRetries,
  }) async {
    int attempt = 0;
    Exception? lastException;

    while (attempt < maxRetries) {
      try {
        AppLogger.debug('📤 HTTP GET attempt ${attempt + 1}/$maxRetries to ${url.host}', 'Debug');

        final response = await http
            .get(
              url,
              headers: headers,
            )
            .timeout(
              Duration(seconds: timeoutSeconds),
              onTimeout: () {
                throw TimeoutException('Request timeout after $timeoutSeconds seconds');
              },
            );

        // Success
        if (response.statusCode >= 200 && response.statusCode < 300) {
          AppLogger.debug('✅ HTTP GET successful (${response.statusCode})', 'Debug');
          return response;
        }

        // Server error - retry
        if (response.statusCode >= 500) {
          AppLogger.debug('⚠️ Server error (${response.statusCode}), will retry...', 'Debug');
          lastException = Exception('Server error: ${response.statusCode}');
        } else {
          // Client error - don't retry
          AppLogger.debug('❌ Client error (${response.statusCode}), not retrying', 'Debug');
          return response;
        }
      } on TimeoutException catch (e) {
        AppLogger.debug('⏱️ Timeout on attempt ${attempt + 1}: $e', 'Debug');
        lastException = e;
      } on Exception catch (e) {
        AppLogger.debug('❌ Error on attempt ${attempt + 1}: $e', 'Debug');
        lastException = e;
      }

      attempt++;

      if (attempt < maxRetries) {
        final delaySeconds = retryDelaysSeconds[attempt - 1];
        AppLogger.debug('⏳ Waiting ${delaySeconds}s before retry...', 'Debug');
        await Future.delayed(Duration(seconds: delaySeconds));
      }
    }

    AppLogger.debug('❌ All $maxRetries attempts failed', 'Debug');
    throw lastException ?? Exception('Request failed after $maxRetries attempts');
  }
}
