import '../../core/config/supabase_client.dart';
import '../../domain/entities/transfer.dart';

class TransferRepository {
  Future<List<Transfer>> getAll() async {
    final rows = await supabase
        .from('transfers')
        .select()
        .order('transfer_date', ascending: false);
    return rows.map((row) => Transfer.fromJson(row)).toList();
  }

  Future<void> create(Transfer transfer) async {
    await supabase.from('transfers').insert({
      'from_account_id': transfer.fromAccountId,
      'to_account_id': transfer.toAccountId,
      'amount_from': transfer.amountFrom,
      'amount_to': transfer.amountTo,
      'exchange_rate': transfer.exchangeRate,
      'transfer_date': transfer.transferDate.toIso8601String().split('T').first,
      'notes': transfer.notes,
    });
  }

  Future<void> delete(String id) async {
    await supabase.from('transfers').delete().eq('id', id);
  }
}