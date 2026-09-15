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

class UserProfileData {
  final String userId;
  final String email;
  final String displayName;
  final String? avatarUrl;

  const UserProfileData({
    required this.userId,
    required this.email,
    required this.displayName,
    this.avatarUrl,
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
    final displayName = (rawName != null && rawName.trim().isNotEmpty)
        ? rawName.trim()
        : _deriveNameFromEmail(email);

    return UserProfileData(
      userId: user.id,
      email: email,
      displayName: displayName,
      avatarUrl: avatarUrl,
    );
  }

  Future<void> updateName(String newName) async {
    final repo = ref.read(authRepositoryProvider);
    await repo.updateProfile(fullName: newName);
    ref.invalidateSelf();
  }

  Future<void> updateAvatar(String? avatarUrl) async {
    final repo = ref.read(authRepositoryProvider);
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

    final url = await repo.uploadAvatar(
      userId: user.id,
      imageBytes: bytes,
      fileExtension: extension,
    );
    await repo.updateProfile(avatarUrl: url);
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
