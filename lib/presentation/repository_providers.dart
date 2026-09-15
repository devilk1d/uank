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
import '../data/saving_goals/saving_goal_repository.dart';

part 'repository_providers.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) => AuthRepository();

@Riverpod(keepAlive: true)
AccountRepository accountRepository(Ref ref) => AccountRepository();

@Riverpod(keepAlive: true)
CategoryRepository categoryRepository(Ref ref) => CategoryRepository();

@Riverpod(keepAlive: true)
TransactionRepository transactionRepository(Ref ref) => TransactionRepository();

@Riverpod(keepAlive: true)
TransferRepository transferRepository(Ref ref) => TransferRepository();

@Riverpod(keepAlive: true)
BillRepository billRepository(Ref ref) => BillRepository();

@Riverpod(keepAlive: true)
ExchangeRateRepository exchangeRateRepository(Ref ref) =>
    ExchangeRateRepository();

@Riverpod(keepAlive: true)
DeviceTokenRepository deviceTokenRepository(Ref ref) => DeviceTokenRepository();

@Riverpod(keepAlive: true)
SavingGoalRepository savingGoalRepository(Ref ref) => SavingGoalRepository();

