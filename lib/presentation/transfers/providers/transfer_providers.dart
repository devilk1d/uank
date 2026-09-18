import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../domain/entities/transfer.dart';
import '../../accounts/providers/account_providers.dart';
import '../../repository_providers.dart';

part 'transfer_providers.g.dart';

@Riverpod(keepAlive: true)
Future<List<Transfer>> transfers(Ref ref) {
  final repo = ref.watch(transferRepositoryProvider);
  return repo.getAll();
}

/// Transfer mempengaruhi saldo DUA akun sekaligus, makanya yang
/// di-invalidate adalah accountBalancesProvider (bukan per-akun).
Future<void> createTransfer(WidgetRef ref, Transfer transfer) async {
  final repo = ref.read(transferRepositoryProvider);
  await repo.create(transfer);
  ref.invalidate(transfersProvider);
  ref.invalidate(accountBalancesProvider);
}

Future<void> updateTransfer(WidgetRef ref, Transfer transfer, {String? oldAttachmentUrl}) async {
  final repo = ref.read(transferRepositoryProvider);
  await repo.update(transfer, oldAttachmentUrl: oldAttachmentUrl);
  ref.invalidate(transfersProvider);
  ref.invalidate(accountBalancesProvider);
}

Future<void> deleteTransfer(WidgetRef ref, String id, {String? attachmentUrl}) async {
  final repo = ref.read(transferRepositoryProvider);
  await repo.delete(id, attachmentUrl: attachmentUrl);
  ref.invalidate(transfersProvider);
  ref.invalidate(accountBalancesProvider);
}

