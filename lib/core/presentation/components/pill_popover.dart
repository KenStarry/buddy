import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/extensions/context_extensions.dart';

/// A pill that **grows a panel out of itself**.
///
/// ## Why not a bottom sheet
///
/// A sheet is a different place. It slides up from the bottom edge, covers the
/// screen, and has no relationship to the control that summoned it — so
/// choosing a category means leaving the entry screen, choosing, and coming
/// back, three times over for three fields. That is the single biggest reason
/// the old entry form felt like filling in a form.
///
/// A panel anchored to its own pill is the opposite: it opens *where you are
/// looking*, scales out of the trigger's own position so the connection is
/// legible without a pointer or a tail, and leaves the sentence above it
/// visible the whole time. Picking three things in a row never moves your eye
/// more than the height of one panel.
///
/// ## Anchoring
///
/// ⚠️ The panel is positioned from the trigger's **global rect, read at open
/// time**, rather than with `CompositedTransformFollower`. The follower cannot
/// be clamped to the screen, so a pill near the right edge opens a panel that
/// runs off it. This clamps, and sets the scale origin to wherever the pill
/// ended up along the panel's width — which is what keeps "it grew out of
/// *that* pill" true even after the clamp has moved the panel sideways.
class PillPopover extends StatefulWidget {
  const PillPopover({
    super.key,
    required this.pill,
    required this.panel,
    this.panelWidth = 300,
  });

  /// The trigger. Gets whether its panel is currently open, so it can stay
  /// visibly lit while it is.
  final Widget Function(BuildContext context, bool isOpen) pill;

  /// The panel's contents. Gets a closer, for a row that commits a choice.
  final Widget Function(BuildContext context, VoidCallback close) panel;

  final double panelWidth;

  @override
  State<PillPopover> createState() => _PillPopoverState();
}

class _PillPopoverState extends State<PillPopover>
    with SingleTickerProviderStateMixin {
  final _anchor = GlobalKey();
  OverlayEntry? _entry;

  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
    reverseDuration: const Duration(milliseconds: 160),
  );

  bool get _isOpen => _entry != null;

  @override
  void dispose() {
    // The entry lives in the Overlay, not in this subtree, so it does not go
    // away with the widget — leaking one leaves a dead panel pinned over the
    // app with no way to dismiss it.
    _entry?.remove();
    _entry = null;
    _anim.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    if (!_isOpen) return;
    await _anim.reverse();
    _entry?.remove();
    _entry = null;
    if (mounted) setState(() {});
  }

  void _open() {
    if (_isOpen) {
      _close();
      return;
    }
    final box = _anchor.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final origin = box.localToGlobal(Offset.zero);
    final pill = origin & box.size;

    HapticFeedback.selectionClick();
    _entry = OverlayEntry(
      builder: (overlayContext) => _Panel(
        anchor: pill,
        animation: _anim,
        popover: widget,
        close: _close,
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_entry!);
    _anim.forward(from: 0);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => KeyedSubtree(
    key: _anchor,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _open,
      child: widget.pill(context, _isOpen),
    ),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.anchor,
    required this.animation,
    required this.popover,
    required this.close,
  });

  final Rect anchor;
  final Animation<double> animation;
  final PillPopover popover;
  final VoidCallback close;

  static const double _gap = 10;
  static const double _margin = 16;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final media = MediaQuery.of(context);
    final screen = media.size;

    final width = math.min(popover.panelWidth, screen.width - _margin * 2);
    var left = anchor.left;
    if (left + width > screen.width - _margin) {
      left = screen.width - _margin - width;
    }
    left = math.max(_margin, left);

    final top = anchor.bottom + _gap;
    // ⚠️ Capped, not just fitted to the space below. Allowed to use every
    // remaining pixel the panel reaches the bottom of the screen and stops
    // reading as a popover attached to a pill — it becomes a drawer, which is
    // the thing this control exists to avoid.
    final maxHeight = math.min(
      340.0,
      math.max(160.0, screen.height - top - media.padding.bottom - _margin),
    );

    // Where the pill sits along the panel, in -1..1 — the point the panel
    // scales out of.
    final originX = (((anchor.center.dx - left) / width) * 2 - 1).clamp(
      -1.0,
      1.0,
    );

    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );
    final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);

    return Stack(
      children: [
        // A dim, not a blur. Blurring the backdrop would soften the sentence
        // the panel is editing, and the whole point is that you can still read
        // it while you choose.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: close,
            child: FadeTransition(
              opacity: fade,
              child: ColoredBox(color: Colors.black.withValues(alpha: 0.45)),
            ),
          ),
        ),
        Positioned(
          left: left,
          top: top,
          width: width,
          child: FadeTransition(
            opacity: fade,
            child: AnimatedBuilder(
              animation: curved,
              builder: (context, child) => Transform.scale(
                scale: 0.86 + 0.14 * curved.value,
                alignment: Alignment(originX, -1),
                child: child,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  // ⚠️ Solid, not frosted. This panel used to run a
                  // `BackdropFilter` under a fill at 96% opacity — a saveLayer
                  // blurring something that was then almost entirely painted
                  // over. Glass only earns its cost where you can see through
                  // it; behind a scrim, over near-black, you cannot. The
                  // surface still belongs to the language — a raised fill with
                  // the light along its top edge — it just stops pretending.
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color.lerp(c.surface300, c.heroInk, 0.05)!,
                          c.surface200,
                        ],
                      ),
                    ),
                    child: CustomPaint(
                      foregroundPainter: _PanelEdge(radius: 26),
                      child: Material(
                        type: MaterialType.transparency,
                        child: popover.panel(context, close),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The light along the panel's top edge — a specular, not a border. It fades
/// out before the shoulders and never closes around the shape.
class _PanelEdge extends CustomPainter {
  _PanelEdge({required this.radius});

  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0.6, 0.6, size.width - 1.2, size.height - 1.2),
        Radius.circular(radius),
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
          stops: const [0, 0.34],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_PanelEdge old) => old.radius != radius;
}
