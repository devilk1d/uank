// LOKASI: lib/presentation/auth/providers/auth_providers.dart
//
// Widget mana pun bisa `ref.watch(authStateProvider)` untuk tahu apakah
// user sedang login atau tidak, dan otomatis rebuild saat status berubah
// (login, logout, token refresh).

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
