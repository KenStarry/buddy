import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../domain/currency.dart';
import '../../theme/budgy_shadows.dart';
import '../../utils/extensions/context_extensions.dart';
import 'press_scale.dart';

/// The amount entry pad.
///
/// ## Why a custom pad and not a `TextField`
///
/// Logging a transaction is the single most frequent thing anyone does in a
/// budget app, and the system numeric keyboard is the wrong tool for it: it
/// takes half the screen, animates in and out, varies by platform and locale,
/// and still lets you type `1.2.3`. A purpose-built pad is always there, has
/// big thumb-sized keys, can hold an inline operator for "add 250 to this",
/// and cannot produce an invalid number — the state is a digit string this
/// widget owns.
///
/// ## State is a string, not a double
///
/// ⚠️ Keeping a `double` and reformatting it loses the user's intent the
/// moment they type a decimal point: `12.` and `12` are the same double, so
/// the point vanishes as fast as it is typed and the next digit lands in the
/// whole part. The pad owns the raw text and only parses on commit.
class AmountKeypad extends StatelessWidget {
  const AmountKeypad({
    super.key,
    required this.text,
    required this.currency,
    required this.onChanged,
    this.onSubmit,
  });

  /// The raw digit string. May be empty, may end in a separator.
  final String text;

  final Currency currency;
  final ValueChanged<String> onChanged;
  final VoidCallback? onSubmit;

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

    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                for (var i = 0; i < row.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(
                    child: _Key(
                      label: row[i],
                      onTap: () => _press(row[i]),
                      disabled:
                          row[i] == '.' && currency.decimalDigits == 0,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    required this.label,
    required this.onTap,
    this.disabled = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final isBackspace = label == '⌫';

    return PressScale(
      onTap: disabled ? null : onTap,
      enableHaptics: false,
      scale: 0.94,
      child: Container(
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: disabled ? Colors.transparent : c.surface200,
          borderRadius: BorderRadius.circular(18),
          boxShadow: disabled ? null : BudgyShadows.pressed(context),
        ),
        child: isBackspace
            ? Icon(LucideIcons.delete, size: 21, color: c.text200)
            : Text(
                label,
                style: context.textTheme.headlineMedium?.copyWith(
                  color: disabled ? c.text300.withValues(alpha: 0.4) : c.text100,
                  fontSize: 23,
                ),
              ),
      ),
    );
  }
}
