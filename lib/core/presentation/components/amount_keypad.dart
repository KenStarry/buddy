import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../domain/currency.dart';
import '../../utils/extensions/context_extensions.dart';

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
/// ## Why the keys are circles, and why the pad is narrow
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
    required this.text,
    required this.currency,
    required this.onChanged,
    this.glowTint,
    this.maxKeySize = 76,
    this.gap = 14,
  });

  /// The raw digit string. May be empty, may end in a separator.
  final String text;

  final Currency currency;
  final ValueChanged<String> onChanged;

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
    switch (key) {
      case '⌫':
        onChanged(text.isEmpty ? '' : text.substring(0, text.length - 1));
      case '.':
        // One separator, and never as the first character — `.5` is a valid
        // double but reads as a typo, and a second point would make the whole
        // string unparseable.
        if (currency.decimalDigits == 0) return;
        if (text.contains('.')) return;
        onChanged(text.isEmpty ? '0.' : '$text.');
      default:
        // Cap the fraction at the currency's own precision, so a user cannot
        // enter 19.9999 and have it silently round to 20.00 on save.
        final dot = text.indexOf('.');
        if (dot >= 0 && text.length - dot - 1 >= currency.decimalDigits) {
          return;
        }
        // No runaway leading zeros: `0` then `5` is `5`, not `05`.
        if (text == '0') {
          onChanged(key);
          return;
        }
        if (text.replaceAll('.', '').length >= 12) return;
        onChanged('$text$key');
    }
  }

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', '⌫'],
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Sized by whichever runs out first — width or the height the parent
        // is willing to give. A pad that overflows its slot is worse than a
        // slightly smaller one, and on a short phone height is what binds.
        final byWidth = (constraints.maxWidth - gap * 2) / 3;
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
                  for (var i = 0; i < rows[r].length; i++) ...[
                    if (i > 0) SizedBox(width: gap),
                    _Key(
                      label: rows[r][i],
                      size: size,
                      glowTint: glowTint,
                      // Lit from above, like everything else on the page. The
                      // falloff is tiny — 5% a row — but it is the difference
                      // between a grid of keys and a grid of keys *in a room*.
                      rest: 0.075 - r * 0.009,
                      onTap: () => _press(rows[r][i]),
                      disabled:
                          rows[r][i] == '.' && currency.decimalDigits == 0,
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
    this.glowTint,
    this.disabled = false,
  });

  final String label;
  final VoidCallback onTap;
  final double size;

  /// Resting fill alpha. Varies by row so the pad catches the page's light.
  final double rest;

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
            color: null,
            // At rest, a shallow vertical ramp rather than a flat fill: a disc
            // lit from above is a dome, a disc of one value is a hole. The
            // page's light comes from the top of the screen, so the keys
            // answer it — which is also why the resting alpha steps down a
            // little with each row.
            gradient: widget.disabled
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
                    fontSize: widget.size * 0.37,
                    color: widget.disabled
                        ? ink.withValues(alpha: 0.2)
                        : ink.withValues(alpha: 0.92),
                  ),
                ),
        ),
      ),
    );
  }
}
