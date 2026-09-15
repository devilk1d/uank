import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../domain/entities/bill.dart';
import '../../../domain/entities/bill_payment.dart';
import '../../accounts/providers/account_providers.dart';
import '../../repository_providers.dart';
import '../../transactions/providers/transaction_providers.dart';

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

final selectedBillsMonthProvider =
    NotifierProvider<SelectedBillsMonthNotifier, DateTime>(
  SelectedBillsMonthNotifier.new,
);

class SelectedBillsMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  void nextMonth() {
    state = DateTime(state.year, state.month + 1, 1);
  }

  void prevMonth() {
    state = DateTime(state.year, state.month - 1, 1);
  }

  void setMonth(DateTime month) {
    state = DateTime(month.year, month.month, 1);
  }
}

final billPaymentsForSelectedMonthProvider =
    FutureProvider.autoDispose<List<BillPayment>>((ref) {
  final month = ref.watch(selectedBillsMonthProvider);
  final repo = ref.watch(billRepositoryProvider);
  return repo.getPaymentsForMonth(month);
});

Future<void> createBill(WidgetRef ref, Bill bill) async {
  final repo = ref.read(billRepositoryProvider);
  await repo.create(bill);
  ref.invalidate(billsProvider);
  ref.invalidate(currentMonthBillPaymentsProvider);
  ref.invalidate(billPaymentsForSelectedMonthProvider);
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
  DateTime? periodMonth,
  DateTime? paidDate,
}) async {
  final repo = ref.read(billRepositoryProvider);
  await repo.payBill(
    billId: billId,
    accountId: accountId,
    amount: amount,
    categoryId: categoryId,
    periodMonth: periodMonth,
    paidDate: paidDate,
  );
  ref.invalidate(billsProvider);
  ref.invalidate(currentMonthBillPaymentsProvider);
  ref.invalidate(billPaymentsForSelectedMonthProvider);
  ref.invalidate(accountBalancesProvider);
  ref.invalidate(transactionsProvider);
}
