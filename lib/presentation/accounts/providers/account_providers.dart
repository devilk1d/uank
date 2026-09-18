import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../domain/entities/account.dart';
import '../../../domain/entities/account_balance.dart';
import '../../repository_providers.dart';

import '../../transactions/providers/transaction_providers.dart';

part 'account_providers.g.dart';

/// Daftar akun mentah (dari tabel `accounts`), dipakai di layar
/// tambah/edit akun.
@Riverpod(keepAlive: true)
Future<List<Account>> accounts(Ref ref) {
  final repo = ref.watch(accountRepositoryProvider);
  return repo.getAll();
}

/// Saldo tiap akun (dari VIEW `account_balances`), dipakai di Dashboard.
@Riverpod(keepAlive: true)
Future<List<AccountBalance>> accountBalances(Ref ref) {
  final repo = ref.watch(accountRepositoryProvider);
  return repo.getBalances();
}

/// Dipanggil dari layar "Tambah Akun". Setelah sukses, invalidate provider
/// di atas supaya daftar akun & saldo otomatis ke-refresh tanpa perlu
/// widget manggil setState manual.
Future<void> createAccount(WidgetRef ref, Account account, {num initialBalance = 0}) async {
  final repo = ref.read(accountRepositoryProvider);
  await repo.create(account, initialBalance: initialBalance);
  ref.invalidate(accountsProvider);
  ref.invalidate(accountBalancesProvider);
  ref.invalidate(transactionsProvider);
}
