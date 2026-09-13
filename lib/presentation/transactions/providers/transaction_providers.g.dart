// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(transactions)
final transactionsProvider = TransactionsProvider._();

final class TransactionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Transaction>>,
          List<Transaction>,
          FutureOr<List<Transaction>>
        >
    with
        $FutureModifier<List<Transaction>>,
        $FutureProvider<List<Transaction>> {
  TransactionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transactionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transactionsHash();

  @$internal
  @override
  $FutureProviderElement<List<Transaction>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Transaction>> create(Ref ref) {
    return transactions(ref);
  }
}

String _$transactionsHash() => r'6165401ef02d3258f15ca22a2c8e31db1505df09';

@ProviderFor(transactionsByAccount)
final transactionsByAccountProvider = TransactionsByAccountFamily._();

final class TransactionsByAccountProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Transaction>>,
          List<Transaction>,
          FutureOr<List<Transaction>>
        >
    with
        $FutureModifier<List<Transaction>>,
        $FutureProvider<List<Transaction>> {
  TransactionsByAccountProvider._({
    required TransactionsByAccountFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'transactionsByAccountProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$transactionsByAccountHash();

  @override
  String toString() {
    return r'transactionsByAccountProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Transaction>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Transaction>> create(Ref ref) {
    final argument = this.argument as String;
    return transactionsByAccount(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TransactionsByAccountProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$transactionsByAccountHash() =>
    r'b7b397b212e4b9f05434bbbecd0b7efdde82c0ed';

final class TransactionsByAccountFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Transaction>>, String> {
  TransactionsByAccountFamily._()
    : super(
        retry: null,
        name: r'transactionsByAccountProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TransactionsByAccountProvider call(String accountId) =>
      TransactionsByAccountProvider._(argument: accountId, from: this);

  @override
  String toString() => r'transactionsByAccountProvider';
}
