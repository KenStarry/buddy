import 'package:flutter/material.dart';

import '../../utils/extensions/context_extensions.dart';

/// A page's opening band: an eyebrow, a large title, and chrome on the right.
///
/// Budgy has no `AppBar`. Every screen opens with one of these inside its own
/// scroll view, so the title scrolls away with the content instead of
/// collapsing into a 56pt bar that repeats what the first card already says.
class BudgyMasthead extends StatelessWidget {
  const BudgyMasthead({
    super.key,
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.actions = const [],
    this.leading,
    this.titleStyle,
  });

  final String title;
  final String? eyebrow;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? leading;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 14)],
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
                const SizedBox(height: 6),
              ],
              Text(
                title,
                style: titleStyle ?? context.textTheme.displaySmall,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: c.text300,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actions.isNotEmpty) ...[
          const SizedBox(width: 12),
          // Nudged down so the 44pt buttons optically centre on the title's
          // cap height rather than on its line box.
          Padding(
            padding: EdgeInsets.only(top: eyebrow != null ? 14 : 2),
            child: Row(
              children: [
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 9),
                  actions[i],
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
