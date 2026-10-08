// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'categories_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CategoriesController)
final categoriesControllerProvider = CategoriesControllerProvider._();

final class CategoriesControllerProvider
    extends $NotifierProvider<CategoriesController, CategoriesState> {
  CategoriesControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoriesControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoriesControllerHash();

  @$internal
  @override
  CategoriesController create() => CategoriesController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CategoriesState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CategoriesState>(value),
    );
  }
}

String _$categoriesControllerHash() =>
    r'ff8d8df3117056bba307a84ec6be82dbbaa6ff53';

abstract class _$CategoriesController extends $Notifier<CategoriesState> {
  CategoriesState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<CategoriesState, CategoriesState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CategoriesState, CategoriesState>,
              CategoriesState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
