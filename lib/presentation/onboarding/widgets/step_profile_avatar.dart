import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_card.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../auth/providers/auth_providers.dart';

class StepProfileAvatar extends ConsumerStatefulWidget {
  const StepProfileAvatar({
    super.key,
    required this.onNext,
    required this.onSkip,
  });

  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  ConsumerState<StepProfileAvatar> createState() => _StepProfileAvatarState();
}

class _StepProfileAvatarState extends ConsumerState<StepProfileAvatar> {
  late TextEditingController _nameController;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider);
    _nameController = TextEditingController(text: profile?.displayName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (file == null) return;

      setState(() => _isUploading = true);
      final bytes = await file.readAsBytes();
      final ext = file.name.split('.').last.toLowerCase();
      final validExt = (ext == 'png' || ext == 'jpg' || ext == 'jpeg') ? ext : 'jpg';

      await ref.read(userProfileProvider.notifier).uploadAndSetAvatar(
        bytes: bytes,
        extension: validExt,
      );
    } catch (_) {
      // Best effort upload
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showImagePickerSheet(BuildContext context) {
    final isDark = context.isDark;
    final cardBg = context.cardBg;
    final cardBorder = context.cardBorder;
    final textPrimary = context.textPrimary;
    final textMuted = context.textMuted;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 32),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: cardBorder, width: 1.5)),
        ),
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
            Text(
              'Select Profile Picture',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickAndUploadImage(ImageSource.gallery);
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
                            'Gallery',
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
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickAndUploadImage(ImageSource.camera);
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
                            'Camera',
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
          ],
        ),
      ),
    );
  }

  Future<void> _handleContinue() async {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      await ref.read(userProfileProvider.notifier).updateName(name);
    }
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final isDark = context.isDark;
    final textPrimary = context.textPrimary;
    final textSecondary = context.textSecondary;
    final cardBorder = context.cardBorder;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 1 of 4',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: isDark ? AppColors.primary : const Color(0xFF15803D),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Set Up Your Profile',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Personalize your financial identity with a name and profile photo.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.4,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 32),

          // Avatar Selector Card
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                AppAvatar(
                  avatarUrl: profile?.avatarUrl,
                  initialLetter: profile?.initialLetter ?? 'U',
                  size: 104,
                  showEditBadge: false,
                  onTap: () => _showImagePickerSheet(context),
                ),
                if (_isUploading)
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black54,
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => _showImagePickerSheet(context),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? const Color(0xFF0E0E10) : Colors.white,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 17,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => _showImagePickerSheet(context),
              child: Text(
                'Upload Photo',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.primaryLight : const Color(0xFF15803D),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Display Name Field
          GlassCard(
            borderRadius: 20,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Display Name',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _nameController,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter your name',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: context.textMuted,
                    ),
                    prefixIcon: Icon(Icons.person_outline_rounded, color: textSecondary, size: 20),
                    filled: true,
                    fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),

          // Action Buttons
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _handleContinue,
              child: Text(
                'Continue',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: widget.onSkip,
              child: Text(
                'Skip for now',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
