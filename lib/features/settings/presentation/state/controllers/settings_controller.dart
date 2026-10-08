import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../core/data/hive_service.dart';
import '../../../../../core/domain/currency.dart';
import '../../../../../core/theme/budgy_color_schemes.dart';
import '../../../domain/home_section.dart';

part 'settings_controller.g.dart';

@immutable
class SettingsState {
  const SettingsState({
    required this.themeMode,
    required this.scheme,
    required this.baseCurrency,
    required this.homeSections,
    this.userName,
    this.hideAmounts = false,
  });

  final ThemeMode themeMode;
  final BudgyColorScheme scheme;

  /// The currency every cross-wallet total is expressed in.
  final Currency baseCurrency;

  /// Enabled home sections, in order.
  final List<HomeSection> homeSections;

  final String? userName;

  /// Privacy screen. Blurs every amount so Budgy can be opened on a matatu.
  final bool hideAmounts;

  String get greetingName => userName ?? 'there';

  SettingsState copyWith({
    ThemeMode? themeMode,
    BudgyColorScheme? scheme,
    Currency? baseCurrency,
    List<HomeSection>? homeSections,
    String? userName,
    bool clearUserName = false,
    bool? hideAmounts,
  }) => SettingsState(
    themeMode: themeMode ?? this.themeMode,
    scheme: scheme ?? this.scheme,
    baseCurrency: baseCurrency ?? this.baseCurrency,
    homeSections: homeSections ?? this.homeSections,
    userName: clearUserName ? null : (userName ?? this.userName),
    hideAmounts: hideAmounts ?? this.hideAmounts,
  );
}

/// Device preferences.
///
/// Reads Hive directly rather than going through a repository, and that is the
/// one place in Budgy that does. These are not ledger data: they never sync,
/// never merge, and have no server counterpart to abstract over — wrapping six
/// scalar settings in an `Either`-returning contract would buy nothing and
/// make `build()` async for no reason. The ledger aggregates all keep theirs.
@Riverpod(keepAlive: true)
class SettingsController extends _$SettingsController {
  @override
  SettingsState build() {
    // Synchronous: the boxes are already open by the time the widget tree
    // exists (see `main()`), so there is no loading state to show.
    final stored = HiveService.homeSections;
    return SettingsState(
      themeMode: HiveService.themeMode,
      scheme: BudgyColorSchemes.byId(HiveService.schemeId),
      baseCurrency: HiveService.baseCurrency,
      homeSections: _resolveSections(stored),
      userName: HiveService.userName,
      hideAmounts: HiveService.hideAmounts,
    );
  }

  /// Turns stored keys into sections.
  ///
  /// ⚠️ Unknown keys are dropped and the pulse is forced back to the front.
  /// A stored arrangement from a build that shipped a section we have since
  /// renamed would otherwise either crash on the enum lookup or leave a gap —
  /// and a stored list that somehow lacks the pulse would render a home
  /// screen with no headline.
  static List<HomeSection> _resolveSections(List<String>? stored) {
    if (stored == null || stored.isEmpty) return HomeSectionX.defaults;
    final resolved = <HomeSection>[];
    for (final key in stored) {
      final section = HomeSectionX.fromKey(key);
      if (section != null && !resolved.contains(section)) {
        resolved.add(section);
      }
    }
    resolved.remove(HomeSection.pulse);
    return [HomeSection.pulse, ...resolved];
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await HiveService.setThemeMode(mode);
  }

  Future<void> setScheme(BudgyColorScheme scheme) async {
    state = state.copyWith(scheme: scheme);
    await HiveService.setSchemeId(scheme.id);
  }

  Future<void> setBaseCurrency(Currency currency) async {
    state = state.copyWith(baseCurrency: currency);
    await HiveService.setBaseCurrency(currency.code);
  }

  Future<void> setUserName(String? name) async {
    final trimmed = name?.trim();
    state = (trimmed == null || trimmed.isEmpty)
        ? state.copyWith(clearUserName: true)
        : state.copyWith(userName: trimmed);
    await HiveService.setUserName(trimmed);
  }

  Future<void> setHideAmounts(bool value) async {
    state = state.copyWith(hideAmounts: value);
    await HiveService.setHideAmounts(value);
  }

  Future<void> toggleHideAmounts() => setHideAmounts(!state.hideAmounts);

  Future<void> setHomeSections(List<HomeSection> sections) async {
    final normalised = [
      HomeSection.pulse,
      ...sections.where((s) => s != HomeSection.pulse),
    ];
    state = state.copyWith(homeSections: normalised);
    await HiveService.setHomeSections([for (final s in normalised) s.key]);
  }

  Future<void> toggleSection(HomeSection section) {
    if (!section.reorderable) return Future.value();
    final next = state.homeSections.contains(section)
        ? [for (final s in state.homeSections) if (s != section) s]
        // Re-added at its position in the shipped order, not at the end —
        // flicking a section off and on again should not reshuffle the page.
        : [
            for (final s in HomeSectionX.defaults)
              if (s == section || state.homeSections.contains(s)) s,
          ];
    return setHomeSections(next);
  }
}
