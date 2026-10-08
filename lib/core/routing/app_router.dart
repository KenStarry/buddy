import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/accounts/presentation/pages/wallet_detail_page.dart';
import '../../features/accounts/presentation/pages/wallets_page.dart';
import '../../features/budgets/presentation/pages/budget_detail_page.dart';
import '../../features/budgets/presentation/pages/budget_form_page.dart';
import '../../features/categories/presentation/pages/categories_page.dart';
import '../../features/goals/presentation/pages/goal_detail_page.dart';
import '../../features/goals/presentation/pages/goal_form_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/plans/presentation/pages/plans_page.dart';
import '../../features/reports/presentation/pages/reports_page.dart';
import '../../features/settings/presentation/pages/appearance_page.dart';
import '../../features/settings/presentation/pages/home_layout_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/shell/presentation/pages/budgy_shell.dart';
import '../../features/transactions/presentation/pages/ledger_page.dart';
import '../../features/transactions/presentation/pages/loans_page.dart';
import '../../features/transactions/presentation/pages/transaction_form_page.dart';
import '../../features/transactions/presentation/pages/upcoming_page.dart';
import '../data/hive_service.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _homeKey = GlobalKey<NavigatorState>();
final _ledgerKey = GlobalKey<NavigatorState>();
final _plansKey = GlobalKey<NavigatorState>();
final _reportsKey = GlobalKey<NavigatorState>();

/// Shared page motion.
///
/// Budgy pushes two kinds of destination and they move differently on
/// purpose. A **detail** page slides in from the right: it is a different
/// place, reached from a row. A **form** rises from the bottom: it is a
/// continuation of the tap that opened it, and the platform's horizontal push
/// would read as navigating away from the thing you are editing.
CustomTransitionPage<T> _slide<T>(Widget child, GoRouterState state) =>
    CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 230),
      transitionsBuilder: (context, animation, secondary, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween(
            begin: const Offset(0.06, 0),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );

CustomTransitionPage<T> _rise<T>(Widget child, GoRouterState state) =>
    CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 340),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (context, animation, secondary, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    // ⚠️ Read once, not watched. A fresh install opens on the welcome screen;
    // once dismissed it must never reappear, and watching the flag would
    // redirect the user mid-session the instant it flipped.
    initialLocation: HiveService.hasOnboarded ? '/home' : '/welcome',
    routes: [
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingPage(),
          transitionDuration: const Duration(milliseconds: 280),
          transitionsBuilder: (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),

      // ── The tabbed shell ────────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        pageBuilder: (context, state, shell) => NoTransitionPage(
          key: state.pageKey,
          child: BudgyShell(navigationShell: shell),
        ),
        branches: [
          StatefulShellBranch(
            navigatorKey: _homeKey,
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _ledgerKey,
            routes: [
              GoRoute(
                path: '/ledger',
                name: 'ledger',
                builder: (context, state) => const LedgerPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _plansKey,
            routes: [
              GoRoute(
                path: '/plans',
                name: 'plans',
                builder: (context, state) => PlansPage(
                  initialTab: state.uri.queryParameters['tab'],
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _reportsKey,
            routes: [
              GoRoute(
                path: '/reports',
                name: 'reports',
                builder: (context, state) => const ReportsPage(),
              ),
            ],
          ),
        ],
      ),

      // ── Full-screen destinations ────────────────────────────────────────
      // All on the root navigator, so they cover the floating nav. A detail
      // page that leaves the nav bar visible invites a tab tap that silently
      // abandons an unsaved form.
      GoRoute(
        path: '/transaction/new',
        name: 'new-transaction',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) => _rise(
          TransactionFormPage(prefill: state.extra as TransactionPrefill?),
          state,
        ),
      ),
      GoRoute(
        path: '/transaction/:id',
        name: 'transaction',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) => _rise(
          TransactionFormPage(
            transactionId: state.pathParameters['id'],
          ),
          state,
        ),
      ),
      GoRoute(
        path: '/budget/new',
        name: 'new-budget',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) => _rise(const BudgetFormPage(), state),
      ),
      GoRoute(
        path: '/budget/:id',
        name: 'budget',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) => _slide(
          BudgetDetailPage(budgetId: state.pathParameters['id']!),
          state,
        ),
        routes: [
          GoRoute(
            path: 'edit',
            name: 'edit-budget',
            parentNavigatorKey: _rootKey,
            pageBuilder: (context, state) => _rise(
              BudgetFormPage(budgetId: state.pathParameters['id']),
              state,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/goal/new',
        name: 'new-goal',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) => _rise(const GoalFormPage(), state),
      ),
      GoRoute(
        path: '/goal/:id',
        name: 'goal',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) =>
            _slide(GoalDetailPage(goalId: state.pathParameters['id']!), state),
        routes: [
          GoRoute(
            path: 'edit',
            name: 'edit-goal',
            parentNavigatorKey: _rootKey,
            pageBuilder: (context, state) =>
                _rise(GoalFormPage(goalId: state.pathParameters['id']), state),
          ),
        ],
      ),
      GoRoute(
        path: '/upcoming',
        name: 'upcoming',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) => _slide(const UpcomingPage(), state),
      ),
      GoRoute(
        path: '/loans',
        name: 'loans',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) => _slide(const LoansPage(), state),
      ),
      GoRoute(
        path: '/wallets',
        name: 'wallets',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) => _slide(const WalletsPage(), state),
        routes: [
          GoRoute(
            path: ':id',
            name: 'wallet',
            parentNavigatorKey: _rootKey,
            pageBuilder: (context, state) => _slide(
              WalletDetailPage(accountId: state.pathParameters['id']!),
              state,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/categories',
        name: 'categories',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) => _slide(const CategoriesPage(), state),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) => _slide(const SettingsPage(), state),
        routes: [
          GoRoute(
            path: 'appearance',
            name: 'appearance',
            parentNavigatorKey: _rootKey,
            pageBuilder: (context, state) =>
                _slide(const AppearancePage(), state),
          ),
          GoRoute(
            path: 'home-layout',
            name: 'home-layout',
            parentNavigatorKey: _rootKey,
            pageBuilder: (context, state) =>
                _slide(const HomeLayoutPage(), state),
          ),
        ],
      ),
    ],
  );
});
