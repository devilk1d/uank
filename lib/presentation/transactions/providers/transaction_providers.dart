import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../domain/entities/transaction.dart';
import '../../accounts/providers/account_providers.dart';
import '../../repository_providers.dart';

part 'transaction_providers.g.dart';

@Riverpod(keepAlive: true)
Future<List<Transaction>> transactions(Ref ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getAll();
}

@riverpod
Future<List<Transaction>> transactionsByAccount(Ref ref, String accountId) {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getByAccount(accountId);
}

/// Setelah transaksi baru dibuat, saldo akun (accountBalancesProvider) juga
/// ikut di-invalidate karena saldo dihitung dari transaksi (lihat VIEW
/// account_balances di schema.sql) — jadi Dashboard otomatis ter-refresh.
Future<void> createTransaction(WidgetRef ref, Transaction transaction) async {
  final repo = ref.read(transactionRepositoryProvider);
  await repo.create(transaction);
  ref.invalidate(transactionsProvider);
  ref.invalidate(accountBalancesProvider);
}

Future<void> updateTransaction(WidgetRef ref, Transaction transaction, {String? oldAttachmentUrl}) async {
  final repo = ref.read(transactionRepositoryProvider);
  await repo.update(transaction, oldAttachmentUrl: oldAttachmentUrl);
  ref.invalidate(transactionsProvider);
  ref.invalidate(accountBalancesProvider);
}

Future<void> deleteTransaction(WidgetRef ref, String transactionId, {String? attachmentUrl}) async {
  final repo = ref.read(transactionRepositoryProvider);
  await repo.delete(transactionId, attachmentUrl: attachmentUrl);
  ref.invalidate(transactionsProvider);
  ref.invalidate(accountBalancesProvider);
}

