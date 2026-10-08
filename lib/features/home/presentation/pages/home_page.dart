import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/budgy_constants.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../settings/domain/home_section.dart';
import '../../../settings/presentation/state/controllers/settings_controller.dart';
import '../../../transactions/presentation/state/controllers/transactions_controller.dart';
import '../components/home_header.dart';
import '../components/home_sections.dart';
import '../components/pulse_card.dart';

/// The home screen.
///
/// It opens with the balance pocket (`HomeHeader`) and then composes its body
/// **from the user's own section list** rather than a hardcoded order — the
/// arrangement lives in `SettingsState.homeSections` and is edited on the
/// Home-layout screen. Cashew's best idea is that the home screen ends up
/// being yours rather than the developer's, and this is where Budgy keeps it.
///
/// The spacing between sections lives here, not inside each section, so the
/// page has one rhythm no matter which blocks are switched on.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.budgyColors;
    final settings = ref.watch(settingsControllerProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // ⚠️ Keyed to the page's own brightness, not pinned. The header no
      // longer inverts the top of the screen — the whole page is one ground —
      // so the status bar simply needs the opposite of whatever that ground
      // is, and there is nothing to track on scroll.
      value:
          (context.isDark
                  ? SystemUiOverlayStyle.light
                  : SystemUiOverlayStyle.dark)
              .copyWith(statusBarColor: Colors.transparent),
      child: RefreshIndicator(
        color: c.accent,
        backgroundColor: c.surface300,
        edgeOffset: context.viewPadding.top + 8,
        onRefresh: () =>
            ref.read(transactionsControllerProvider.notifier).load(),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // Bleeds to the very top of the display — no safe-area inset here.
            // The header applies `viewPadding.top` to its own content, so its
            // ambient glow runs under the status bar.
            const SliverToBoxAdapter(child: HomeHeader()),

            const SliverToBoxAdapter(child: SizedBox(height: 36)),

            for (final section in settings.homeSections) ...[
              SliverToBoxAdapter(child: _sectionFor(section)),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],

            // Reserve for the floating nav, so the last section is not parked
            // permanently underneath it.
            const SliverToBoxAdapter(
              child: SizedBox(height: BudgyConstants.navReserve),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _sectionFor(HomeSection section) => switch (section) {
    HomeSection.pulse => const Padding(
      padding: EdgeInsets.symmetric(horizontal: BudgyConstants.gutter),
      child: PulseCard(),
    ),
    HomeSection.budgets => const HomeBudgetsSection(),
    HomeSection.goals => const HomeGoalsSection(),
    HomeSection.wallets => const HomeWalletsSection(),
    HomeSection.upcoming => const HomeUpcomingSection(),
    HomeSection.spendByCategory => const HomeSpendSection(),
    HomeSection.thisMonth => const HomeThisMonthSection(),
    HomeSection.heatmap => const HomeHeatmapSection(),
    HomeSection.recent => const HomeRecentSection(),
    HomeSection.loans => const HomeLoansSection(),
  };
}
