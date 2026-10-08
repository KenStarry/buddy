import 'package:flutter/material.dart';

import '../../utils/extensions/context_extensions.dart';
import '../budgy_icons.dart';
import 'category_glyph.dart';
import 'press_scale.dart';

/// The icon + colour picker shared by the budget and goal journeys.
class LookPicker extends StatelessWidget {
  const LookPicker({
    super.key,
    required this.iconKey,
    required this.colorIndex,
    required this.onIcon,
    required this.onColor,
  });

  final String iconKey;
  final int colorIndex;
  final ValueChanged<String> onIcon;
  final ValueChanged<int> onColor;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HOW IT LOOKS',
          style: context.textTheme.labelSmall?.copyWith(color: c.text300),
        ),
        const SizedBox(height: 12),
        // ⚠️ Eight swatches, not a colour wheel. The eight slots were
        // validated together for colour-vision separation as an ordered set
        // (see `BudgyPalette`); a free-form picker hands users two categories
        // they cannot tell apart in their own charts and invalidates that
        // run.
        Row(
          children: [
            for (var i = 0; i < c.categories.length; i++) ...[
              if (i > 0) const SizedBox(width: 9),
              PressScale(
                onTap: () => onColor(i),
                haptic: HapticLevel.selection,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: c.categoryAt(i),
                    borderRadius: BorderRadius.circular(10),
                    // A selection ring on a colour swatch — the one thing
                    // a border is still for. It marks *which* swatch is
                    // chosen; it is not an outline around a surface.
                    border: Border.all(
                      color: colorIndex == i ? c.text100 : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              for (final key in BudgyIcons.pickable)
                Padding(
                  padding: const EdgeInsets.only(right: 9),
                  child: PressScale(
                    onTap: () => onIcon(key),
                    haptic: HapticLevel.selection,
                    child: CategoryGlyph(
                      colorIndex: colorIndex,
                      iconKey: key,
                      size: 44,
                      solid: key == iconKey,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
