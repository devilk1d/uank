// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(transfers)
final transfersProvider = TransfersProvider._();

final class TransfersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Transfer>>,
          List<Transfer>,
          FutureOr<List<Transfer>>
        >
    with $FutureModifier<List<Transfer>>, $FutureProvider<List<Transfer>> {
  TransfersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transfersProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transfersHash();

  @$internal
  @override
  $FutureProviderElement<List<Transfer>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Transfer>> create(Ref ref) {
    return transfers(ref);
  }
}

String _$transfersHash() => r'b2e8142b9c2fde434677bbf7c2f92d34652ca200';
