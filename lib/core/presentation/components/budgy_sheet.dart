import 'package:flutter/material.dart';

import '../../utils/extensions/context_extensions.dart';

/// The shell every bottom sheet in Budgy wears: top radius 28, a drag handle,
/// an optional title row, and bottom padding that already accounts for the
/// keyboard and the home indicator.
class BudgySheet extends StatelessWidget {
  const BudgySheet({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(20, 0, 20, 20),
    this.scrollable = false,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsets padding;

  /// Wrap [child] in a scroll view. For sheets whose content can outgrow the
  /// screen — a category picker, a filter panel.
  final bool scrollable;

  /// Presents [builder]'s result as a modal sheet with Budgy's chrome.
  ///
  /// ⚠️ `isScrollControlled` is always true and the sheet is capped at 92% of
  /// the screen. Without it, a sheet holding a text field is pinned to half
  /// the screen and the keyboard covers the field being typed into.
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool dismissible = true,
  }) => showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: dismissible,
    enableDrag: dismissible,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.42),
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      maxWidth: 560,
    ),
    builder: builder,
  );

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;

    final body = Padding(
      padding: padding.copyWith(
        // The keyboard inset is added to the bottom padding rather than
        // replacing it, so a focused field still clears the keyboard by the
        // sheet's own gutter.
        bottom: padding.bottom + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: child,
    );

    return Container(
      decoration: BoxDecoration(
        color: c.surface100,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: c.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title!, style: context.textTheme.titleLarge),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
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
                  ?trailing,
                ],
              ),
            ),
          const SizedBox(height: 18),
          if (scrollable)
            Flexible(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: body,
              ),
            )
          else
            body,
        ],
      ),
    );
  }
}
