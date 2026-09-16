// LOKASI: lib/presentation/auth/providers/auth_providers.dart
//
// Widget mana pun bisa `ref.watch(authStateProvider)` untuk tahu apakah
// user sedang login atau tidak, dan otomatis rebuild saat status berubah
// (login, logout, token refresh).

import 'dart:typed_data';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../repository_providers.dart';

part 'auth_providers.g.dart';

@riverpod
Stream<AuthState> authState(Ref ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
}

@riverpod
bool isLoggedIn(Ref ref) {
  final repo = ref.watch(authRepositoryProvider);
  // ikut berubah setiap authState berubah
  ref.watch(authStateProvider);
  return repo.isLoggedIn;
}

@riverpod
class PasswordRecoveryMode extends _$PasswordRecoveryMode {
  @override
  bool build() => false;

  void setMode(bool isRecovery) => state = isRecovery;
}

enum AuthTransitionMode {
  none,
  enteringApp,
  exitingApp,
}

@riverpod
class AuthTransitionLock extends _$AuthTransitionLock {
  @override
  AuthTransitionMode build() => AuthTransitionMode.none;

  void setEntering() => state = AuthTransitionMode.enteringApp;
  void setExiting() => state = AuthTransitionMode.exitingApp;
  void reset() => state = AuthTransitionMode.none;
  void setLocked(bool isLocked) {
    state = isLocked ? AuthTransitionMode.enteringApp : AuthTransitionMode.none;
  }
}

class UserProfileData {
  final String userId;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final bool hasCompletedOnboarding;

  const UserProfileData({
    required this.userId,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    this.hasCompletedOnboarding = false,
  });

  String get initialLetter => displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
}

@riverpod
class UserProfile extends _$UserProfile {
  @override
  UserProfileData? build() {
    final repo = ref.watch(authRepositoryProvider);
    ref.watch(authStateProvider);
    final user = repo.currentUser;
    if (user == null) return null;

    final rawName = user.userMetadata?['full_name'] as String?;
    final avatarUrl = user.userMetadata?['avatar_url'] as String?;
    final email = user.email ?? 'user@uank.app';
    final hasCompletedOnboarding = (user.userMetadata?['has_completed_onboarding'] as bool?) ?? false;
    final displayName = (rawName != null && rawName.trim().isNotEmpty)
        ? rawName.trim()
        : _deriveNameFromEmail(email);

    return UserProfileData(
      userId: user.id,
      email: email,
      displayName: displayName,
      avatarUrl: avatarUrl,
      hasCompletedOnboarding: hasCompletedOnboarding,
    );
  }

  Future<void> updateName(String newName) async {
    final repo = ref.read(authRepositoryProvider);
    await repo.updateProfile(fullName: newName);
    ref.invalidateSelf();
  }

  Future<void> completeOnboarding() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.updateProfile(extraData: {'has_completed_onboarding': true});
    ref.invalidateSelf();
  }

  Future<void> updateAvatar(String? avatarUrl) async {
    final repo = ref.read(authRepositoryProvider);
    final previousAvatar = state?.avatarUrl;
    if (previousAvatar != null && previousAvatar.contains('/avatars/')) {
      await repo.deleteAvatarFile(previousAvatar);
    }
    await repo.updateProfile(avatarUrl: avatarUrl ?? '');
    ref.invalidateSelf();
  }

  Future<String> uploadAndSetAvatar({
    required Uint8List bytes,
    required String extension,
  }) async {
    final repo = ref.read(authRepositoryProvider);
    final user = repo.currentUser;
    if (user == null) throw Exception('No user logged in');

    final previousAvatar = state?.avatarUrl;

    final url = await repo.uploadAvatar(
      userId: user.id,
      imageBytes: bytes,
      fileExtension: extension,
    );
    await repo.updateProfile(avatarUrl: url);

    // Delete old avatar from storage if existed to avoid storage clutter
    if (previousAvatar != null && previousAvatar.contains('/avatars/') && previousAvatar != url) {
      await repo.deleteAvatarFile(previousAvatar);
    }

    ref.invalidateSelf();
    return url;
  }

  static String _deriveNameFromEmail(String email) {
    final prefix = email.split('@').first;
    if (prefix.isEmpty) return 'User Account';
    final parts = prefix.split(RegExp(r'[._-]'));
    return parts.map((p) => p.isEmpty ? '' : '${p[0].toUpperCase()}${p.substring(1)}').join(' ');
  }
}
