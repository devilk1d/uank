// LOKASI: lib/presentation/theme/providers/theme_mode_provider.dart
//
// State sederhana (bukan data dari Supabase) untuk toggle light/dark.
// Widget mana pun bisa ref.watch(themeModeProvider) untuk tahu mode aktif,
// dan ref.read(themeModeProvider.notifier).toggle() untuk mengubahnya.

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_mode_provider.g.dart';

@riverpod
class AppThemeMode extends _$AppThemeMode {
  @override
  ThemeMode build() => ThemeMode.dark; // default sesuai referensi desain

  void toggle() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }
}
