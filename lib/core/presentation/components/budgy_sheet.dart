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

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: CustomPaint(
        foregroundPainter: _SheetEdge(),
        child: DecoratedBox(
          // ⚠️ A step **above** the page, not equal to it. `surface100` made the
          // sheet exactly the colour of the screen behind it, so its only edge
          // was the scrim — and on a near-black page a dimmed black against
          // black is barely an edge at all. Raised one rung and lit along the
          // top, it reads as a surface arriving over the page.
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(c.surface300, c.heroInk, 0.04)!,
                c.surface200,
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.heroInk.withValues(alpha: 0.22),
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
        ),
      ),
    );
  }
}

/// The light along the sheet's top edge — a specular, not a border. It fades
/// out well before the shoulders and never closes around the shape.
class _SheetEdge extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(0.6, 0.6, size.width - 1.2, size.height),
        topLeft: const Radius.circular(30),
        topRight: const Radius.circular(30),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.26),
            Colors.white.withValues(alpha: 0),
          ],
          stops: const [0, 0.22],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_SheetEdge old) => false;
}
