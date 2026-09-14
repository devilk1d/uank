import '../../core/config/supabase_client.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/account_balance.dart';

class AccountRepository {
  /// Daftar akun mentah (dari tabel `accounts`), dipakai saat menambah/edit akun.
  Future<List<Account>> getAll() async {
    final rows = await supabase
        .from('accounts')
        .select()
        .eq('is_active', true)
        .order('name');

    return rows.map((row) => Account.fromJson(row)).toList();
  }

  /// Saldo tiap akun (dari VIEW `account_balances`), dipakai di Dashboard.
  Future<List<AccountBalance>> getBalances() async {
    final rows = await supabase.from('account_balances').select();

    return rows.map((row) => AccountBalance.fromJson(row)).toList();
  }

  Future<void> create(Account account, {num initialBalance = 0}) async {
    final res = await supabase.from('accounts').insert({
      'name': account.name,
      'type': account.type,
      'currency': account.currency,
    }).select().single();

    final accountId = res['id'] as String;

    if (initialBalance > 0) {
      await supabase.from('transactions').insert({
        'account_id': accountId,
        'type': 'income',
        'amount': initialBalance,
        'description': 'Initial Balance',
        'transaction_date': DateTime.now().toIso8601String().split('T').first,
      });
    }
  }

  Future<void> deactivate(String accountId) async {
    await supabase
        .from('accounts')
        .update({'is_active': false}).eq('id', accountId);
  }
}