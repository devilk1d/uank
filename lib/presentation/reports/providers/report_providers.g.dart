// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(monthlyExpenses)
final monthlyExpensesProvider = MonthlyExpensesProvider._();

final class MonthlyExpensesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MonthlyExpenseCategory>>,
          List<MonthlyExpenseCategory>,
          FutureOr<List<MonthlyExpenseCategory>>
        >
    with
        $FutureModifier<List<MonthlyExpenseCategory>>,
        $FutureProvider<List<MonthlyExpenseCategory>> {
  MonthlyExpensesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'monthlyExpensesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$monthlyExpensesHash();

  @$internal
  @override
  $FutureProviderElement<List<MonthlyExpenseCategory>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MonthlyExpenseCategory>> create(Ref ref) {
    return monthlyExpenses(ref);
  }
}

String _$monthlyExpensesHash() => r'90fac3b2666003a81a2aed96e86de23774728132';
