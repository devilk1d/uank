import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/supabase_client.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'presentation/auth/widgets/auth_gate.dart';
import 'presentation/repository_providers.dart';
import 'presentation/theme/theme_mode_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSupabase();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('[Main] Firebase.initializeApp note: $e');
  }
  runApp(const ProviderScope(child: UankApp()));
}

class UankApp extends ConsumerStatefulWidget {
  const UankApp({super.key});

  @override
  ConsumerState<UankApp> createState() => _UankAppState();
}

class _UankAppState extends ConsumerState<UankApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Preemptively ensure session freshness on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authRepositoryProvider).refreshSessionIfNeeded();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Whenever user re-opens or unlocks the app, silently refresh session if near expiry
      ref.read(authRepositoryProvider).refreshSessionIfNeeded();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('lib/core/image/uanktext3.png'), context);
    precacheImage(const AssetImage('lib/core/image/phone1.png'), context);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final themeMode = ref.watch(appThemeModeProvider);
        return MaterialApp(
          title: 'uank',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          themeAnimationDuration: const Duration(milliseconds: 250),
          themeAnimationCurve: Curves.easeInOut,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: child,
        );
      },
      child: const AuthGate(),
    );
  }
}