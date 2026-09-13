// LOKASI: lib/presentation/transfers/providers/transfer_providers.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../domain/entities/transfer.dart';
import '../../accounts/providers/account_providers.dart';
import '../../repository_providers.dart';

part 'transfer_providers.g.dart';

@riverpod
Future<List<Transfer>> transfers(Ref ref) {
  final repo = ref.watch(transferRepositoryProvider);
  return repo.getAll();
}

/// Transfer mempengaruhi saldo DUA akun sekaligus, makanya yang
/// di-invalidate adalah accountBalancesProvider (bukan per-akun).
Future<void> createTransfer(Ref ref, Transfer transfer) async {
  final repo = ref.read(transferRepositoryProvider);
  await repo.create(transfer);
  ref.invalidate(transfersProvider);
  ref.invalidate(accountBalancesProvider);
}
