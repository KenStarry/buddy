import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/config/budgy_config.dart';
import '../../../../core/data/ledger_bootstrap.dart';
import '../../../../core/domain/currency.dart';
import '../../../../core/presentation/components/budgy_button.dart';
import '../../../../core/presentation/components/budgy_masthead.dart';
import '../../../../core/presentation/components/budgy_sheet.dart';
import '../../../../core/presentation/components/press_scale.dart';
import '../../../../core/utils/budgy_constants.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../modules/ledger/state/providers/ledger_providers.dart';
import '../../../accounts/presentation/state/controllers/accounts_controller.dart';
import '../../../categories/presentation/state/controllers/categories_controller.dart';
import '../components/settings_tiles.dart';
import '../state/controllers/settings_controller.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.budgyColors;
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final categoryCount = ref.watch(categoriesControllerProvider).items.length;
    final walletCount = ref.watch(accountsControllerProvider).live.length;
    final entryCount = ref.watch(ledgerProvider).length;

    return Scaffold(
      backgroundColor: c.surface100,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                BudgyConstants.gutter,
                8,
                BudgyConstants.gutter,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    BudgyIconButton(
                      icon: LucideIcons.arrowLeft,
                      onTap: () => context.pop(),
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                BudgyConstants.gutter,
                18,
                BudgyConstants.gutter,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: BudgyMasthead(
                  eyebrow: 'Settings',
                  title: 'Make it yours',
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 26)),

            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: BudgyConstants.gutter,
              ),
              sliver: SliverList.list(
                children: [
                  SettingsGroup(
                    label: 'You',
                    children: [
                      SettingsRow(
                        iconKey: 'star',
                        title: 'Your name',
                        subtitle: 'Budgy says hello with it',
                        value: settings.userName ?? 'Not set',
                        onTap: () => _editName(context, ref),
                      ),
                      SettingsSwitch(
                        iconKey: 'shield',
                        title: 'Hide amounts',
                        subtitle: 'Blurs every figure in the app',
                        value: settings.hideAmounts,
                        onChanged: controller.setHideAmounts,
                      ),
                    ],
                  ),

                  const SizedBox(height: 26),

                  SettingsGroup(
                    label: 'Look & feel',
                    children: [
                      SettingsRow(
                        iconKey: 'sparkles',
                        title: 'Appearance',
                        subtitle: 'Theme and brand colour',
                        value: settings.scheme.label,
                        onTap: () => context.pushNamed('appearance'),
                      ),
                      SettingsRow(
                        iconKey: 'house',
                        title: 'Home screen',
                        subtitle: 'Which blocks, in which order',
                        value: '${settings.homeSections.length} on',
                        onTap: () => context.pushNamed('home-layout'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 26),

                  SettingsGroup(
                    label: 'Your money',
                    children: [
                      SettingsRow(
                        iconKey: 'wallet',
                        title: 'Wallets',
                        value: '$walletCount',
                        onTap: () => context.pushNamed('wallets'),
                      ),
                      SettingsRow(
                        iconKey: 'shopping-bag',
                        title: 'Categories',
                        value: '$categoryCount',
                        onTap: () => context.pushNamed('categories'),
                      ),
                      SettingsRow(
                        iconKey: 'banknote',
                        title: 'Base currency',
                        subtitle: 'What cross-wallet totals are shown in',
                        value: settings.baseCurrency.code,
                        onTap: () => _pickCurrency(context, ref),
                      ),
                      SettingsRow(
                        iconKey: 'handshake',
                        title: 'Lent & borrowed',
                        onTap: () => context.pushNamed('loans'),
                      ),
                      SettingsRow(
                        iconKey: 'clock',
                        title: 'Upcoming & overdue',
                        onTap: () => context.pushNamed('upcoming'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 26),

                  SettingsGroup(
                    label: 'Your data',
                    children: [
                      SettingsRow(
                        iconKey: 'receipt',
                        title: 'Entries on this device',
                        subtitle: 'Budgy keeps everything locally',
                        value: '$entryCount',
                      ),
                      SettingsRow(
                        iconKey: 'sparkles',
                        title: 'Load the demo month',
                        subtitle: 'Replaces everything with sample data',
                        onTap: () => _confirmReseed(context, ref),
                      ),
                      SettingsRow(
                        iconKey: 'trash2',
                        title: 'Start fresh',
                        subtitle: 'Deletes every entry, budget and goal',
                        destructive: true,
                        onTap: () => _confirmWipe(context, ref),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  Center(
                    child: Column(
                      children: [
                        Text(
                          BudgyConfig.appName,
                          style: context.textTheme.titleMedium?.copyWith(
                            color: c.text300,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          BudgyConfig.tagline,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: c.text300,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 40 + context.viewPadding.bottom),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editName(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(
      text: ref.read(settingsControllerProvider).userName ?? '',
    );
    await BudgySheet.show<void>(
      context,
      builder: (sheetContext) => BudgySheet(
        title: 'What should Budgy call you?',
        child: Column(
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              style: context.textTheme.titleLarge,
              decoration: const InputDecoration(hintText: 'Your name'),
            ),
            const SizedBox(height: 20),
            BudgyFilledButton(
              label: 'Save',
              width: double.infinity,
              onTap: () async {
                await ref
                    .read(settingsControllerProvider.notifier)
                    .setUserName(controller.text);
                if (sheetContext.mounted) Navigator.of(sheetContext).pop();
              },
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }

  Future<void> _pickCurrency(BuildContext context, WidgetRef ref) =>
      BudgySheet.show<void>(
        context,
        builder: (sheetContext) {
          final current = ref.read(settingsControllerProvider).baseCurrency;
          return BudgySheet(
            title: 'Base currency',
            subtitle:
                'Wallets keep their own currency — this is only what totals '
                'across them are shown in.',
            scrollable: true,
            child: Column(
              children: [
                for (final currency in CurrencyRegistry.all)
                  PressScale(
                    onTap: () async {
                      await ref
                          .read(settingsControllerProvider.notifier)
                          .setBaseCurrency(currency);
                      if (sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 44,
                            child: Text(
                              currency.symbol,
                              style: context.textTheme.titleLarge,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currency.name,
                                  style: context.textTheme.titleSmall,
                                ),
                                Text(
                                  currency.code,
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: context.budgyColors.text300,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (currency.code == current.code)
                            Icon(
                              LucideIcons.check,
                              size: 18,
                              color: context.budgyColors.accent,
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      );

  Future<void> _confirmReseed(BuildContext context, WidgetRef ref) async {
    // ⚠️ Captured BEFORE the dialog awaits. Reseeding rebuilds every ledger
    // controller, and reaching back through `context` afterwards is a use
    // across an async gap — this very page can be gone by then.
    final container = ProviderScope.containerOf(context, listen: false);
    final ok = await _confirm(
      context,
      title: 'Load the demo month?',
      message:
          'This replaces everything you have with sample data. Handy for a '
          'look around; not what you want if you have been using Budgy for '
          'real.',
      confirmLabel: 'Load it',
    );
    if (!ok) return;
    await LedgerBootstrap.reseed(container);
  }

  Future<void> _confirmWipe(BuildContext context, WidgetRef ref) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final ok = await _confirm(
      context,
      title: 'Delete everything?',
      message:
          'Every entry, budget, goal and wallet goes. Your theme and your '
          'name stay. This cannot be undone.',
      confirmLabel: 'Delete it all',
      destructive: true,
    );
    if (!ok) return;
    await LedgerBootstrap.clear(container);
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Never mind'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              confirmLabel,
              style: destructive
                  ? TextStyle(color: context.budgyColors.errorMain)
                  : null,
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
