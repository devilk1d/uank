// LOKASI: lib/core/config/auth_repository.dart
//
// Membungkus Supabase Auth. Ditaruh di core/ (bukan data/) karena auth
// dipakai di seluruh aplikasi, bukan satu fitur spesifik.
//
// PENTING: semua tabel di schema.sql pakai Row Level Security berbasis
// auth.uid(). Tanpa user login lewat class ini, SEMUA query di repository
// lain (accounts, transactions, dst) akan mengembalikan hasil kosong,
// bukan error — karena RLS diam-diam menyaring "tidak ada baris milikmu".

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_client.dart';

class AuthRepository {
  /// Null kalau belum ada yang login.
  String? get currentUserId => supabase.auth.currentUser?.id;

  bool get isLoggedIn => currentUserId != null;

  /// Dengarkan ini di provider untuk tahu kapan status login berubah
  /// (login, logout, atau token expired lalu refresh otomatis).
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

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

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }
}