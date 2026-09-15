// LOKASI: lib/core/config/auth_repository.dart
//
// Membungkus Supabase Auth. Ditaruh di core/ (bukan data/) karena auth
// dipakai di seluruh aplikasi, bukan satu fitur spesifik.
//
// PENTING: semua tabel di schema.sql pakai Row Level Security berbasis
// auth.uid(). Tanpa user login lewat class ini, SEMUA query di repository
// lain (accounts, transactions, dst) akan mengembalikan hasil kosong,
// bukan error — karena RLS diam-diam menyaring "tidak ada baris milikmu".

import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_client.dart';

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
  }) async {
    await supabase.auth.signUp(email: email, password: password);
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<UserResponse> updateProfile({String? fullName, String? avatarUrl}) async {
    final data = <String, dynamic>{};
    if (fullName != null) data['full_name'] = fullName;
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;

    return await supabase.auth.updateUser(
      UserAttributes(data: data),
    );
  }

  Future<String> uploadAvatar({
    required String userId,
    required Uint8List imageBytes,
    required String fileExtension,
  }) async {
    final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
    try {
      await supabase.storage.from('avatars').uploadBinary(
        fileName,
        imageBytes,
        fileOptions: FileOptions(
          contentType: 'image/$fileExtension',
          upsert: true,
        ),
      );
      final publicUrl = supabase.storage.from('avatars').getPublicUrl(fileName);
      return publicUrl;
    } catch (_) {
      // Fallback if storage bucket is not configured: save as base64 data URI
      final base64Str = base64Encode(imageBytes);
      return 'data:image/$fileExtension;base64,$base64Str';
    }
  }

  Future<void> updatePassword(String newPassword) async {
    await supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }
}