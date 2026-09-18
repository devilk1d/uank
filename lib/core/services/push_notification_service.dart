import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/device_token/device_token_repository.dart';
import '../../firebase_options.dart';
import '../config/auth_repository.dart';

/// Top-level background message handler required by firebase_messaging.
/// Must be an entry-point function outside of any class.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // Firebase already initialized or running in isolated background thread
  }
  debugPrint('[PushNotificationService] Background message received: ${message.messageId} | ${message.notification?.title}');
}

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  bool _isInitialized = false;
  String? _cachedFcmToken;
  DeviceTokenRepository? _tokenRepo;
  AuthRepository? _authRepo;

  String? get fcmToken => _cachedFcmToken;
  bool get isInitialized => _isInitialized;

  /// Inisialisasi Firebase Messaging & Daftarkan Token ke Database
  Future<void> init({
    required DeviceTokenRepository tokenRepo,
    required AuthRepository authRepo,
  }) async {
    _tokenRepo = tokenRepo;
    _authRepo = authRepo;

    try {
      // 1. Inisialisasi Firebase Core dengan options eksplisit
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('[PushNotificationService] Firebase initialized successfully with DefaultFirebaseOptions.');

      // 2. Set background messaging handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 3. Request Permission Notifikasi (Khusus Android 13+ & iOS)
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('[PushNotificationService] Notification authorization status: ${settings.authorizationStatus}');

      // 4. Konfigurasi agar banner notifikasi juga bisa muncul saat aplikasi di foreground (iOS/Android)
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 5. Ambil FCM Token
      _cachedFcmToken = await messaging.getToken();
      debugPrint('[PushNotificationService] FCM Token: $_cachedFcmToken');

      // 5. Sinkronisasi token ke Supabase jika user sudah login
      if (_cachedFcmToken != null) {
        await syncTokenWithBackend();
      }

      // 6. Dengarkan pembaruan token (token refresh)
      messaging.onTokenRefresh.listen((newToken) async {
        _cachedFcmToken = newToken;
        debugPrint('[PushNotificationService] FCM Token Refreshed: $newToken');
        await syncTokenWithBackend();
      });

      // 7. Dengarkan perubahan status login untuk sinkronisasi token otomatis
      authRepo.authStateChanges.listen((data) {
        final event = data.event;
        if (event == AuthChangeEvent.signedIn ||
            event == AuthChangeEvent.tokenRefreshed ||
            event == AuthChangeEvent.userUpdated) {
          syncTokenWithBackend();
        }
      });

      // 8. Dengarkan notifikasi saat aplikasi berada di FOREGROUND (sedang dibuka)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[PushNotificationService] Foreground message received:');
        debugPrint(' - Title: ${message.notification?.title}');
        debugPrint(' - Body: ${message.notification?.body}');
        debugPrint(' - Data: ${message.data}');
        // Notifikasi foreground dapat ditangkap oleh in-app notification banner atau local toast
      });

      // 9. Tangani event saat notifikasi di-klik saat aplikasi di BACKGROUND
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[PushNotificationService] User tapped notification from background: ${message.data}');
        _handleNotificationRouting(message.data);
      });

      // 10. Tangani event saat notifikasi di-klik saat aplikasi TERMINATED (ditutup total)
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('[PushNotificationService] User opened app from terminated state via notification: ${initialMessage.data}');
        _handleNotificationRouting(initialMessage.data);
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('[PushNotificationService] Push notification setup note: $e');
    }
  }

  /// Sinkronkan FCM token ke database Supabase (tabel `device_tokens`)
  Future<void> syncTokenWithBackend() async {
    final token = _cachedFcmToken;
    final repo = _tokenRepo;
    final auth = _authRepo;

    if (token == null || repo == null || auth == null) return;
    if (!auth.isLoggedIn) {
      debugPrint('[PushNotificationService] User is not logged in yet. FCM Token will be registered to Supabase as soon as user logs in.');
      return;
    }

    try {
      // Pastikan session auth segar sebelum melakukan query database
      await auth.refreshSessionIfNeeded();

      final platform = kIsWeb
          ? 'web'
          : (Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'web'));

      await repo.registerToken(
        fcmToken: token,
        platform: platform,
      );
      debugPrint('[PushNotificationService] Token successfully registered to Supabase device_tokens.');
    } catch (e) {
      debugPrint('[PushNotificationService] Failed to register FCM token to Supabase: $e');
    }
  }

  /// Hapus token dari backend saat user Sign Out / Logout
  Future<void> removeCurrentToken() async {
    final token = _cachedFcmToken;
    final repo = _tokenRepo;

    if (token == null || repo == null) return;

    try {
      await repo.removeToken(token);
      debugPrint('[PushNotificationService] Token successfully removed from Supabase device_tokens on logout.');
    } catch (e) {
      debugPrint('[PushNotificationService] Failed to remove FCM token: $e');
    }
  }

  /// Routing navigasi berdasarkan data payload notifikasi
  void _handleNotificationRouting(Map<String, dynamic> data) {
    final targetScreen = data['screen'] ?? data['type'];
    debugPrint('[PushNotificationService] Target routing payload: $targetScreen');
    // Payload bisa mengarahkan ke 'bills', 'notifications', 'rates', dsb.
  }
}
