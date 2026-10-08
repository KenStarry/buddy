import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../domain/currency.dart';
import '../../utils/extensions/context_extensions.dart';

/// The four operations a budget actually needs.
///
/// Multiplication and division are not padding: "three coffees at 250" and
/// "split the 1,200 bill four ways" are the two sums people most often do in
/// their head before opening the app, and getting them wrong is how a ledger
/// quietly stops matching reality.
enum CalcOp {
  add('+'),
  subtract('−'),
  multiply('×'),
  divide('÷');

  const CalcOp(this.glyph);

  final String glyph;

  static CalcOp? fromGlyph(String glyph) {
    for (final op in values) {
      if (op.glyph == glyph) return op;
    }
    return null;
  }

  /// Applies this operation, left to right.
  ///
  /// ⚠️ Division by zero returns [left] unchanged rather than infinity or NaN.
  /// The divisor is read live while it is being typed, so a user reaching for
  /// "÷ 40" passes through "÷ 0" on the way — and a figure that flashes
  /// `Infinity` mid-keystroke is both alarming and, once formatted into minor
  /// units, a crash.
  double apply(double left, double right) => switch (this) {
    CalcOp.add => left + right,
    CalcOp.subtract => left - right,
    CalcOp.multiply => left * right,
    CalcOp.divide => right == 0 ? left : left / right,
  };
}

/// The amount entry pad.
///
/// ## Why a custom pad and not a `TextField`
///
/// Logging a transaction is the single most frequent thing anyone does in a
/// budget app, and the system numeric keyboard is the wrong tool for it: it
/// takes half the screen, animates in and out, varies by platform and locale,
/// and still lets you type `1.2.3`. A purpose-built pad is always there, has
/// big thumb-sized keys, and cannot produce an invalid number — the state is a
/// digit string this widget owns.
///
/// ## State is a string, not a double
///
/// ⚠️ Keeping a `double` and reformatting it loses the user's intent the
/// moment they type a decimal point: `12.` and `12` are the same double, so
/// the point vanishes as fast as it is typed and the next digit lands in the
/// whole part. The pad owns the raw text and only parses on commit.
///
/// ## Why there is no `=`
///
/// The figure always shows **what would be saved right now**: with an operation
/// pending it is the running result, not the operand being typed. So
/// `1,250 + 340` reads 1,590 the moment the last digit lands, and there is
/// nothing left for an equals key to do. That removes a key, removes a state
/// where the display and the saved value disagree, and removes the commonest
/// calculator mistake — pressing save before pressing equals.
///
/// ## Why the keys are circles
///
/// A 3×4 grid of full-width rounded rectangles is a wall: twelve high-contrast
/// slabs filling the bottom half of a screen whose entire point is one
/// enormous number. Circles carry the same affordance in less ink — a disc is
/// the oldest "press here" there is — and sizing them to a comfortable thumb
/// rather than to the available width leaves the pad a *compact instrument*
/// sitting in open space instead of a keyboard bolted to the bottom edge.
///
/// The keys are barely-there glass. Nobody needs a high-contrast slab to find
/// the 5, and the contrast budget belongs to the figure.
class AmountKeypad extends StatelessWidget {
  const AmountKeypad({
    super.key,
    required this.currency,
    required this.onKey,
    this.onOperator,
    this.activeOp,
    this.glowTint,
    this.maxKeySize = 76,
    this.gap = 12,
  });

  final Currency currency;

  /// Emits the pressed key — a digit, `.` or `⌫`.
  ///
  /// ⚠️ The pad no longer owns the string. With a caret in play every edit is
  /// an insertion *somewhere*, so the rules about decimals, leading zeros and
  /// length became rules about the text rather than about the key — they live
  /// with the text, in `applyAmountKey`.
  final ValueChanged<String> onKey;

  /// Null hides the operator column entirely, leaving a plain 3-wide pad.
  final ValueChanged<CalcOp>? onOperator;

  /// The operation waiting on a second operand, lit so it is obvious one is
  /// pending.
  final CalcOp? activeOp;

  /// The colour a key blooms when pressed. Defaults to plain ink.
  ///
  /// The entry screen feeds it the hue of whatever is being logged, so the
  /// dial lights in the same colour as the room — pressing a key is the one
  /// moment the screen's light has a *source* the user caused.
  final Color? glowTint;

  /// Ceiling on the key diameter. The pad shrinks below this on a short or
  /// narrow screen, but never grows past it — a 100pt key is not easier to
  /// hit, it is just further from the next one.
  final double maxKeySize;

  final double gap;

  /// Parses [text] into minor units. 0 for anything unparseable, so a caller
  /// can always render something.
  static int toMinor(String text, Currency currency) {
    if (text.isEmpty) return 0;
    final value = double.tryParse(text.replaceAll(',', '.'));
    if (value == null) return 0;
    return currency.toMinor(value);
  }

  /// Formats minor units back into pad text, for opening the pad on an
  /// existing amount.
  static String fromMinor(int minor, Currency currency) {
    if (minor == 0) return '';
    final major = currency.toMajor(minor);
    return currency.decimalDigits == 0 || major == major.roundToDouble()
        ? major.toStringAsFixed(0)
        : major.toStringAsFixed(currency.decimalDigits);
  }

  void _press(String key) {
    HapticFeedback.selectionClick();
    onKey(key);
  }

  /// Interleaves nulls as gap markers, so the row builder stays a flat loop.
  static List<String?> _spaced(List<String> keys, double gap) => [
    for (var i = 0; i < keys.length; i++) ...[if (i > 0) null, keys[i]],
  ];

  @override
  Widget build(BuildContext context) {
    final calculator = onOperator != null;
    final rows = [
      ['1', '2', '3', if (calculator) CalcOp.divide.glyph],
      ['4', '5', '6', if (calculator) CalcOp.multiply.glyph],
      ['7', '8', '9', if (calculator) CalcOp.subtract.glyph],
      ['.', '0', '⌫', if (calculator) CalcOp.add.glyph],
    ];
    final columns = calculator ? 4 : 3;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Sized by whichever runs out first — width or the height the parent
        // is willing to give. A pad that overflows its slot is worse than a
        // slightly smaller one, and on a short phone height is what binds.
        final byWidth = (constraints.maxWidth - gap * (columns - 1)) / columns;
        final byHeight = constraints.hasBoundedHeight
            ? (constraints.maxHeight - gap * 3) / 4
            : double.infinity;
        final size = math.min(math.min(byWidth, byHeight), maxKeySize);

        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var r = 0; r < rows.length; r++) ...[
              if (r > 0) SizedBox(height: gap),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final label in _spaced(rows[r], gap)) ...[
                    if (label == null)
                      SizedBox(width: gap)
                    else
                      Builder(
                        builder: (context) {
                          final op = CalcOp.fromGlyph(label);
                          return _Key(
                            label: label,
                            size: size,
                            glowTint: glowTint,
                            // Lit from above, like everything else on the
                            // page. The falloff is tiny — but it is the
                            // difference between a grid of keys and a grid of
                            // keys *in a room*.
                            rest: 0.09 - r * 0.009,
                            op: op,
                            // ⚠️ `op != null &&` is load-bearing. Comparing
                            // the two nullables alone makes every **digit**
                            // active whenever no operation is pending, because
                            // `null == null` — which lit the whole pad.
                            active: op != null && op == activeOp,
                            onTap: () {
                              if (op != null) {
                                HapticFeedback.selectionClick();
                                onOperator!(op);
                              } else {
                                _press(label);
                              }
                            },
                            disabled:
                                label == '.' && currency.decimalDigits == 0,
                          );
                        },
                      ),
                  ],
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

/// One key.
///
/// The press state is a **bloom from the centre**, not a fill change: a radial
/// highlight under the glyph, so the key reads as lighting up rather than as
/// swapping colour. Combined with the scale it is the cheapest way to make a
/// flat glass disc feel physical.
class _Key extends StatefulWidget {
  const _Key({
    required this.label,
    required this.onTap,
    required this.size,
    required this.rest,
    this.op,
    this.active = false,
    this.glowTint,
    this.disabled = false,
  });

  final String label;
  final VoidCallback onTap;
  final double size;

  /// Resting fill alpha. Varies by row so the pad catches the page's light.
  final double rest;

  /// Set when this key is an operator — it wears the accent rather than plain
  /// ink, so the column reads as a different kind of control at a glance.
  final CalcOp? op;

  /// This operator is the one waiting on a second operand.
  final bool active;

  final Color? glowTint;
  final bool disabled;

  @override
  State<_Key> createState() => _KeyState();
}

class _KeyState extends State<_Key> {
  bool _down = false;

  void _set(bool value) {
    if (_down == value || !mounted) return;
    setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final ink = c.heroInk;
    final isBackspace = widget.label == '⌫';
    final isOp = widget.op != null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.disabled ? null : (_) => _set(true),
      // ⚠️ Reset on cancel as well as up. Tracking only down/up leaves a key
      // stuck lit when the press turns into a scroll.
      onTapCancel: () => _set(false),
      onTapUp: (_) => _set(false),
      onTap: widget.disabled ? null : widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.92 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: widget.size,
          height: widget.size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // ⚠️ The active operator is a flat fill, and it has to be set
            // *here* — the gradient below is skipped for it, so leaving this
            // null rendered the pending operator as nothing at all.
            color: widget.active ? c.accent : null,
            // At rest, a shallow vertical ramp rather than a flat fill: a disc
            // lit from above is a dome, a disc of one value is a hole. The
            // page's light comes from the top of the screen, so the keys
            // answer it — which is also why the resting alpha steps down a
            // little with each row.
            gradient: widget.disabled || widget.active
                ? null
                : _down
                ? RadialGradient(
                    colors: [
                      (widget.glowTint ?? ink).withValues(alpha: 0.42),
                      (widget.glowTint ?? ink).withValues(alpha: 0.12),
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      ink.withValues(alpha: widget.rest * 1.75),
                      ink.withValues(alpha: widget.rest * 0.55),
                    ],
                  ),
            boxShadow: _down && widget.glowTint != null
                ? [
                    BoxShadow(
                      color: widget.glowTint!.withValues(alpha: 0.35),
                      blurRadius: 18,
                      spreadRadius: -4,
                    ),
                  ]
                : null,
          ),
          child: isBackspace
              ? Icon(
                  LucideIcons.delete,
                  size: widget.size * 0.30,
                  color: ink.withValues(alpha: 0.7),
                )
              : Text(
                  widget.label,
                  style: context.textTheme.headlineLarge?.copyWith(
                    fontSize: widget.size * (isOp ? 0.42 : 0.37),
                    color: widget.disabled
                        ? ink.withValues(alpha: 0.2)
                        : widget.active
                        ? Colors.white
                        : isOp
                        ? c.accent
                        : ink.withValues(alpha: 0.92),
                  ),
                ),
        ),
      ),
    );
  }
}
