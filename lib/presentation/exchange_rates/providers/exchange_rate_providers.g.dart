// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exchange_rate_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(latestRate)
final latestRateProvider = LatestRateFamily._();

final class LatestRateProvider
    extends
        $FunctionalProvider<
          AsyncValue<ExchangeRate?>,
          ExchangeRate?,
          FutureOr<ExchangeRate?>
        >
    with $FutureModifier<ExchangeRate?>, $FutureProvider<ExchangeRate?> {
  LatestRateProvider._({
    required LatestRateFamily super.from,
    required ({String fromCurrency, String toCurrency}) super.argument,
  }) : super(
         retry: null,
         name: r'latestRateProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$latestRateHash();

  @override
  String toString() {
    return r'latestRateProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<ExchangeRate?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ExchangeRate?> create(Ref ref) {
    final argument =
        this.argument as ({String fromCurrency, String toCurrency});
    return latestRate(
      ref,
      fromCurrency: argument.fromCurrency,
      toCurrency: argument.toCurrency,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LatestRateProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$latestRateHash() => r'fff22727468563f6b59c056944982ae720d7bffc';

final class LatestRateFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<ExchangeRate?>,
          ({String fromCurrency, String toCurrency})
        > {
  LatestRateFamily._()
    : super(
        retry: null,
        name: r'latestRateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  LatestRateProvider call({
    required String fromCurrency,
    required String toCurrency,
  }) => LatestRateProvider._(
    argument: (fromCurrency: fromCurrency, toCurrency: toCurrency),
    from: this,
  );

  @override
  String toString() => r'latestRateProvider';
}

/// Dipakai langsung di layar converter mata uang.

@ProviderFor(convertedAmount)
final convertedAmountProvider = ConvertedAmountFamily._();

/// Dipakai langsung di layar converter mata uang.

final class ConvertedAmountProvider
    extends $FunctionalProvider<AsyncValue<num?>, num?, FutureOr<num?>>
    with $FutureModifier<num?>, $FutureProvider<num?> {
  /// Dipakai langsung di layar converter mata uang.
  ConvertedAmountProvider._({
    required ConvertedAmountFamily super.from,
    required ({num amount, String fromCurrency, String toCurrency})
    super.argument,
  }) : super(
         retry: null,
         name: r'convertedAmountProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$convertedAmountHash();

  @override
  String toString() {
    return r'convertedAmountProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<num?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<num?> create(Ref ref) {
    final argument =
        this.argument as ({num amount, String fromCurrency, String toCurrency});
    return convertedAmount(
      ref,
      amount: argument.amount,
      fromCurrency: argument.fromCurrency,
      toCurrency: argument.toCurrency,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ConvertedAmountProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$convertedAmountHash() => r'09fdaddfe4ab28fa58a591026f2f69d509bb6086';

/// Dipakai langsung di layar converter mata uang.

final class ConvertedAmountFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<num?>,
          ({num amount, String fromCurrency, String toCurrency})
        > {
  ConvertedAmountFamily._()
    : super(
        retry: null,
        name: r'convertedAmountProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Dipakai langsung di layar converter mata uang.

  ConvertedAmountProvider call({
    required num amount,
    required String fromCurrency,
    required String toCurrency,
  }) => ConvertedAmountProvider._(
    argument: (
      amount: amount,
      fromCurrency: fromCurrency,
      toCurrency: toCurrency,
    ),
    from: this,
  );

  @override
  String toString() => r'convertedAmountProvider';
}
