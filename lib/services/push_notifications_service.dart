import 'dart:convert';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '/utils/app_logger.dart';

// Top-level function for handling background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  AppLogger.debug('Handling a background message: ${message.messageId}', 'PushNotificationsService');
}

class PushNotificationsService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final StreamController<String> onNotificationClick = StreamController<String>.broadcast();
  static String? pendingChatRoute;

  /// Initialize Firebase Messaging
  static Future<void> initialize() async {
    try {
      // 1. Request permissions for iOS and Android 13+
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        AppLogger.debug('User granted notification permission', 'PushNotificationsService');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        AppLogger.debug('User granted provisional notification permission', 'PushNotificationsService');
      } else {
        AppLogger.debug('User declined or has not accepted permission', 'PushNotificationsService');
      }

      // 2. Register background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        AppLogger.debug('Received foreground message: ${message.notification?.title}', 'PushNotificationsService');
        // You could show a local notification or custom Snackbar here if needed
      });

      // 4. Handle when a user taps a notification and the app is in background but opened
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        AppLogger.debug('Message opened from background: ${message.data}', 'PushNotificationsService');
        _handleNotificationInteraction(message);
      });

      // 5. Handle when the app is completely terminated and opened via notification
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        AppLogger.debug('Message opened from terminated state: ${initialMessage.data}', 'PushNotificationsService');
        _handleNotificationInteraction(initialMessage);
      }

    } catch (e) {
      AppLogger.error('Failed to initialize push notifications', 'PushNotificationsService', e);
    }
  }

  /// Update the FCM token in the user's Firestore document
  static Future<void> updateFCMToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final token = await _firebaseMessaging.getToken();
      if (token == null) return;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {'fcmToken': token}, 
        SetOptions(merge: true)
      );
      
      AppLogger.debug('FCM Token updated successfully', 'PushNotificationsService');

      // Listen for token refreshes
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        FirebaseFirestore.instance.collection('users').doc(user.uid).set(
          {'fcmToken': newToken},
          SetOptions(merge: true)
        );
      });
      
    } catch (e) {
      AppLogger.error('Failed to update FCM token', 'PushNotificationsService', e);
    }
  }

  /// Handle routing if a notification contains deep linking data
  static void _handleNotificationInteraction(RemoteMessage message) {
    // Ex: Navigate to a chat room if the payload contains `chatId`
    if (message.data.containsKey('chatId')) {
      final chatId = message.data['chatId'];
      pendingChatRoute = chatId;
      onNotificationClick.add(chatId);
      AppLogger.debug('Should navigate to chat: $chatId', 'PushNotificationsService');
    }
  }
}
