import 'package:flutter/material.dart';

import '../../utils/extensions/context_extensions.dart';
import 'press_scale.dart';

/// Budgy's switch.
///
/// Material's adaptive switch is two different controls — a Material one on
/// Android, a Cupertino one on iOS — and neither is this app: both bring their
/// own track height, their own knob shadow and their own idea of an accent. On
/// a near-black page the Cupertino one in particular renders a bright grey
/// track that reads as *on* when it is off.
class BudgySwitch extends StatelessWidget {
  const BudgySwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  static const double _width = 48;
  static const double _height = 29;
  static const double _knob = 23;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final ink = c.heroInk;

    return PressScale(
      onTap: () => onChanged(!value),
      haptic: HapticLevel.selection,
      scale: 0.94,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: _width,
        height: _height,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? c.accent : ink.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(_height / 2),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: _knob,
            height: _knob,
            decoration: BoxDecoration(
              color: value ? Colors.white : ink.withValues(alpha: 0.55),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

/// A labelled switch row. The whole row is the target — a 29pt switch is a
/// small thing to ask a thumb to find when the sentence beside it means the
/// same thing.
class BudgyToggleTile extends StatelessWidget {
  const BudgyToggleTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.filled = true,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  /// Draws the quiet panel behind the row. Off when the caller is already
  /// providing one.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final ink = c.heroInk;

    return PressScale(
      onTap: () => onChanged(!value),
      haptic: HapticLevel.selection,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        decoration: filled
            ? BoxDecoration(
                color: ink.withValues(alpha: 0.055),
                borderRadius: BorderRadius.circular(18),
              )
            : null,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.textTheme.titleSmall?.copyWith(color: ink),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: ink.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 14),
            // ⚠️ Not wrapped in its own tap target. The row already toggles, and
            // a nested `PressScale` here would swallow the press on the one
            // part of the row people actually aim at.
            IgnorePointer(
              child: BudgySwitch(value: value, onChanged: onChanged),
            ),
          ],
        ),
      ),
    );
  }
}
