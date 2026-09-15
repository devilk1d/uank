import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.avatarUrl,
    required this.initialLetter,
    this.size = 44,
    this.fontSize,
    this.showEditBadge = false,
    this.onTap,
    this.border,
  });

  final String? avatarUrl;
  final String initialLetter;
  final double size;
  final double? fontSize;
  final bool showEditBadge;
  final VoidCallback? onTap;
  final BoxBorder? border;

  static final Map<String, Uint8List> _base64Cache = {};

  @override
  Widget build(BuildContext context) {
    final avatarContent = _buildAvatarContent();

    Widget avatarWidget = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: (avatarUrl != null && avatarUrl!.isNotEmpty && !avatarUrl!.startsWith('emoji:'))
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
        color: (avatarUrl != null && avatarUrl!.isNotEmpty && !avatarUrl!.startsWith('emoji:'))
            ? context.cardBg
            : null,
        border: border ??
            Border.all(
              color: AppColors.primary.withValues(alpha: 0.5),
              width: size > 50 ? 2.0 : 1.5,
            ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: size > 50 ? 14 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: Center(child: avatarContent),
      ),
    );

    if (showEditBadge) {
      avatarWidget = Stack(
        clipBehavior: Clip.none,
        children: [
          avatarWidget,
          Positioned(
            bottom: 0,
            right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: context.background, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 13,
                color: Colors.black,
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatarWidget,
      );
    }

    return avatarWidget;
  }

  Widget _buildAvatarContent() {
    final url = avatarUrl?.trim();
    if (url == null || url.isEmpty) {
      return Text(
        initialLetter.isNotEmpty ? initialLetter[0].toUpperCase() : 'U',
        style: TextStyle(
          fontSize: fontSize ?? (size * 0.44),
          fontWeight: FontWeight.w900,
          color: const Color(0xFF0E0E10),
        ),
      );
    }

    // 1. Emoji Preset
    if (url.startsWith('emoji:')) {
      final emoji = url.substring('emoji:'.length);
      return Text(
        emoji,
        style: TextStyle(
          fontSize: fontSize ?? (size * 0.52),
        ),
      );
    }

    // 2. Base64 Data URI
    if (url.startsWith('data:image/')) {
      try {
        final commaIndex = url.indexOf(',');
        if (commaIndex != -1) {
          final bytes = _base64Cache.putIfAbsent(url, () {
            final base64Data = url.substring(commaIndex + 1);
            return base64Decode(base64Data);
          });
          return Image.memory(
            bytes,
            key: ValueKey(url),
            width: size,
            height: size,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) => _buildFallback(),
          );
        }
      } catch (_) {}
      return _buildFallback();
    }

    // 3. Network URL
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        key: ValueKey(url),
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            width: size * 0.4,
            height: size * 0.4,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: context.isDark ? AppColors.primary : const Color(0xFF15803D),
            ),
          );
        },
      );
    }

    return _buildFallback();
  }

  Widget _buildFallback() {
    return Text(
      initialLetter.isNotEmpty ? initialLetter[0].toUpperCase() : 'U',
      style: TextStyle(
        fontSize: fontSize ?? (size * 0.44),
        fontWeight: FontWeight.w900,
        color: const Color(0xFF0E0E10),
      ),
    );
  }
}
