// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(authState)
final authStateProvider = AuthStateProvider._();

final class AuthStateProvider
    extends
        $FunctionalProvider<AsyncValue<AuthState>, AuthState, Stream<AuthState>>
    with $FutureModifier<AuthState>, $StreamProvider<AuthState> {
  AuthStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authStateHash();

  @$internal
  @override
  $StreamProviderElement<AuthState> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<AuthState> create(Ref ref) {
    return authState(ref);
  }
}

String _$authStateHash() => r'4475c6907099fbb7a56a92dc3b6723d3340c362e';

@ProviderFor(isLoggedIn)
final isLoggedInProvider = IsLoggedInProvider._();

final class IsLoggedInProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  IsLoggedInProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isLoggedInProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isLoggedInHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return isLoggedIn(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isLoggedInHash() => r'a0353f4141f8c26c5702b61288211510312a3a7f';

@ProviderFor(PasswordRecoveryMode)
final passwordRecoveryModeProvider = PasswordRecoveryModeProvider._();

final class PasswordRecoveryModeProvider
    extends $NotifierProvider<PasswordRecoveryMode, bool> {
  PasswordRecoveryModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'passwordRecoveryModeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$passwordRecoveryModeHash();

  @$internal
  @override
  PasswordRecoveryMode create() => PasswordRecoveryMode();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$passwordRecoveryModeHash() =>
    r'f971191ba37c89c73fa121a9fedd02107504f30e';

abstract class _$PasswordRecoveryMode extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(AuthTransitionLock)
final authTransitionLockProvider = AuthTransitionLockProvider._();

final class AuthTransitionLockProvider
    extends $NotifierProvider<AuthTransitionLock, AuthTransitionMode> {
  AuthTransitionLockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authTransitionLockProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authTransitionLockHash();

  @$internal
  @override
  AuthTransitionLock create() => AuthTransitionLock();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthTransitionMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthTransitionMode>(value),
    );
  }
}

String _$authTransitionLockHash() =>
    r'adc4a9971de93c30090d8fed1a9353869f235a66';

abstract class _$AuthTransitionLock extends $Notifier<AuthTransitionMode> {
  AuthTransitionMode build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AuthTransitionMode, AuthTransitionMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AuthTransitionMode, AuthTransitionMode>,
              AuthTransitionMode,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(UserProfile)
final userProfileProvider = UserProfileProvider._();

final class UserProfileProvider
    extends $NotifierProvider<UserProfile, UserProfileData?> {
  UserProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userProfileProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userProfileHash();

  @$internal
  @override
  UserProfile create() => UserProfile();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserProfileData? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserProfileData?>(value),
    );
  }
}

String _$userProfileHash() => r'6b4edd9e11ed793c87f8c30955180b4c166fdb7d';

abstract class _$UserProfile extends $Notifier<UserProfileData?> {
  UserProfileData? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<UserProfileData?, UserProfileData?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<UserProfileData?, UserProfileData?>,
              UserProfileData?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
