// LOKASI: lib/presentation/repository_providers.dart
//
// Satu file berisi provider untuk SEMUA repository (bukan file per fitur),
// karena isinya cuma "bungkus jadi provider", tidak ada logic tambahan.
// Provider lain (di masing-masing folder fitur) akan `ref.watch` ke sini.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/config/auth_repository.dart';
import '../data/accounts/account_repository.dart';
import '../data/categories/category_repository.dart';
import '../data/transactions/transaction_repository.dart';
import '../data/transfers/transfer_repository.dart';
import '../data/bills/bill_repository.dart';
import '../data/exchange_rates/exchange_rate_repository.dart';
import '../data/device_token/device_token_repository.dart';

part 'repository_providers.g.dart';

@riverpod
AuthRepository authRepository(Ref ref) => AuthRepository();

@riverpod
AccountRepository accountRepository(Ref ref) => AccountRepository();

@riverpod
CategoryRepository categoryRepository(Ref ref) => CategoryRepository();

@riverpod
TransactionRepository transactionRepository(Ref ref) => TransactionRepository();

@riverpod
TransferRepository transferRepository(Ref ref) => TransferRepository();

@riverpod
BillRepository billRepository(Ref ref) => BillRepository();

@riverpod
ExchangeRateRepository exchangeRateRepository(Ref ref) =>
    ExchangeRateRepository();

@riverpod
DeviceTokenRepository deviceTokenRepository(Ref ref) => DeviceTokenRepository();
