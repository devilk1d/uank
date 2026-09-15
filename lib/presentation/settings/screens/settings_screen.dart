import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_background.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_card.dart';
import '../../categories/screens/categories_screen.dart';
import '../../repository_providers.dart';
import '../../theme/theme_mode_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(appThemeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final authRepo = ref.read(authRepositoryProvider);
    final canPop = Navigator.canPop(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'Settings & Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.darkTextPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
            children: [
              // User Profile Info Card
              GlassCard(
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                        border: Border.all(color: AppColors.primaryLight, width: 1.5),
                      ),
                      child: const Center(
                        child: Text(
                          'U',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'User Account',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkTextPrimary),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            authRepo.currentUserId != null
                                ? 'ID: ${authRepo.currentUserId!.substring(0, 8)}...'
                                : 'Guest',
                            style: const TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Preferences Section
              const Text(
                'Preferences',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkTextSecondary),
              ),
              const SizedBox(height: 10),

              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    // Categories Manager
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.category_outlined, color: AppColors.teal),
                      title: const Text(
                        'Manage Categories',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.darkTextSecondary),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                        );
                      },
                    ),
                    const Divider(color: AppColors.darkCardBorder),

                    // Theme Switcher
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                        color: AppColors.primaryLight,
                      ),
                      title: const Text(
                        'Dark Mode',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary),
                      ),
                      trailing: Switch(
                        value: isDark,
                        activeThumbColor: Colors.black,
                        activeTrackColor: AppColors.primary,
                        onChanged: (_) => ref.read(appThemeModeProvider.notifier).toggle(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Account & App
              const Text(
                'Account & App',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkTextSecondary),
              ),
              const SizedBox(height: 10),

              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.info_outline_rounded, color: AppColors.blue),
                      title: const Text(
                        'App Version',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary),
                      ),
                      trailing: const Text(
                        'v1.0.0+1',
                        style: TextStyle(fontSize: 13, color: AppColors.darkTextSecondary),
                      ),
                    ),
                    const Divider(color: AppColors.darkCardBorder),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.logout_rounded, color: AppColors.red),
                      title: const Text(
                        'Log Out',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.red),
                      ),
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: AppColors.darkCardBg,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            title: const Text('Confirm Log Out', style: TextStyle(color: Colors.white, fontSize: 16)),
                            content: const Text('Are you sure you want to log out of your account?', style: TextStyle(color: AppColors.darkTextSecondary)),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, foregroundColor: Colors.white),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Log Out'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await authRepo.signOut();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
