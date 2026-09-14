import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../domain/entities/bill.dart';
import '../../../domain/entities/bill_payment.dart';
import '../../accounts/providers/account_providers.dart';
import '../../repository_providers.dart';

part 'bill_providers.g.dart';

@riverpod
Future<List<Bill>> bills(Ref ref) {
  final repo = ref.watch(billRepositoryProvider);
  return repo.getAll();
}

@riverpod
Future<List<BillPayment>> currentMonthBillPayments(Ref ref) {
  final repo = ref.watch(billRepositoryProvider);
  return repo.getCurrentMonthPayments();
}

Future<void> createBill(WidgetRef ref, Bill bill) async {
  final repo = ref.read(billRepositoryProvider);
  await repo.create(bill);
  ref.invalidate(billsProvider);
}

/// Memanggil function SQL `pay_bill()` (lihat schema.sql bagian 12), yang
/// membuat transaksi expense DAN menandai tagihan lunas sebagai satu
/// operasi atomik. Karena itu di sini juga invalidate transactions &
/// saldo akun, bukan cuma status tagihan.
Future<void> payBill(
  WidgetRef ref, {
  required String billId,
  required String accountId,
  required num amount,
  String? categoryId,
}) async {
  final repo = ref.read(billRepositoryProvider);
  await repo.payBill(
    billId: billId,
    accountId: accountId,
    amount: amount,
    categoryId: categoryId,
  );
  ref.invalidate(currentMonthBillPaymentsProvider);
  ref.invalidate(accountBalancesProvider);
}
