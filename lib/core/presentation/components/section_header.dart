import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../utils/extensions/context_extensions.dart';
import 'press_scale.dart';

/// The band that opens every section: a caps eyebrow, a title, and an
/// optional trailing action.
///
/// One widget rather than an ad-hoc `Row` per section, because the thing that
/// makes a long scrolling page feel composed is that every section announces
/// itself identically.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.trailing,
    this.padding = EdgeInsets.zero,
  });

  final String title;

  /// Small caps line above the title. Use it for the *category* of the
  /// section ("THIS MONTH"), never to repeat the title.
  final String? eyebrow;

  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null) ...[
                  Text(
                    eyebrow!.toUpperCase(),
                    style: context.textTheme.labelSmall?.copyWith(
                      color: c.text300,
                    ),
                  ),
                  const SizedBox(height: 5),
                ],
                Text(title, style: context.textTheme.titleLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: c.text300,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else if (onAction != null)
            PressScale(
              onTap: onAction,
              haptic: HapticLevel.selection,
              child: Padding(
                // Padding on the tappable, not margin around it: the label is
                // ~40pt wide and would otherwise be a hit target smaller than
                // a fingertip.
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Text(
                      actionLabel ?? 'See all',
                      style: context.textTheme.labelLarge?.copyWith(
                        color: c.accent,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 15,
                      color: c.accent,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
