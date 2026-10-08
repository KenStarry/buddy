import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/presentation/components/budgy_button.dart';
import '../../../../core/presentation/components/budgy_card.dart';
import '../../../../core/presentation/components/budgy_chip.dart';
import '../../../../core/presentation/components/budgy_masthead.dart';
import '../../../../core/presentation/components/budgy_meter.dart';
import '../../../../core/presentation/components/money_text.dart';
import '../../../../core/presentation/components/section_header.dart';
import '../../../../core/theme/budgy_color_schemes.dart';
import '../../../../core/utils/budgy_constants.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../modules/ledger/state/providers/ledger_providers.dart';
import '../state/controllers/settings_controller.dart';

/// Theme mode and brand skin.
class AppearancePage extends ConsumerWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.budgyColors;
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);

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
                  eyebrow: 'Appearance',
                  title: 'How Budgy looks',
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 26)),

            // Live preview, so a scheme can be judged on the thing it will
            // actually be seen on — a money card — rather than on a swatch.
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: BudgyConstants.gutter,
              ),
              sliver: SliverToBoxAdapter(
                child: const _Preview(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 30)),

            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: BudgyConstants.gutter,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(eyebrow: 'Theme', title: 'Light or dark'),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        for (final mode in ThemeMode.values) ...[
                          if (mode != ThemeMode.values.first)
                            const SizedBox(width: 10),
                          Expanded(
                            child: _ModeTile(
                              mode: mode,
                              selected: settings.themeMode == mode,
                              onTap: () => controller.setThemeMode(mode),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 30),
                    const SectionHeader(
                      eyebrow: 'Brand',
                      title: 'Pick a skin',
                      subtitle:
                          'Retints the whole page, not just the buttons.',
                    ),
                    const SizedBox(height: 14),
                    for (final scheme in BudgyColorSchemes.all)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 11),
                        child: _SchemeTile(
                          scheme: scheme,
                          selected: settings.scheme.id == scheme.id,
                          onTap: () => controller.setScheme(scheme),
                        ),
                      ),
                    SizedBox(height: 40 + context.viewPadding.bottom),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The money hero, in miniature, rendered with the live tokens.
class _Preview extends ConsumerWidget {
  const _Preview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.budgyColors;
    final base = ref.watch(baseCurrencyProvider);
    final pulse = ref.watch(spendingPulseProvider);
    final ink = c.heroInk;

    return BudgyHeroCard(
      gradient: budgyHeroGradient(context),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SAFE TO SPEND',
            style: context.textTheme.labelSmall?.copyWith(
              color: ink.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 10),
          MoneyText(
            pulse.remainingMinor.abs(),
            currency: base,
            size: MoneySize.display,
            color: ink,
            showDecimals: false,
          ),
          const SizedBox(height: 14),
          BudgyMeter(
            fraction: pulse.fraction,
            color: c.accentPop,
            trackColor: ink.withValues(alpha: 0.18),
            height: 9,
            animated: false,
          ),
        ],
      ),
    ).animate(key: ValueKey(c.heroFill.toARGB32())).fadeIn(duration: 260.ms);
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final ThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    return BudgyCard(
      tone: selected ? BudgyCardTone.wash : BudgyCardTone.band,
      elevated: false,
      padding: const EdgeInsets.symmetric(vertical: 16),
      onTap: onTap,
      child: Column(
        children: [
          Icon(
            switch (mode) {
              ThemeMode.light => LucideIcons.sun,
              ThemeMode.dark => LucideIcons.moon,
              ThemeMode.system => LucideIcons.smartphone,
            },
            size: 20,
            color: selected ? c.accent : c.text300,
          ),
          const SizedBox(height: 9),
          Text(
            switch (mode) {
              ThemeMode.light => 'Light',
              ThemeMode.dark => 'Dark',
              ThemeMode.system => 'System',
            },
            style: context.textTheme.labelLarge?.copyWith(
              color: selected ? c.text100 : c.text300,
            ),
          ),
        ],
      ),
    );
  }
}

class _SchemeTile extends StatelessWidget {
  const _SchemeTile({
    required this.scheme,
    required this.selected,
    required this.onTap,
  });

  final BudgyColorScheme scheme;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final dark = context.isDark;
    // Swatches come from the scheme itself rather than the live theme, so
    // every row previews its own colours instead of all five rendering in
    // whichever one is currently active.
    final swatches = dark
        ? [scheme.darkPrimary, scheme.darkAccent, scheme.darkAccentMid]
        : [scheme.lightPrimary, scheme.lightAccent, scheme.lightAccentMid];

    return BudgyCard(
      tone: selected ? BudgyCardTone.wash : BudgyCardTone.plain,
      onTap: onTap,
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            height: 34,
            child: Stack(
              children: [
                for (var i = 0; i < swatches.length; i++)
                  Positioned(
                    left: i * 13,
                    child: Container(
                      width: 32,
                      height: 34,
                      decoration: BoxDecoration(
                        color: swatches[i],
                        borderRadius: BorderRadius.circular(11),
                        // A surface-coloured ring between OVERLAPPING
                        // marks, so three stacked swatches stay three shapes.
                        // A mark separator, not a surface outline.
                        border: Border.all(color: c.surface200, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(scheme.label, style: context.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  scheme.blurb,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: c.text300,
                  ),
                ),
              ],
            ),
          ),
          if (selected)
            StatusPill(
              label: 'On',
              tint: c.accent,
              icon: LucideIcons.check,
            ),
        ],
      ),
    );
  }
}
