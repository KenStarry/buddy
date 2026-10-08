import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../utils/extensions/context_extensions.dart';
import 'press_scale.dart';

/// A selectable row: a tinted glyph, a label, and a check when it is the one.
///
/// The house list row for "pick one of these" — the anchored panels on the
/// entry screen, the extras sheet, any picker. One implementation, so a goal
/// chosen in a sheet and a wallet chosen in a popover look like the same act.
class OptionRow extends StatelessWidget {
  const OptionRow({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.sublabel,
    this.icon,
    this.emoji,
    this.tint,
  });

  final String label;
  final String? sublabel;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final String? emoji;

  /// The glyph's colour, and what its disc fills with once chosen.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final ink = c.heroInk;
    final hue = tint ?? c.accent;
    final hasGlyph = icon != null || emoji != null;

    return PressScale(
      onTap: onTap,
      haptic: HapticLevel.selection,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          // Selection is a brightness step; the hue stays in the glyph. A
          // category colour at row alpha over near-black is mud.
          color: selected ? ink.withValues(alpha: 0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            if (hasGlyph) ...[
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: hue.withValues(alpha: selected ? 0.9 : 0.18),
                  shape: BoxShape.circle,
                ),
                child: emoji != null
                    ? Text(emoji!, style: const TextStyle(fontSize: 15))
                    : Icon(
                        icon,
                        size: 15,
                        color: selected ? Colors.white : hue,
                      ),
              ),
              const SizedBox(width: 11),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleSmall?.copyWith(color: ink),
                  ),
                  if (sublabel != null)
                    Text(
                      sublabel!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: ink.withValues(alpha: 0.5),
                      ),
                    ),
                ],
              ),
            ),
            if (selected) Icon(LucideIcons.check, size: 17, color: c.accent),
          ],
        ),
      ),
    );
  }
}
