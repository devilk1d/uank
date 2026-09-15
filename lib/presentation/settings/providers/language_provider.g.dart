// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'language_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AppLanguageNotifier)
final appLanguageProvider = AppLanguageNotifierProvider._();

final class AppLanguageNotifierProvider
    extends $NotifierProvider<AppLanguageNotifier, AppLanguage> {
  AppLanguageNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLanguageProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLanguageNotifierHash();

  @$internal
  @override
  AppLanguageNotifier create() => AppLanguageNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppLanguage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppLanguage>(value),
    );
  }
}

String _$appLanguageNotifierHash() =>
    r'afd3e7a958d53ccc01660fa6df13d7733ff1e058';

abstract class _$AppLanguageNotifier extends $Notifier<AppLanguage> {
  AppLanguage build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AppLanguage, AppLanguage>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AppLanguage, AppLanguage>,
              AppLanguage,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
