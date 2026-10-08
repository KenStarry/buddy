import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/currency.dart';
import '../../utils/extensions/context_extensions.dart';

/// The amount being typed, with a caret you can place.
///
/// ## Why not a `TextField`
///
/// The figure is 88pt, grouped (`1,250`), carries a sign and a trailing
/// currency, and is driven by an on-screen dial rather than a keyboard. A
/// `TextField` would fight every one of those: it formats nothing, it wants the
/// system keyboard, and its selection model is far more than "where does the
/// next digit land". What is actually needed is one index into a digit string —
/// so this renders the formatted figure itself and draws a caret at that index.
///
/// ## The index is into the *raw* text
///
/// ⚠️ `caret` counts characters of the unformatted operand (`1250`), never of
/// what is on screen (`1,250`). Group separators are inserted for display only
/// and are deliberately **not** tap targets or caret positions: a caret that
/// could sit either side of a comma has two positions that mean the same edit,
/// and the keypad would have to understand commas it never produced.
class AmountField extends StatefulWidget {
  const AmountField({
    super.key,
    required this.text,
    required this.caret,
    required this.currency,
    required this.onCaret,
    required this.style,
    required this.ink,
    this.sign,
    this.showCaret = true,
  });

  /// The raw operand. May be empty, may end in a separator.
  final String text;

  /// Insertion point, 0..text.length, in raw characters.
  final int caret;

  final Currency currency;
  final ValueChanged<int> onCaret;

  /// The figure's own style. Satellites are derived from it.
  final TextStyle style;

  final Color ink;

  /// `−` or `+`, drawn ahead of the figure. Null for a transfer.
  final String? sign;

  final bool showCaret;

  @override
  State<AmountField> createState() => _AmountFieldState();
}

/// One rendered character and where it sits in the raw string.
class _Glyph {
  _Glyph(this.char, this.rawBefore, {this.separator = false});

  final String char;

  /// How many raw characters precede this glyph.
  final int rawBefore;

  /// A grouping comma — display only, never a caret position.
  final bool separator;
}

class _AmountFieldState extends State<AmountField> {
  /// Groups the integer part for display, remembering where each glyph came
  /// from so a caret index can be resolved back to a position on screen.
  List<_Glyph> _layout() {
    final text = widget.text;
    if (text.isEmpty) return [_Glyph('0', 0)];

    final dot = text.indexOf('.');
    final whole = dot >= 0 ? text.substring(0, dot) : text;
    final rest = dot >= 0 ? text.substring(dot) : '';

    final glyphs = <_Glyph>[];
    for (var i = 0; i < whole.length; i++) {
      // A separator every three digits counted from the right.
      final fromRight = whole.length - i;
      if (i > 0 && fromRight % 3 == 0) {
        glyphs.add(_Glyph(',', i, separator: true));
      }
      glyphs.add(_Glyph(whole[i], i));
    }
    for (var i = 0; i < rest.length; i++) {
      glyphs.add(_Glyph(rest[i], whole.length + i));
    }
    return glyphs;
  }

  /// Where the caret sits among [glyphs].
  ///
  /// ⚠️ Separators are skipped, so a caret at raw index 1 of `1250` lands as
  /// `1,|250` rather than `1|,250`. Both are the same edit; only one of them
  /// looks like it.
  int _caretSlot(List<_Glyph> glyphs) {
    for (var i = 0; i < glyphs.length; i++) {
      final glyph = glyphs[i];
      if (!glyph.separator && glyph.rawBefore >= widget.caret) return i;
    }
    return glyphs.length;
  }

  double _widthOf(String char, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: char, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.width;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final empty = widget.text.isEmpty;
    final style = widget.style.copyWith(
      color: empty ? widget.ink.withValues(alpha: 0.26) : widget.ink,
    );
    final satellite = style.copyWith(
      fontSize: (style.fontSize ?? 16) * 0.24,
      color: style.color?.withValues(alpha: (style.color?.a ?? 1) * 0.7),
      letterSpacing: 0,
    );

    final glyphs = _layout();
    final slot = _caretSlot(glyphs);

    final caret = _Caret(
      // Restarting on every keystroke keeps the caret solid while typing —
      // a caret that blinks out mid-digit reads as the field losing focus.
      restartKey: '${widget.text}:${widget.caret}',
      color: c.accent,
      lineHeight: style.fontSize ?? 48,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.sign != null)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text(
              widget.sign!,
              style: style.copyWith(
                fontSize: (style.fontSize ?? 48) * 0.64,
                color: widget.ink.withValues(alpha: empty ? 0.18 : 0.4),
              ),
            ),
          ),
        for (var i = 0; i <= glyphs.length; i++) ...[
          if (i == slot && widget.showCaret && !empty) caret,
          if (i < glyphs.length)
            _GlyphTarget(
              glyph: glyphs[i],
              style: style,
              width: _widthOf(glyphs[i].char, style),
              enabled: !empty && !glyphs[i].separator,
              onCaret: widget.onCaret,
            ),
        ],
        // An empty field still needs somewhere for the caret to be.
        if (empty && widget.showCaret) caret,
        SizedBox(width: (style.fontSize ?? 16) * 0.14),
        Text(widget.currency.symbol, style: satellite),
      ],
    );
  }
}

class _GlyphTarget extends StatelessWidget {
  const _GlyphTarget({
    required this.glyph,
    required this.style,
    required this.width,
    required this.enabled,
    required this.onCaret,
  });

  final _Glyph glyph;
  final TextStyle style;
  final double width;
  final bool enabled;
  final ValueChanged<int> onCaret;

  @override
  Widget build(BuildContext context) {
    final text = Text(glyph.char, style: style);
    if (!enabled) return text;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // Which half was tapped decides which side of the digit the caret lands
      // — the thing every text editor does, and the only way to reach the
      // position before the first digit.
      onTapDown: (details) {
        HapticFeedback.selectionClick();
        onCaret(
          details.localPosition.dx < width / 2
              ? glyph.rawBefore
              : glyph.rawBefore + 1,
        );
      },
      child: text,
    );
  }
}

/// The caret.
///
/// A rounded accent bar that breathes rather than blinks: a hard on/off at
/// 500ms is a 1980s terminal, and on a 88pt figure it flickers. This fades
/// between full and a quarter on a slow ease, with a soft glow of its own, so
/// it reads as a lit mark sitting in the number.
class _Caret extends StatefulWidget {
  const _Caret({
    required this.restartKey,
    required this.color,
    required this.lineHeight,
  });

  final String restartKey;
  final Color color;

  /// The figure's own line box. The bar is sized and placed from this rather
  /// than passed in, so the caret cannot drift out of step with the type.
  final double lineHeight;

  @override
  State<_Caret> createState() => _CaretState();
}

class _CaretState extends State<_Caret> with SingleTickerProviderStateMixin {
  static const double _barWidth = 3.5;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void didUpdateWidget(_Caret old) {
    super.didUpdateWidget(old);
    if (old.restartKey != widget.restartKey) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) {
      final t = Curves.easeInOut.transform(_controller.value);
      final opacity = 1 - 0.75 * t;
      // ⚠️ Positioned inside a box the height of the figure's own line, not
      // by baseline. The Row aligns on the alphabetic baseline and a bare
      // container reports none, so the caret fell back to the top of the line
      // and floated a good 15pt above the digits it sits between. A full-height
      // box lands at the line's top deterministically, and the bar is then
      // placed against the **cap height** — which is what a caret should centre
      // on, since digits have no descenders to balance it.
      return SizedBox(
        height: widget.lineHeight,
        width: _barWidth + 3,
        child: Align(
          alignment: const Alignment(0, -0.42),
          child: Container(
            width: _barWidth,
            height: widget.lineHeight * 0.62,
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: opacity),
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.45 * opacity),
                  blurRadius: 10,
                  spreadRadius: -1,
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Applies one keypad press to a (text, caret) pair.
///
/// Lives here rather than in the pad because the pad no longer owns the
/// string: with a caret in play, every edit is an insertion *somewhere*, and
/// the rules about decimals and leading zeros are rules about the text, not
/// about the key.
({String text, int caret}) applyAmountKey({
  required String text,
  required int caret,
  required String key,
  required Currency currency,
}) {
  final at = caret.clamp(0, text.length);

  if (key == '⌫') {
    if (at == 0) return (text: text, caret: 0);
    return (
      text: text.substring(0, at - 1) + text.substring(at),
      caret: at - 1,
    );
  }

  if (key == '.') {
    // One separator, and never as the first character — `.5` is a valid double
    // but reads as a typo, and a second point would make the whole string
    // unparseable.
    if (currency.decimalDigits == 0 || text.contains('.')) {
      return (text: text, caret: at);
    }
    if (text.isEmpty) return (text: '0.', caret: 2);
    return (
      text: '${text.substring(0, at)}.${text.substring(at)}',
      caret: at + 1,
    );
  }

  // ⚠️ The fraction cap counts digits *after* the point and only bites when
  // inserting there — otherwise typing a digit at the front of `19.99` would
  // be refused for a reason that has nothing to do with where it was going.
  final dot = text.indexOf('.');
  if (dot >= 0 && at > dot) {
    final fraction = text.length - dot - 1;
    if (fraction >= currency.decimalDigits) return (text: text, caret: at);
  }

  // No runaway leading zeros: a lone `0` is replaced, not prefixed.
  if (text == '0' && at == 1) return (text: key, caret: 1);
  if (text.replaceAll('.', '').length >= 12) return (text: text, caret: at);

  return (
    text: '${text.substring(0, at)}$key${text.substring(at)}',
    caret: at + 1,
  );
}
