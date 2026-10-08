import 'package:flutter/material.dart';

import '../../utils/extensions/context_extensions.dart';
import '../budgy_icons.dart';

/// A category / wallet / budget / goal badge: a tinted rounded tile holding
/// an emoji or a glyph.
///
/// ⚠️ It is **never** a bare colour swatch, and that is a correctness
/// requirement rather than a style preference. Three of the eight category
/// hues sit under 3:1 contrast against the cream page, so the validated
/// palette is only legal with the relief rule honoured — the colour must
/// always arrive with a second channel attached. The icon is that channel.
/// A colour-only version of this widget would quietly invalidate the palette
/// run documented in `BudgyPalette`.
class CategoryGlyph extends StatelessWidget {
  const CategoryGlyph({
    super.key,
    required this.colorIndex,
    this.iconKey,
    this.emoji,
    this.size = 44,
    this.radius,
    this.solid = false,
  });

  final int colorIndex;
  final String? iconKey;
  final String? emoji;
  final double size;
  final double? radius;

  /// Filled with the category colour and an inverted glyph, rather than a
  /// tinted wash. For the one badge that leads a detail page.
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final tint = c.categoryAt(colorIndex);
    final corner = radius ?? size * 0.34;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: solid ? tint : tint.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(corner),
      ),
      child: emoji != null
          ? Text(
              emoji!,
              style: TextStyle(fontSize: size * 0.44, height: 1),
            )
          : Icon(
              BudgyIcons.resolve(iconKey),
              // Icons stay at a legible weight by being sized generously
              // relative to the tile; a 16pt glyph in a 44pt tile reads as a
              // mistake.
              size: size * 0.46,
              color: solid ? Colors.white : tint,
            ),
    );
  }
}

/// A small coloured dot + label, for chart legends and filter rows.
///
/// The label is in **text** ink, never the series colour — a legend whose
/// words are tinted is harder to read and makes the colour do two jobs.
class LegendDot extends StatelessWidget {
  const LegendDot({
    super.key,
    required this.color,
    required this.label,
    this.trailing,
    this.dotSize = 9,
  });

  final Color color;
  final String label;
  final Widget? trailing;
  final double dotSize;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    return Row(
      children: [
        Container(
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(dotSize / 3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.bodyMedium?.copyWith(color: c.text200),
          ),
        ),
        ?trailing,
      ],
    );
  }
}
