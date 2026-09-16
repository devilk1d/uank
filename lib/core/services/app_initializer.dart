import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../presentation/repository_providers.dart';
import 'push_notification_service.dart';

/// Coordinator provider that orchestrates critical startup hydration:
/// 1. Minimum perceptual display window (1.2s) to prevent visual flash/jitter.
/// 2. Silent Supabase session verification & token refresh.
/// 3. Pre-warming critical Google Fonts (Plus Jakarta Sans).
/// 4. Push Notification initialization & token sync.
/// 5. Hard fail-safe timeout (3.5s) to guarantee the app never freezes.
final appInitializerProvider = FutureProvider<void>((ref) async {
  final authRepo = ref.read(authRepositoryProvider);
  final tokenRepo = ref.read(deviceTokenRepositoryProvider);

  // Initialize push notification service asynchronously
  unawaited(PushNotificationService.instance.init(
    tokenRepo: tokenRepo,
    authRepo: authRepo,
  ));

  await Future.wait([
    // 1. Minimum perceptual display duration (1.2 seconds)
    Future.delayed(const Duration(milliseconds: 1200)),

    // 2. Auth session verification & token refresh
    _hydrateAuthSession(authRepo),

    // 3. Pre-warm Google Fonts
    GoogleFonts.pendingFonts([
      GoogleFonts.plusJakartaSans(),
    ]),
  ]).timeout(
    const Duration(milliseconds: 3500),
    onTimeout: () {
      debugPrint('[AppInitializer] Startup timeout reached. Proceeding with fallback UI.');
      return [null, null, null];
    },
  );
});

Future<void> _hydrateAuthSession(dynamic authRepo) async {
  try {
    await authRepo.refreshSessionIfNeeded();
  } catch (e) {
    debugPrint('[AppInitializer] Session hydration warning: $e');
  }
}
