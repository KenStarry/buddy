// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accounts_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AccountsController)
final accountsControllerProvider = AccountsControllerProvider._();

final class AccountsControllerProvider
    extends $NotifierProvider<AccountsController, AccountsState> {
  AccountsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountsControllerHash();

  @$internal
  @override
  AccountsController create() => AccountsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AccountsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AccountsState>(value),
    );
  }
}

String _$accountsControllerHash() =>
    r'7abb038fd1a05e769aceedab2a3ff4b95ef638a0';

abstract class _$AccountsController extends $Notifier<AccountsState> {
  AccountsState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AccountsState, AccountsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AccountsState, AccountsState>,
              AccountsState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
