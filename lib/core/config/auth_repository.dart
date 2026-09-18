// LOKASI: lib/core/config/auth_repository.dart
//
// Membungkus Supabase Auth. Ditaruh di core/ (bukan data/) karena auth
// dipakai di seluruh aplikasi, bukan satu fitur spesifik.
//
// PENTING: semua tabel di schema.sql pakai Row Level Security berbasis
// auth.uid(). Tanpa user login lewat class ini, SEMUA query di repository
// lain (accounts, transactions, dst) akan mengembalikan hasil kosong,
// bukan error — karena RLS diam-diam menyaring "tidak ada baris milikmu".

import 'dart:async';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/push_notification_service.dart';
import 'supabase_client.dart';

class AuthRepository {
  /// Current logged-in Supabase user
  User? get currentUser => supabase.auth.currentUser;

  /// Null kalau belum ada yang login.
  String? get currentUserId => supabase.auth.currentUser?.id;

  bool get isLoggedIn => currentUserId != null;

  /// Dengarkan ini di provider untuk tahu kapan status login berubah
  /// (login, logout, atau token expired lalu refresh otomatis).
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  /// Refresh token session jika sudah expired atau mendekati expired (< 5 menit).
  Future<bool> refreshSessionIfNeeded() async {
    try {
      final session = supabase.auth.currentSession;
      if (session != null) {
        final expiresAt = session.expiresAt != null
            ? DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000)
            : null;
        final isNearExpiry = expiresAt != null &&
            DateTime.now().add(const Duration(minutes: 5)).isAfter(expiresAt);

        if (session.isExpired || isNearExpiry) {
          final res = await supabase.auth.refreshSession();
          return res.session != null;
        }
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    await supabase.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }

  Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
    required OtpType type,
  }) async {
    final response = await supabase.auth.verifyOTP(
      email: email,
      token: token,
      type: type,
    );
    if (response.session != null) {
      unawaited(PushNotificationService.instance.syncTokenWithBackend());
    }
    return response;
  }

  Future<void> resendOtp({
    required String email,
    required OtpType type,
  }) async {
    await supabase.auth.resend(
      type: type == OtpType.signup ? OtpType.signup : OtpType.email,
      email: email,
    );
  }

  Future<void> resetPasswordForEmail(String email) async {
    await supabase.auth.resetPasswordForEmail(email);
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await supabase.auth.signInWithPassword(email: email, password: password);
    unawaited(PushNotificationService.instance.syncTokenWithBackend());
  }

  Future<UserResponse> updateProfile({
    String? fullName,
    String? avatarUrl,
    Map<String, dynamic>? extraData,
  }) async {
    final data = <String, dynamic>{};
    if (fullName != null) data['full_name'] = fullName;
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;
    if (extraData != null) data.addAll(extraData);

    return await supabase.auth.updateUser(
      UserAttributes(data: data),
    );
  }

  Future<String> uploadAvatar({
    required String userId,
    required Uint8List imageBytes,
    required String fileExtension,
  }) async {
    final cleanExt = (fileExtension.toLowerCase() == 'jpg' || fileExtension.toLowerCase() == 'jpeg')
        ? 'jpeg'
        : fileExtension.toLowerCase();
    final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}.$cleanExt';

    await supabase.storage.from('avatars').uploadBinary(
      fileName,
      imageBytes,
      fileOptions: FileOptions(
        contentType: 'image/$cleanExt',
        upsert: true,
      ),
    );
    final publicUrl = supabase.storage.from('avatars').getPublicUrl(fileName);
    return publicUrl;
  }

  Future<void> deleteAvatarFile(String avatarUrl) async {
    try {
      const marker = '/storage/v1/object/public/avatars/';
      if (avatarUrl.contains(marker)) {
        final path = avatarUrl.substring(avatarUrl.indexOf(marker) + marker.length);
        if (path.isNotEmpty) {
          await supabase.storage.from('avatars').remove([Uri.decodeComponent(path)]);
        }
      }
    } catch (_) {
      // Best effort cleanup
    }
  }

  Future<void> updatePassword(String newPassword) async {
    await supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) throw Exception('No user logged in');

    // 1. Remove FCM device token registration
    await PushNotificationService.instance.removeCurrentToken();

    // 2. Clean up avatar file if exists
    final avatarUrl = user.userMetadata?['avatar_url'] as String?;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      await deleteAvatarFile(avatarUrl);
    }

    // 3. Call Supabase RPC to delete user and all cascading database records
    await supabase.rpc('delete_user_account');

    // 4. Clear auth session
    await supabase.auth.signOut();
  }

  Future<void> signOut() async {
    await PushNotificationService.instance.removeCurrentToken();
    await supabase.auth.signOut();
  }
}