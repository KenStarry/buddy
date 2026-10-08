import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/presentation/budgy_icons.dart';
import '../../../../core/presentation/components/budgy_card.dart';
import '../../../../core/presentation/components/press_scale.dart';
import '../../../../core/utils/extensions/context_extensions.dart';

/// A labelled group of setting rows, rendered as one card with hairlines
/// between the rows.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            label.toUpperCase(),
            style: context.textTheme.labelSmall?.copyWith(color: c.text300),
          ),
        ),
        BudgyCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Padding(
                    // Inset to the text column, so the divider separates the
                    // labels rather than cutting across the icons.
                    padding: const EdgeInsets.only(left: 60),
                    child: Divider(height: 1, color: c.divider),
                  ),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// One tappable setting.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.iconKey,
    required this.title,
    this.subtitle,
    this.value,
    this.onTap,
    this.trailing,
    this.destructive = false,
  });

  final String iconKey;
  final String title;
  final String? subtitle;

  /// The current setting, shown on the right.
  final String? value;

  final VoidCallback? onTap;
  final Widget? trailing;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final ink = destructive ? c.errorMain : c.text100;

    return PressScale(
      onTap: onTap,
      haptic: HapticLevel.selection,
      scale: 0.99,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: (destructive ? c.errorMain : c.accent).withValues(
                  alpha: 0.12,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                BudgyIcons.resolve(iconKey),
                size: 16,
                color: destructive ? c.errorMain : c.accent,
              ),
            ),
            const SizedBox(width: 12),
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
                        color: c.text300,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else ...[
              if (value != null)
                Text(
                  value!,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: c.text300,
                  ),
                ),
              if (onTap != null) ...[
                const SizedBox(width: 6),
                Icon(LucideIcons.chevronRight, size: 16, color: c.text300),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// A setting that is a switch. Tappable anywhere on the row — a 40pt switch
/// is a small target for a row that is 300pt wide and means one thing.
class SettingsSwitch extends StatelessWidget {
  const SettingsSwitch({
    super.key,
    required this.iconKey,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String iconKey;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SettingsRow(
    iconKey: iconKey,
    title: title,
    subtitle: subtitle,
    onTap: () => onChanged(!value),
    trailing: Switch.adaptive(
      value: value,
      activeTrackColor: context.budgyColors.accent,
      onChanged: onChanged,
    ),
  );
}
