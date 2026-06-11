// Firebase Cloud Messaging client service.
//
// PRODUCTION SETUP REQUIRED:
//   1. Add to pubspec.yaml: firebase_core, firebase_messaging
//   2. Android: place google-services.json in android/app/
//   3. iOS: place GoogleService-Info.plist in ios/Runner/ + enable Push capability
//   4. Call NotificationService.init() in main() after Firebase.initializeApp()
//
// In this sprint the service is wired up as a no-op stub so the app compiles
// and runs without Firebase credentials. Replace the body of each method with
// the firebase_messaging implementation once credentials are obtained.

import 'package:flutter/foundation.dart';
import 'customer_service.dart';
import 'auth_service.dart';

class NotificationService {
  NotificationService._();

  static bool _initialized = false;

  /// Call once from main() after AuthService.init().
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    // TODO: Uncomment when firebase_core + firebase_messaging are added:
    //
    // await Firebase.initializeApp();
    // final messaging = FirebaseMessaging.instance;
    // await messaging.requestPermission(alert: true, badge: true, sound: true);
    // final token = await messaging.getToken();
    // if (token != null) await _saveToken(token);
    // messaging.onTokenRefresh.listen(_saveToken);
    //
    // FirebaseMessaging.onMessage.listen(_handleForeground);
    // FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

    debugPrint('[NotificationService] stub — Firebase not yet configured');
  }

  static Future<void> _saveToken(String token) async {
    try {
      if (AuthService.isLoggedIn) {
        await CustomerService.saveFcmToken(token);
      }
    } catch (e) {
      debugPrint('[NotificationService] token save failed: $e');
    }
  }

  // Handles a foreground FCM message (show local notification or in-app banner).
  // static void _handleForeground(RemoteMessage message) {
  //   debugPrint('[NotificationService] foreground: ${message.notification?.title}');
  // }

  // Handles tap on a notification while app is in background/terminated.
  // static void _handleTap(RemoteMessage message) {
  //   final orderId = message.data['order_id'];
  //   if (orderId != null) {
  //     // Navigate to order detail — requires a global navigator key.
  //   }
  // }
}
