// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(categories)
final categoriesProvider = CategoriesProvider._();

final class CategoriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Category>>,
          List<Category>,
          FutureOr<List<Category>>
        >
    with $FutureModifier<List<Category>>, $FutureProvider<List<Category>> {
  CategoriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoriesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoriesHash();

  @$internal
  @override
  $FutureProviderElement<List<Category>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Category>> create(Ref ref) {
    return categories(ref);
  }
}

String _$categoriesHash() => r'170b7f0ed764fe121f936234e998d6e72bfdc6d7';

@ProviderFor(categoriesByType)
final categoriesByTypeProvider = CategoriesByTypeFamily._();

final class CategoriesByTypeProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Category>>,
          List<Category>,
          FutureOr<List<Category>>
        >
    with $FutureModifier<List<Category>>, $FutureProvider<List<Category>> {
  CategoriesByTypeProvider._({
    required CategoriesByTypeFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'categoriesByTypeProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$categoriesByTypeHash();

  @override
  String toString() {
    return r'categoriesByTypeProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Category>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Category>> create(Ref ref) {
    final argument = this.argument as String;
    return categoriesByType(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CategoriesByTypeProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$categoriesByTypeHash() => r'fa293253674e1732556d56c043c31f8d0fe82b07';

final class CategoriesByTypeFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Category>>, String> {
  CategoriesByTypeFamily._()
    : super(
        retry: null,
        name: r'categoriesByTypeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  CategoriesByTypeProvider call(String type) =>
      CategoriesByTypeProvider._(argument: type, from: this);

  @override
  String toString() => r'categoriesByTypeProvider';
}
