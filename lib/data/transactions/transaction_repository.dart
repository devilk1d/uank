import '../../core/config/supabase_client.dart';
import '../../domain/entities/transaction.dart';

class TransactionRepository {
  Future<List<Transaction>> getAll() async {
    final rows = await supabase
        .from('transactions')
        .select()
        .order('transaction_date', ascending: false);
    return rows.map((row) => Transaction.fromJson(row)).toList();
  }

  Future<List<Transaction>> getByAccount(String accountId) async {
    final rows = await supabase
        .from('transactions')
        .select()
        .eq('account_id', accountId)
        .order('transaction_date', ascending: false);
    return rows.map((row) => Transaction.fromJson(row)).toList();
  }

  /// amount_idr TIDAK dikirim dari sini — sudah diisi otomatis oleh
  /// trigger `fill_amount_idr` di database (lihat schema.sql).
  Future<void> create(Transaction transaction) async {
    await supabase.from('transactions').insert({
      'account_id': transaction.accountId,
      'category_id': transaction.categoryId,
      'type': transaction.type,
      'amount': transaction.amount,
      'description': transaction.description,
      'transaction_date':
      transaction.transactionDate.toIso8601String().split('T').first,
    });
  }

  Future<void> delete(String transactionId) async {
    await supabase.from('transactions').delete().eq('id', transactionId);
  }
}