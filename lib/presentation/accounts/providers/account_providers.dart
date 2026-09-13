// LOKASI: lib/presentation/accounts/providers/account_providers.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../domain/entities/account.dart';
import '../../../domain/entities/account_balance.dart';
import '../../repository_providers.dart';

part 'account_providers.g.dart';

/// Daftar akun mentah (dari tabel `accounts`), dipakai di layar
/// tambah/edit akun.
@riverpod
Future<List<Account>> accounts(Ref ref) {
  final repo = ref.watch(accountRepositoryProvider);
  return repo.getAll();
}

/// Saldo tiap akun (dari VIEW `account_balances`), dipakai di Dashboard.
@riverpod
Future<List<AccountBalance>> accountBalances(Ref ref) {
  final repo = ref.watch(accountRepositoryProvider);
  return repo.getBalances();
}

/// Dipanggil dari layar "Tambah Akun". Setelah sukses, invalidate provider
/// di atas supaya daftar akun & saldo otomatis ke-refresh tanpa perlu
/// widget manggil setState manual.
Future<void> createAccount(Ref ref, Account account) async {
  final repo = ref.read(accountRepositoryProvider);
  await repo.create(account);
  ref.invalidate(accountsProvider);
  ref.invalidate(accountBalancesProvider);
}
