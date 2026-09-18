import '../../core/config/supabase_client.dart';
import '../../domain/entities/bill.dart';
import '../../domain/entities/bill_payment.dart';

class BillRepository {
  Future<List<Bill>> getAll() async {
    final rows = await supabase
        .from('bills')
        .select()
        .eq('is_active', true)
        .order('due_day');
    return rows.map((row) => Bill.fromJson(row)).toList();
  }

  Future<void> create(Bill bill) async {
    await supabase.from('bills').insert({
      'name': bill.name,
      'amount': bill.amount,
      'currency': bill.currency,
      'due_day': bill.dueDay,
      'account_id': bill.accountId,
      'reminder_days_before': bill.reminderDaysBefore,
    });
  }

  /// Status pembayaran bulan berjalan untuk semua tagihan.
  Future<List<BillPayment>> getCurrentMonthPayments() async {
    return getPaymentsForMonth(DateTime.now());
  }

  /// Status pembayaran untuk bulan tertentu (format YYYY-MM-01).
  Future<List<BillPayment>> getPaymentsForMonth(DateTime month) async {
    final startOfMonth = DateTime(month.year, month.month, 1).toIso8601String().split('T').first;
    final nextMonth = DateTime(month.year, month.month + 1, 1).toIso8601String().split('T').first;
    final rows = await supabase
        .from('bill_payments')
        .select()
        .gte('period_month', startOfMonth)
        .lt('period_month', nextMonth);
    return rows.map((row) => BillPayment.fromJson(row)).toList();
  }

  /// Menandai tagihan lunas. Memanggil function SQL `pay_bill()` supaya
  /// insert transaksi + update status terjadi sebagai satu operasi atomik
  /// (lihat schema.sql bagian 12) — tidak dilakukan manual 2 langkah di sini.
  Future<void> payBill({
    required String billId,
    required String accountId,
    required num amount,
    String? categoryId,
    DateTime? periodMonth,
    DateTime? paidDate,
  }) async {
    final params = <String, dynamic>{
      'p_bill_id': billId,
      'p_account_id': accountId,
      'p_amount': amount,
      'p_category_id': categoryId,
    };
    if (periodMonth != null) {
      params['p_period'] = DateTime(periodMonth.year, periodMonth.month, 1).toIso8601String().split('T').first;
    }
    if (paidDate != null) {
      params['p_paid_date'] = DateTime(paidDate.year, paidDate.month, paidDate.day).toIso8601String().split('T').first;
    }
    await supabase.rpc('pay_bill', params: params);
  }
}