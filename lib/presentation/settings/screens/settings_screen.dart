import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_background.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_card.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_confirmation_sheet.dart';
import '../../../core/widgets/legal_document_sheet.dart';
import '../../../core/utils/password_validator.dart';
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
                                  style: GoogleFonts.plusJakartaSans(
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
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
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
                                  style: GoogleFonts.plusJakartaSans(
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
                  iconColor: isDark ? Colors.white : const Color(0xFF0F172A),
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
                  iconColor: isDark ? Colors.white : const Color(0xFF0F172A),
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
                      iconColor: isDark ? Colors.white : const Color(0xFF0F172A),
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
                          await ref.read(authRepositoryProvider).signOut();
                        }
                      },
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      height: 1,
                      color: context.cardBorder,
                    ),
                    _SettingsItemTile(
                      icon: Icons.delete_forever_rounded,
                      iconColor: AppColors.red,
                      title: 'Delete Account',
                      subtitle: 'Permanently delete your account and all data',
                      titleColor: AppColors.red,
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.red),
                      onTap: () => _showDeleteAccountSheet(context, ref),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 5. LEGAL & POLICIES SECTION
              _buildSectionTitle(context, 'LEGAL & POLICIES'),
              const SizedBox(height: 8),
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Column(
                  children: [
                    _SettingsItemTile(
                      icon: Icons.verified_user_outlined,
                      iconColor: isDark ? Colors.white : const Color(0xFF0F172A),
                      title: 'Privacy Policy',
                      subtitle: 'How we protect and encrypt your data',
                      trailing: Icon(Icons.chevron_right_rounded, color: context.textSecondary),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        LegalDocumentSheet.showPrivacyPolicy(context);
                      },
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      height: 1,
                      color: context.cardBorder,
                    ),
                    _SettingsItemTile(
                      icon: Icons.description_outlined,
                      iconColor: isDark ? Colors.white : const Color(0xFF0F172A),
                      title: 'Terms of Service',
                      subtitle: 'Terms of use and service agreements',
                      trailing: Icon(Icons.chevron_right_rounded, color: context.textSecondary),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        LegalDocumentSheet.showTermsOfService(context);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 6. BRANDED FOOTER WITH UANK LOGO
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'lib/core/image/uanktext3.png',
                      height: 35,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.12),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                        ),
                        child: Center(
                          child: Text(
                            'U',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'v1.0.0',
                      style: GoogleFonts.plusJakartaSans(
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
        style: GoogleFonts.plusJakartaSans(
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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
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
                        style: GoogleFonts.plusJakartaSans(
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
                                  style: GoogleFonts.plusJakartaSans(
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
                                  style: GoogleFonts.plusJakartaSans(
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
                        label: Text(
                          'Remove Photo (Reset to Default)',
                          style: GoogleFonts.plusJakartaSans(
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
                        style: GoogleFonts.plusJakartaSans(
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
                    style: GoogleFonts.plusJakartaSans(color: textPrimary, fontSize: 15),
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      labelStyle: GoogleFonts.plusJakartaSans(color: textSecondary, fontSize: 13),
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
                          : Text(
                              'Save Changes',
                              style: GoogleFonts.plusJakartaSans(
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
    final userProfile = ref.read(userProfileProvider);
    final email = userProfile?.email ?? '';

    final otpController = TextEditingController();
    final otpFocusNode = FocusNode();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    int step = 1; // 1 = Request, 2 = Verify OTP, 3 = Set New Password
    bool isLoading = false;
    bool obscureNew = true;
    bool obscureConfirm = true;
    String? sheetError;
    Timer? resendTimer;
    int resendCountdown = 60;
    bool canResend = false;

    final isDark = context.isDark;
    final cardBg = context.cardBg;
    final cardBorder = context.cardBorder;
    final textPrimary = context.textPrimary;
    final textSecondary = context.textSecondary;
    final textMuted = context.textMuted;
    final primaryAccent = isDark ? AppColors.primary : const Color(0xFF15803D);

    void startTimer(StateSetter setSheetState) {
      resendTimer?.cancel();
      setSheetState(() {
        resendCountdown = 60;
        canResend = false;
      });
      resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (resendCountdown > 1) {
          setSheetState(() => resendCountdown--);
        } else {
          timer.cancel();
          setSheetState(() => canResend = true);
        }
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
          final bottomPadding = MediaQuery.of(ctx).padding.bottom;

          Future<void> submitVerifyOtp(String code) async {
            if (code.length != 6 || isLoading) return;

            FocusScope.of(ctx).unfocus();
            setSheetState(() {
              isLoading = true;
              sheetError = null;
            });

            try {
              await ref.read(authRepositoryProvider).verifyOtp(
                email: email,
                token: code,
                type: OtpType.recovery,
              );
              if (ctx.mounted) {
                setSheetState(() {
                  isLoading = false;
                  step = 3;
                });
              }
            } catch (e) {
              if (ctx.mounted) {
                setSheetState(() {
                  isLoading = false;
                  sheetError = 'Invalid or expired verification code';
                });
              }
            }
          }

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

                  // STEP 1: Request Email Verification Code
                  if (step == 1) ...[
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
                          child: const Icon(Icons.shield_outlined, size: 20, color: AppColors.orange),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Change Password',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'For your security, we\'ll send a 6-digit verification code to your email address before you can set a new password.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.alternate_email_rounded, size: 18, color: textSecondary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              email,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    if (sheetError != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.red.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.red.withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                sheetError!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppColors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: isLoading
                            ? null
                            : () async {
                                setSheetState(() {
                                  isLoading = true;
                                  sheetError = null;
                                });
                                try {
                                  await ref.read(authRepositoryProvider).resetPasswordForEmail(email);
                                  setSheetState(() {
                                    isLoading = false;
                                    step = 2;
                                  });
                                  startTimer(setSheetState);
                                } catch (e) {
                                  setSheetState(() {
                                    isLoading = false;
                                    sheetError = e.toString().replaceAll('Exception:', '').trim();
                                  });
                                }
                              },
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                              )
                            : Text(
                                'Send Verification Code',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                      ),
                    ),
                  ],

                  // STEP 2: Verify 6-Digit OTP Code
                  if (step == 2) ...[
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (isDark ? AppColors.primary : const Color(0xFF15803D)).withValues(alpha: 0.15),
                            border: Border.all(color: (isDark ? AppColors.primary : const Color(0xFF15803D)).withValues(alpha: 0.3)),
                          ),
                          child: Icon(Icons.pin_outlined, size: 20, color: isDark ? AppColors.primaryLight : const Color(0xFF15803D)),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Verification Code',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text.rich(
                      TextSpan(
                        text: 'Enter the 6-digit code sent to ',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                        ),
                        children: [
                          TextSpan(
                            text: email,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (sheetError != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.red.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.red.withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                sheetError!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppColors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 6-BOX OTP INPUT
                    Stack(
                      children: [
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0.0,
                            child: TextField(
                              controller: otpController,
                              focusNode: otpFocusNode,
                              autofocus: true,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                              ],
                              onChanged: (val) {
                                setSheetState(() {});
                                if (val.length == 6) {
                                  submitVerifyOtp(val.trim());
                                }
                              },
                            ),
                          ),
                        ),

                        GestureDetector(
                          onTap: () => otpFocusNode.requestFocus(),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(6, (index) {
                              final otpText = otpController.text;
                              final char = index < otpText.length ? otpText[index] : '';
                              final isCurrent = index == otpText.length;
                              final isFilled = index < otpText.length;

                              return Container(
                                width: 46,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1B1B22) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isCurrent
                                        ? primaryAccent
                                        : isFilled
                                            ? (isDark ? Colors.white.withValues(alpha: 0.3) : const Color(0xFF94A3B8))
                                            : (isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0)),
                                    width: isCurrent ? 1.8 : 1.2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    char,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: textPrimary,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Resend Timer Row
                    Center(
                      child: canResend
                          ? GestureDetector(
                              onTap: isLoading
                                  ? null
                                  : () async {
                                      try {
                                        await ref.read(authRepositoryProvider).resetPasswordForEmail(email);
                                        startTimer(setSheetState);
                                      } catch (e) {
                                        setSheetState(() => sheetError = 'Failed to resend code');
                                      }
                                    },
                              child: Text(
                                'Resend verification code',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: primaryAccent,
                                ),
                              ),
                            )
                          : Text(
                                'Resend code in ${resendCountdown}s',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: textSecondary,
                                ),
                              ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: isLoading || otpController.text.length != 6
                            ? null
                            : () => submitVerifyOtp(otpController.text.trim()),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                              )
                            : Text(
                                'Verify Code',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                      ),
                    ),
                  ],

                  // STEP 3: Enter New Password
                  if (step == 3) ...[
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
                          'Create New Password',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Identity confirmed. Enter your new password below.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 18),

                    if (sheetError != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.red.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.red.withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                sheetError!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppColors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // New Password Field
                    Text(
                      'New Password',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: cardBorder),
                      ),
                      child: TextField(
                        controller: passwordController,
                        obscureText: obscureNew,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Min. 6 chars, A-Z, a-z, symbol',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            color: textMuted,
                            fontSize: 13.5,
                          ),
                          prefixIcon: Icon(Icons.lock_outline_rounded, size: 18, color: textSecondary),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 18,
                              color: textSecondary,
                            ),
                            onPressed: () => setSheetState(() => obscureNew = !obscureNew),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Min. 6 chars with uppercase, lowercase & symbol (=, -, @, #, etc.)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Confirm Password Field
                    Text(
                      'Confirm New Password',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: cardBorder),
                      ),
                      child: TextField(
                        controller: confirmPasswordController,
                        obscureText: obscureConfirm,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Repeat new password',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            color: textMuted,
                            fontSize: 13.5,
                          ),
                          prefixIcon: Icon(Icons.lock_outline_rounded, size: 18, color: textSecondary),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 18,
                              color: textSecondary,
                            ),
                            onPressed: () => setSheetState(() => obscureConfirm = !obscureConfirm),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: isLoading
                            ? null
                            : () async {
                                final pass = passwordController.text;
                                final confirmPass = confirmPasswordController.text;
                                final validationError = PasswordValidator.validate(pass);
                                if (validationError != null) {
                                  setSheetState(() => sheetError = validationError);
                                  return;
                                }
                                if (pass != confirmPass) {
                                  setSheetState(() => sheetError = 'Passwords do not match');
                                  return;
                                }

                                FocusScope.of(ctx).unfocus();
                                setSheetState(() {
                                  isLoading = true;
                                  sheetError = null;
                                });

                                try {
                                  await ref.read(authRepositoryProvider).updatePassword(pass);
                                  if (ctx.mounted) {
                                    setSheetState(() {
                                      isLoading = false;
                                      step = 4;
                                    });
                                  }
                                } catch (e) {
                                  if (ctx.mounted) {
                                    setSheetState(() {
                                      isLoading = false;
                                      sheetError = e.toString().replaceAll('Exception:', '').trim();
                                    });
                                  }
                                }
                              },
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                              )
                            : Text(
                                'Update Password',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                      ),
                    ),
                  ],

                  // STEP 4: Success Confirmation View
                  if (step == 4) ...[
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 10),
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withValues(alpha: 0.15),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.35), width: 2),
                            ),
                            child: const Icon(Icons.check_rounded, size: 36, color: AppColors.primary),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Password Updated',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Your account password has been successfully updated.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                color: textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 26),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.black,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              onPressed: () {
                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                }
                              },
                              child: Text(
                                'Done',
                                style: GoogleFonts.plusJakartaSans(
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
                  ],
                ],
              ),
            ),
          );
        },
      ),
    ).then((_) {
      resendTimer?.cancel();
      otpController.dispose();
      otpFocusNode.dispose();
      passwordController.dispose();
      confirmPasswordController.dispose();
    });
  }

  void _showDeleteAccountSheet(BuildContext context, WidgetRef ref) {
    final confirmController = TextEditingController();
    bool isLoading = false;
    String? sheetError;

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
          final isConfirmationMatched = confirmController.text.trim().toUpperCase() == 'DELETE';

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

                  // Danger Header Row
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.red.withValues(alpha: 0.15),
                          border: Border.all(color: AppColors.red.withValues(alpha: 0.35), width: 1.5),
                        ),
                        child: const Icon(Icons.delete_forever_rounded, size: 22, color: AppColors.red),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Delete Account',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: AppColors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Warning Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.red.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: AppColors.red, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Permanent & Irreversible',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Deleting your account will permanently wipe all your financial accounts, transactions, bills, savings goals, categories, and personal data from our servers. You will lose access immediately.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (sheetError != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.red.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              sheetError!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppColors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Confirmation text input
                  Text.rich(
                    TextSpan(
                      text: 'To confirm deletion, please type ',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                      children: const [
                        TextSpan(
                          text: 'DELETE',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.red,
                          ),
                        ),
                        TextSpan(text: ' below:'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isConfirmationMatched ? AppColors.red : cardBorder,
                        width: isConfirmationMatched ? 1.5 : 1.0,
                      ),
                    ),
                    child: TextField(
                      controller: confirmController,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Type DELETE to confirm',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          color: textMuted,
                          fontSize: 13,
                          letterSpacing: 0.2,
                        ),
                        prefixIcon: const Icon(Icons.shield_outlined, size: 18, color: AppColors.red),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                      onChanged: (_) => setSheetState(() {}),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Delete Account Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.red,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.red.withValues(alpha: 0.35),
                        disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      onPressed: (!isConfirmationMatched || isLoading)
                          ? null
                          : () async {
                              FocusScope.of(ctx).unfocus();
                              setSheetState(() {
                                isLoading = true;
                                sheetError = null;
                              });

                              try {
                                if (context.mounted) {
                                  Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
                                }
                                await ref.read(authRepositoryProvider).deleteAccount();
                              } catch (e) {
                                if (ctx.mounted) {
                                  setSheetState(() {
                                    isLoading = false;
                                    sheetError = e.toString().replaceAll('Exception:', '').trim();
                                  });
                                }
                              }
                            },
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              'Delete My Account Permanently',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Cancel Button
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: textSecondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(23),
                        ),
                      ),
                      onPressed: isLoading ? null : () => Navigator.pop(ctx),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
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
    ).then((_) {
      confirmController.dispose();
    });
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
            // Squircle Icon Badge with synchronized color & glyph animation
            TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: iconColor),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              builder: (context, animatedColor, _) {
                final currentColor = animatedColor ?? iconColor;
                return Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: currentColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: currentColor.withValues(alpha: 0.28),
                      width: 1,
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.easeInOut,
                    switchOutCurve: Curves.easeInOut,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.75, end: 1.0).animate(anim),
                        child: child,
                      ),
                    ),
                    child: Icon(
                      icon,
                      key: ValueKey(icon),
                      size: 19,
                      color: currentColor,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 14),

            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: titleColor ?? context.textPrimary,
                    ),
                    child: Text(title),
                  ),
                  const SizedBox(height: 2),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: context.textSecondary,
                    ),
                    child: Text(subtitle),
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
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
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
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
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
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeInOut,
                  switchOutCurve: Curves.easeInOut,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.7, end: 1.0).animate(anim),
                      child: child,
                    ),
                  ),
                  child: Icon(
                    isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                    key: ValueKey(isDark),
                    size: 12,
                    color: isDark ? AppColors.primary : const Color(0xFFF59E0B),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

