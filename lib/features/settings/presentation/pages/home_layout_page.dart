import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/presentation/budgy_icons.dart';
import '../../../../core/presentation/components/budgy_button.dart';
import '../../../../core/presentation/components/budgy_card.dart';
import '../../../../core/presentation/components/budgy_masthead.dart';
import '../../../../core/presentation/components/section_header.dart';
import '../../../../core/utils/budgy_constants.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../domain/home_section.dart';
import '../state/controllers/settings_controller.dart';

/// Rearrange and switch off home-screen blocks.
///
/// Cashew's best idea, kept: the home screen ends up being the user's
/// dashboard rather than the developer's. The pulse is fixed at the top and
/// cannot be removed — see [HomeSectionX.reorderable].
class HomeLayoutPage extends ConsumerWidget {
  const HomeLayoutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.budgyColors;
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);

    final on = settings.homeSections;
    final off = [
      for (final section in HomeSection.values)
        if (!on.contains(section)) section,
    ];

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
                  eyebrow: 'Home screen',
                  title: 'Your dashboard',
                  subtitle: 'Drag to reorder. Tap the switch to hide a block.',
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 26)),

            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: BudgyConstants.gutter,
              ),
              sliver: SliverToBoxAdapter(
                child: const SectionHeader(eyebrow: 'Showing', title: 'On your home screen'),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 14)),

            // ⚠️ `ReorderableListView` needs bounded height, which it cannot
            // get inside a `CustomScrollView`'s viewport — hence
            // `SliverReorderableList`, which is the sliver-native variant and
            // the only thing that reorders correctly in a scrolling page.
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: BudgyConstants.gutter,
              ),
              sliver: SliverReorderableList(
                itemCount: on.length,
                // `onReorderItem`, not the deprecated `onReorder`: it
                // already adjusts `to` for the removed item, so the usual
                // `from < to ? to - 1 : to` fudge — which is wrong exactly as
                // often as it is right — is gone.
                onReorderItem: (from, to) {
                  final next = [...on];
                  next.insert(to, next.removeAt(from));
                  controller.setHomeSections(next);
                },
                itemBuilder: (context, index) {
                  final section = on[index];
                  return ReorderableDelayedDragStartListener(
                    key: ValueKey(section.key),
                    index: index,
                    enabled: section.reorderable,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SectionTile(
                        section: section,
                        enabled: true,
                        onToggle: section.reorderable
                            ? () => controller.toggleSection(section)
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),

            if (off.isNotEmpty) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 22)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: BudgyConstants.gutter,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        eyebrow: 'Hidden',
                        title: 'Not showing',
                      ),
                      const SizedBox(height: 14),
                      for (final section in off)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _SectionTile(
                            section: section,
                            enabled: false,
                            onToggle: () => controller.toggleSection(section),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],

            SliverToBoxAdapter(
              child: SizedBox(height: 40 + context.viewPadding.bottom),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.section,
    required this.enabled,
    this.onToggle,
  });

  final HomeSection section;
  final bool enabled;

  /// Null means the block is fixed and cannot be hidden.
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final fixed = onToggle == null;

    return BudgyCard(
      padding: const EdgeInsets.all(14),
      tone: enabled ? BudgyCardTone.plain : BudgyCardTone.band,
      elevated: enabled,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: (enabled ? c.accent : c.text300).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              BudgyIcons.resolve(section.iconKey),
              size: 16,
              color: enabled ? c.accent : c.text300,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.label,
                  style: context.textTheme.titleSmall?.copyWith(
                    color: enabled ? c.text100 : c.text300,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fixed ? 'Always first' : section.blurb,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: c.text300,
                  ),
                ),
              ],
            ),
          ),
          if (fixed)
            Icon(LucideIcons.lock, size: 15, color: c.text300)
          else ...[
            Switch.adaptive(
              value: enabled,
              activeTrackColor: c.accent,
              onChanged: (_) => onToggle!(),
            ),
            if (enabled) ...[
              const SizedBox(width: 4),
              Icon(LucideIcons.gripVertical, size: 17, color: c.text300),
            ],
          ],
        ],
      ),
    );
  }
}
