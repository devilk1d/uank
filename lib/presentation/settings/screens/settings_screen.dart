import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_background.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_card.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_confirmation_sheet.dart';
import '../../auth/providers/auth_providers.dart';
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
    final userProfile = ref.watch(userProfileProvider);

    final displayName = userProfile?.displayName ?? 'User Account';
    final email = userProfile?.email ?? 'user@uank.app';
    final initialLetter = userProfile?.initialLetter ?? 'U';
    final avatarUrl = userProfile?.avatarUrl;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
            children: [
              // Header with Title & Back Button (Consistent with other screens)
              _buildHeader(context),
              const SizedBox(height: 20),

              // 1. HERO PROFILE CARD (Clean & Simple)
              GlassCard(
                borderRadius: 24,
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Clean Avatar without Camera Badge
                    AppAvatar(
                      avatarUrl: avatarUrl,
                      initialLetter: initialLetter,
                      size: 60,
                      showEditBadge: false,
                      onTap: () => _showAvatarPickerSheet(context, ref, userProfile),
                    ),
                    const SizedBox(width: 16),

                    // Display Name, Email & Edit Profile Button
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                    color: context.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => _showEditProfileSheet(context, ref, displayName),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    Icons.edit_rounded,
                                    size: 13,
                                    color: context.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.alternate_email_rounded,
                                size: 13,
                                color: context.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: context.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. FINANCIAL / CATEGORIES MANAGEMENT SECTION
              _buildSectionTitle(context, 'CATEGORIES'),
              const SizedBox(height: 8),
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: _SettingsItemTile(
                  icon: Icons.category_rounded,
                  iconColor: AppColors.teal,
                  title: 'Manage Categories',
                  subtitle: 'Custom income & expense categories',
                  trailing: Icon(Icons.chevron_right_rounded, color: context.textSecondary),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // 3. PREFERENCES & SYSTEM (Theme)
              _buildSectionTitle(context, 'PREFERENCES & APPEARANCE'),
              const SizedBox(height: 8),
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: _SettingsItemTile(
                  icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  iconColor: AppColors.yellow,
                  title: 'Dark Mode',
                  subtitle: isDark ? 'Deep Obsidian & Neon Lime' : 'Clean Light Surface',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(appThemeModeProvider.notifier).toggle();
                  },
                  trailing: _SmoothThemeSwitch(
                    isDark: isDark,
                    onChanged: (_) {
                      HapticFeedback.selectionClick();
                      ref.read(appThemeModeProvider.notifier).toggle();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 4. SECURITY & SESSION (Change Password & Logout)
              _buildSectionTitle(context, 'SECURITY & SESSION'),
              const SizedBox(height: 8),
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Column(
                  children: [
                    _SettingsItemTile(
                      icon: Icons.lock_reset_rounded,
                      iconColor: AppColors.orange,
                      title: 'Change Password',
                      subtitle: 'Update account login credentials',
                      trailing: Icon(Icons.chevron_right_rounded, color: context.textSecondary),
                      onTap: () => _showChangePasswordSheet(context, ref),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      height: 1,
                      color: context.cardBorder,
                    ),
                    _SettingsItemTile(
                      icon: Icons.logout_rounded,
                      iconColor: AppColors.red,
                      title: 'Log Out',
                      subtitle: 'Sign out from this device',
                      titleColor: AppColors.red,
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.red),
                      onTap: () async {
                        final confirm = await AppConfirmationSheet.show(
                          context,
                          title: 'Log Out',
                          message: 'Are you sure you want to log out of your account? You will need to sign in again to access your financial data.',
                          confirmLabel: 'Log Out',
                          icon: Icons.logout_rounded,
                          isDestructive: true,
                        );

                        if (confirm == true) {
                          if (context.mounted) {
                            Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
                          }
                          await authRepo.signOut();
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 5. BRANDED FOOTER WITH UANK LOGO
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'lib/core/image/logo uank.png',
                      height: 48,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.12),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                        ),
                        child: const Center(
                          child: Text(
                            'U',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'UANK - Personal Finance',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'v1.0.0',
                      style: TextStyle(
                        fontSize: 11,
                        color: context.textMuted,
                      ),
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

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          color: context.textSecondary,
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        if (Navigator.canPop(context)) ...[
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.cardBg,
                border: Border.all(color: context.cardBorder),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: context.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 14),
        ],
        Text(
          'Settings & Profile',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: context.textPrimary,
          ),
        ),
      ],
    );
  }

  void _showAvatarPickerSheet(BuildContext context, WidgetRef ref, UserProfileData? profile) {
    final picker = ImagePicker();
    bool isUploading = false;
    final isDark = context.isDark;
    final cardBg = context.cardBg;
    final cardBorder = context.cardBorder;
    final textPrimary = context.textPrimary;
    final textMuted = context.textMuted;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
          final bottomPadding = MediaQuery.of(ctx).padding.bottom;

          return Container(
            padding: EdgeInsets.fromLTRB(22, 16, 22, 24 + bottomInset + bottomPadding),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                top: BorderSide(color: cardBorder, width: 1.5),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: textMuted.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Header
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (isDark ? AppColors.primary : const Color(0xFF15803D)).withValues(alpha: isDark ? 0.15 : 0.12),
                          border: Border.all(color: (isDark ? AppColors.primary : const Color(0xFF15803D)).withValues(alpha: 0.3)),
                        ),
                        child: Icon(Icons.add_a_photo_rounded, size: 20, color: isDark ? AppColors.primaryLight : const Color(0xFF15803D)),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Change Profile Picture',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Photo Actions (Gallery & Camera)
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: isUploading
                              ? null
                              : () async {
                                  try {
                                    final XFile? file = await picker.pickImage(
                                      source: ImageSource.gallery,
                                      maxWidth: 512,
                                      maxHeight: 512,
                                      imageQuality: 85,
                                    );
                                    if (file == null) return;

                                    setSheetState(() => isUploading = true);
                                    final bytes = await file.readAsBytes();
                                    final ext = file.name.split('.').last.toLowerCase();
                                    final validExt = (ext == 'png' || ext == 'jpg' || ext == 'jpeg') ? ext : 'jpg';

                                    await ref.read(userProfileProvider.notifier).uploadAndSetAvatar(
                                      bytes: bytes,
                                      extension: validExt,
                                    );

                                    if (ctx.mounted) Navigator.pop(ctx);
                                  } catch (e) {
                                    setSheetState(() => isUploading = false);
                                  }
                                },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: (isDark ? AppColors.primary : const Color(0xFF15803D)).withValues(alpha: isDark ? 0.12 : 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: (isDark ? AppColors.primary : const Color(0xFF15803D)).withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.photo_library_rounded, color: isDark ? AppColors.primaryLight : const Color(0xFF15803D), size: 26),
                                const SizedBox(height: 8),
                                Text(
                                  'Choose Gallery',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.primaryLight : const Color(0xFF15803D),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: isUploading
                              ? null
                              : () async {
                                  try {
                                    final XFile? file = await picker.pickImage(
                                      source: ImageSource.camera,
                                      maxWidth: 512,
                                      maxHeight: 512,
                                      imageQuality: 85,
                                    );
                                    if (file == null) return;

                                    setSheetState(() => isUploading = true);
                                    final bytes = await file.readAsBytes();
                                    final ext = file.name.split('.').last.toLowerCase();
                                    final validExt = (ext == 'png' || ext == 'jpg' || ext == 'jpeg') ? ext : 'jpg';

                                    await ref.read(userProfileProvider.notifier).uploadAndSetAvatar(
                                      bytes: bytes,
                                      extension: validExt,
                                    );

                                    if (ctx.mounted) Navigator.pop(ctx);
                                  } catch (e) {
                                    setSheetState(() => isUploading = false);
                                  }
                                },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: cardBorder),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.camera_alt_rounded, color: textPrimary, size: 26),
                                const SizedBox(height: 8),
                                Text(
                                  'Take Photo',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Reset / Remove Avatar
                  if (profile?.avatarUrl != null && profile!.avatarUrl!.isNotEmpty) ...[
                    Divider(color: cardBorder, height: 1),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.red, size: 18),
                        label: const Text(
                          'Remove Photo (Reset to Default)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.red,
                          ),
                        ),
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          await ref.read(userProfileProvider.notifier).updateAvatar(null);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showEditProfileSheet(BuildContext context, WidgetRef ref, String currentName) {
    final nameController = TextEditingController(text: currentName);
    bool isSaving = false;
    final isDark = context.isDark;
    final cardBg = context.cardBg;
    final cardBorder = context.cardBorder;
    final textPrimary = context.textPrimary;
    final textSecondary = context.textSecondary;
    final textMuted = context.textMuted;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
          final bottomPadding = MediaQuery.of(ctx).padding.bottom;

          return Container(
            padding: EdgeInsets.fromLTRB(22, 16, 22, 24 + bottomInset + bottomPadding),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                top: BorderSide(color: cardBorder, width: 1.5),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: textMuted.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (isDark ? AppColors.primary : const Color(0xFF15803D)).withValues(alpha: isDark ? 0.15 : 0.12),
                          border: Border.all(color: (isDark ? AppColors.primary : const Color(0xFF15803D)).withValues(alpha: 0.3)),
                        ),
                        child: Icon(Icons.person_rounded, size: 20, color: isDark ? AppColors.primaryLight : const Color(0xFF15803D)),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Edit Profile Name',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    style: TextStyle(color: textPrimary, fontSize: 15),
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      labelStyle: TextStyle(color: textSecondary),
                      filled: true,
                      fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF1F5F9),
                      prefixIcon: Icon(Icons.badge_outlined, color: textSecondary, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              final name = nameController.text.trim();
                              if (name.isEmpty) return;

                              setSheetState(() => isSaving = true);
                              try {
                                await ref.read(userProfileProvider.notifier).updateName(name);
                                if (ctx.mounted) Navigator.pop(ctx);
                              } catch (e) {
                                setSheetState(() => isSaving = false);
                              }
                            },
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showChangePasswordSheet(BuildContext context, WidgetRef ref) {
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isSaving = false;
    bool obscure = true;
    final isDark = context.isDark;
    final cardBg = context.cardBg;
    final cardBorder = context.cardBorder;
    final textPrimary = context.textPrimary;
    final textSecondary = context.textSecondary;
    final textMuted = context.textMuted;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
          final bottomPadding = MediaQuery.of(ctx).padding.bottom;

          return Container(
            padding: EdgeInsets.fromLTRB(22, 16, 22, 24 + bottomInset + bottomPadding),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                top: BorderSide(color: cardBorder, width: 1.5),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: textMuted.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.orange.withValues(alpha: 0.15),
                          border: Border.all(color: AppColors.orange.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.lock_reset_rounded, size: 20, color: AppColors.orange),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Change Password',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: passwordController,
                    obscureText: obscure,
                    style: TextStyle(color: textPrimary, fontSize: 15),
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      labelStyle: TextStyle(color: textSecondary),
                      filled: true,
                      fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF1F5F9),
                      prefixIcon: Icon(Icons.lock_outline_rounded, color: textSecondary, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: textSecondary,
                          size: 20,
                        ),
                        onPressed: () => setSheetState(() => obscure = !obscure),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: obscure,
                    style: TextStyle(color: textPrimary, fontSize: 15),
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      labelStyle: TextStyle(color: textSecondary),
                      filled: true,
                      fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF1F5F9),
                      prefixIcon: Icon(Icons.lock_outline_rounded, color: textSecondary, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              final pass = passwordController.text;
                              final confirmPass = confirmPasswordController.text;
                              if (pass.length < 6 || pass != confirmPass) {
                                return;
                              }

                              setSheetState(() => isSaving = true);
                              try {
                                await ref.read(authRepositoryProvider).updatePassword(pass);
                                if (ctx.mounted) Navigator.pop(ctx);
                              } catch (e) {
                                setSheetState(() => isSaving = false);
                              }
                            },
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Text(
                              'Update Password',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SettingsItemTile extends StatelessWidget {
  const _SettingsItemTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.titleColor,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      splashColor: iconColor.withValues(alpha: 0.08),
      highlightColor: iconColor.withValues(alpha: 0.04),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            // Squircle Icon Badge
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: iconColor.withValues(alpha: 0.28),
                  width: 1,
                ),
              ),
              child: Icon(icon, size: 19, color: iconColor),
            ),
            const SizedBox(width: 14),

            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: titleColor ?? context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Trailing Widget
            if (trailing != null) ...[
              const SizedBox(width: 10),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class _SmoothThemeSwitch extends StatelessWidget {
  const _SmoothThemeSwitch({
    required this.isDark,
    required this.onChanged,
  });

  final bool isDark;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: () => onChanged(!isDark),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.fastOutSlowIn,
          width: 50,
          height: 28,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isDark ? AppColors.primary : const Color(0xFFE2E8F0),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.fastOutSlowIn,
            alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? Colors.black : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                  size: 12,
                  color: isDark ? AppColors.primary : const Color(0xFFF59E0B),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

