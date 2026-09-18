// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Daftar akun mentah (dari tabel `accounts`), dipakai di layar
/// tambah/edit akun.

@ProviderFor(accounts)
final accountsProvider = AccountsProvider._();

/// Daftar akun mentah (dari tabel `accounts`), dipakai di layar
/// tambah/edit akun.

final class AccountsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Account>>,
          List<Account>,
          FutureOr<List<Account>>
        >
    with $FutureModifier<List<Account>>, $FutureProvider<List<Account>> {
  /// Daftar akun mentah (dari tabel `accounts`), dipakai di layar
  /// tambah/edit akun.
  AccountsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountsHash();

  @$internal
  @override
  $FutureProviderElement<List<Account>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Account>> create(Ref ref) {
    return accounts(ref);
  }
}

String _$accountsHash() => r'959e38fa25108531407ac85292451983353a358d';

/// Saldo tiap akun (dari VIEW `account_balances`), dipakai di Dashboard.

@ProviderFor(accountBalances)
final accountBalancesProvider = AccountBalancesProvider._();

/// Saldo tiap akun (dari VIEW `account_balances`), dipakai di Dashboard.

final class AccountBalancesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AccountBalance>>,
          List<AccountBalance>,
          FutureOr<List<AccountBalance>>
        >
    with
        $FutureModifier<List<AccountBalance>>,
        $FutureProvider<List<AccountBalance>> {
  /// Saldo tiap akun (dari VIEW `account_balances`), dipakai di Dashboard.
  AccountBalancesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountBalancesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountBalancesHash();

  @$internal
  @override
  $FutureProviderElement<List<AccountBalance>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AccountBalance>> create(Ref ref) {
    return accountBalances(ref);
  }
}

String _$accountBalancesHash() => r'a06ba4b044749bdffb98e7710dbab839217320a5';
