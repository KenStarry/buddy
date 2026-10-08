import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/presentation/nav/budgy_pill_nav.dart';
import '../../../../core/utils/extensions/context_extensions.dart';

/// The app's persistent chrome: the four branches plus the floating nav.
///
/// A `StatefulShellRoute.indexedStack` rather than a `PageView`, so each tab
/// keeps its own scroll offset and navigation stack — tapping away from a
/// half-scrolled ledger and back lands exactly where you left it.
class BudgyShell extends StatelessWidget {
  const BudgyShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const destinations = <PillDestination>[
    PillDestination(
      icon: LucideIcons.house,
      activeIcon: LucideIcons.house,
      label: 'HOME',
    ),
    PillDestination(
      icon: LucideIcons.receipt,
      activeIcon: LucideIcons.receipt,
      label: 'LEDGER',
    ),
    PillDestination(
      icon: LucideIcons.target,
      activeIcon: LucideIcons.target,
      label: 'PLANS',
    ),
    PillDestination(
      icon: LucideIcons.chartNoAxesColumn,
      activeIcon: LucideIcons.chartNoAxesColumn,
      label: 'REPORTS',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;

    return Scaffold(
      backgroundColor: c.surface100,
      // The nav floats *over* the content rather than insetting it, so a card
      // can scroll under the bar's translucent edge. Pages reserve the room
      // themselves via `BudgyConstants.navReserve`.
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: BudgyPillNav(
        destinations: destinations,
        currentIndex: navigationShell.currentIndex,
        onSelected: (index) => navigationShell.goBranch(
          index,
          // Tapping the live tab pops that branch back to its root — the
          // standard "take me to the top of this section" gesture.
          initialLocation: index == navigationShell.currentIndex,
        ),
        onAdd: () => context.pushNamed('new-transaction'),
      ),
    );
  }
}
