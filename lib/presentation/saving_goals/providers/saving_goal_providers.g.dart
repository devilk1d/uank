// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saving_goal_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(savingGoals)
final savingGoalsProvider = SavingGoalsProvider._();

final class SavingGoalsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SavingGoal>>,
          List<SavingGoal>,
          FutureOr<List<SavingGoal>>
        >
    with $FutureModifier<List<SavingGoal>>, $FutureProvider<List<SavingGoal>> {
  SavingGoalsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savingGoalsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savingGoalsHash();

  @$internal
  @override
  $FutureProviderElement<List<SavingGoal>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SavingGoal>> create(Ref ref) {
    return savingGoals(ref);
  }
}

String _$savingGoalsHash() => r'424a8d6df2b8bcf4ad36d61206329224a96c7b15';
