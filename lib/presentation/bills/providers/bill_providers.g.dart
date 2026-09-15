// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bill_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(bills)
final billsProvider = BillsProvider._();

final class BillsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Bill>>,
          List<Bill>,
          FutureOr<List<Bill>>
        >
    with $FutureModifier<List<Bill>>, $FutureProvider<List<Bill>> {
  BillsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'billsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$billsHash();

  @$internal
  @override
  $FutureProviderElement<List<Bill>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Bill>> create(Ref ref) {
    return bills(ref);
  }
}

String _$billsHash() => r'927efd49de93e648d2dea234a451ad6fdc8d5a4d';

@ProviderFor(currentMonthBillPayments)
final currentMonthBillPaymentsProvider = CurrentMonthBillPaymentsProvider._();

final class CurrentMonthBillPaymentsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<BillPayment>>,
          List<BillPayment>,
          FutureOr<List<BillPayment>>
        >
    with
        $FutureModifier<List<BillPayment>>,
        $FutureProvider<List<BillPayment>> {
  CurrentMonthBillPaymentsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentMonthBillPaymentsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentMonthBillPaymentsHash();

  @$internal
  @override
  $FutureProviderElement<List<BillPayment>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<BillPayment>> create(Ref ref) {
    return currentMonthBillPayments(ref);
  }
}

String _$currentMonthBillPaymentsHash() =>
    r'0b4e76bb78e19f7a8d05b9846172e2c93f02c27f';
