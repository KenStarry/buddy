import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../utils/extensions/context_extensions.dart';
import '../../utils/extensions/date_extensions.dart';
import 'press_scale.dart';

/// Budgy's date picker. One implementation, every call site.
///
/// ## Why not `showDatePicker`
///
/// Material's picker is a white dialog with its own type ramp, its own radii
/// and its own idea of a primary colour. Dropped into a near-black app it does
/// not read as a themed component — it reads as a different product briefly
/// taking over the screen, which is exactly the break in continuity this one
/// exists to remove. Theming it is not an option either: the parts that look
/// wrong (the header block, the input-mode toggle, the edit field) are the
/// parts `DatePickerThemeData` cannot reach.
///
/// ## Tap commits
///
/// There is no confirm button. Picking a day *is* the choice — a Cancel/OK pair
/// would add a tap to the common case to protect against a mistake that costs
/// one tap to undo. Month navigation and the year grid change what is shown
/// without committing anything, so there is still no way to pick by accident.
Future<DateTime?> showBudgyDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  final first = firstDate ?? DateTime(DateTime.now().year - 5);
  final last = lastDate ?? DateTime(DateTime.now().year + 5, 12, 31);

  return showGeneralDialog<DateTime>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (_, _, _) => const SizedBox.shrink(),
    transitionBuilder: (context, animation, _, _) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          // A short throw. A dialog that scales from far away reads as a
          // different surface arriving; one that barely moves reads as the
          // same surface coming into focus.
          scale: Tween(begin: 0.94, end: 1.0).animate(curved),
          child: _DatePickerCard(
            initialDate: initialDate.clamp(first, last),
            firstDate: first,
            lastDate: last,
          ),
        ),
      );
    },
  );
}

extension on DateTime {
  DateTime clamp(DateTime low, DateTime high) =>
      isBefore(low) ? low : (isAfter(high) ? high : this);
}

class _DatePickerCard extends StatefulWidget {
  const _DatePickerCard({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<_DatePickerCard> createState() => _DatePickerCardState();
}

class _DatePickerCardState extends State<_DatePickerCard> {
  late DateTime _month = DateTime(
    widget.initialDate.year,
    widget.initialDate.month,
  );
  late DateTime _selected = widget.initialDate;

  /// Years take over the grid rather than opening a second dialog. Reaching a
  /// goal's target date two years out is otherwise 24 taps on a chevron.
  bool _pickingYear = false;

  /// Which way the month grid should slide on the next change.
  bool _forward = true;

  bool get _canGoBack =>
      DateTime(_month.year, _month.month - 1, 1).isAfter(
        DateTime(widget.firstDate.year, widget.firstDate.month, 0),
      );

  bool get _canGoForward => DateTime(
    _month.year,
    _month.month + 1,
    1,
  ).isBefore(DateTime(widget.lastDate.year, widget.lastDate.month + 1, 1));

  void _step(int by) {
    if (by > 0 ? !_canGoForward : !_canGoBack) return;
    setState(() {
      _forward = by > 0;
      _month = DateTime(_month.year, _month.month + by);
    });
  }

  bool _enabled(DateTime day) =>
      !day.isBefore(widget.firstDate.startOfDay) &&
      !day.isAfter(widget.lastDate.startOfDay);

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final ink = c.heroInk;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Material(
            type: MaterialType.transparency,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: DecoratedBox(
                // ⚠️ Solid, not glass. Behind a 55% scrim there is nothing
                // left to refract, so a `BackdropFilter` here would be a
                // saveLayer rendering a blur of flat black. The surface still
                // belongs to the language — a raised fill with the light along
                // its top edge — it just does not pretend to be transparent.
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.lerp(c.surface300, ink, 0.05)!,
                      c.surface200,
                    ],
                  ),
                ),
                child: CustomPaint(
                  foregroundPainter: _CardEdge(radius: 30),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Header(
                          month: _month,
                          pickingYear: _pickingYear,
                          canGoBack: _canGoBack && !_pickingYear,
                          canGoForward: _canGoForward && !_pickingYear,
                          onBack: () => _step(-1),
                          onForward: () => _step(1),
                          onToggleYear: () =>
                              setState(() => _pickingYear = !_pickingYear),
                        ),
                        const SizedBox(height: 12),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          child: _pickingYear ? _years(ink) : _days(ink),
                        ),
                        const SizedBox(height: 12),
                        _Footer(
                          onToday: _enabled(DateTime.now())
                              ? () => Navigator.of(context).pop(DateTime.now())
                              : null,
                          onCancel: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _days(Color ink) {
    final first = DateTime(_month.year, _month.month);
    // Monday-first. `weekday` is 1..7 from Monday, so the lead-in is simply
    // one less than the first day's own index.
    final lead = first.weekday - 1;
    final count = DateTime(_month.year, _month.month + 1, 0).day;
    final rows = ((lead + count) / 7).ceil();

    return Column(
      key: ValueKey(_month),
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            for (final label in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: ink.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        // Slides in the direction travelled, so paging a month reads as moving
        // along a calendar rather than as the grid being swapped out.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(
                begin: Offset(_forward ? 0.12 : -0.12, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: Column(
            key: ValueKey('${_month.year}-${_month.month}'),
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var row = 0; row < rows; row++)
                Row(
                  children: [
                    for (var col = 0; col < 7; col++)
                      Expanded(
                        child: _dayCell(row * 7 + col - lead + 1, ink),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dayCell(int dayOfMonth, Color ink) {
    final count = DateTime(_month.year, _month.month + 1, 0).day;
    if (dayOfMonth < 1 || dayOfMonth > count) {
      return const SizedBox(height: 42);
    }

    final c = context.budgyColors;
    final day = DateTime(_month.year, _month.month, dayOfMonth);
    final enabled = _enabled(day);
    final selected = day.isSameDay(_selected);
    final isToday = day.isToday;

    return PressScale(
      onTap: enabled
          ? () {
              setState(() => _selected = day);
              Navigator.of(context).pop(day);
            }
          : null,
      haptic: HapticLevel.selection,
      child: SizedBox(
        height: 42,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? c.accent : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$dayOfMonth',
              style: context.textTheme.titleSmall?.copyWith(
                fontFamily: 'Sora',
                fontSize: 14.5,
                color: !enabled
                    ? ink.withValues(alpha: 0.18)
                    : selected
                    ? Colors.white
                    // Today is marked in the accent rather than with a ring:
                    // a ring on an unselected cell is one mark away from
                    // looking selected, which on a calendar is the single
                    // ambiguity worth spending a colour to avoid.
                    : isToday
                    ? c.accent
                    : ink.withValues(alpha: 0.85),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _years(Color ink) {
    final c = context.budgyColors;
    final years = [
      for (var y = widget.firstDate.year; y <= widget.lastDate.year; y++) y,
    ];

    return SizedBox(
      key: const ValueKey('years'),
      height: 252,
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 2.1,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
        ),
        itemCount: years.length,
        itemBuilder: (context, index) {
          final year = years[index];
          final selected = year == _month.year;
          return PressScale(
            onTap: () => setState(() {
              _month = DateTime(year, _month.month);
              _pickingYear = false;
            }),
            haptic: HapticLevel.selection,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? c.accent
                    : ink.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '$year',
                style: context.textTheme.titleSmall?.copyWith(
                  fontFamily: 'Sora',
                  color: selected ? Colors.white : ink.withValues(alpha: 0.8),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.month,
    required this.pickingYear,
    required this.canGoBack,
    required this.canGoForward,
    required this.onBack,
    required this.onForward,
    required this.onToggleYear,
  });

  final DateTime month;
  final bool pickingYear;
  final bool canGoBack;
  final bool canGoForward;
  final VoidCallback onBack;
  final VoidCallback onForward;
  final VoidCallback onToggleYear;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final ink = c.heroInk;

    return Row(
      children: [
        PressScale(
          onTap: onToggleYear,
          haptic: HapticLevel.selection,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat.yMMMM().format(month),
                  style: context.textTheme.titleLarge?.copyWith(color: ink),
                ),
                const SizedBox(width: 5),
                AnimatedRotation(
                  turns: pickingYear ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    LucideIcons.chevronDown,
                    size: 17,
                    color: ink.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        _Step(icon: LucideIcons.chevronLeft, enabled: canGoBack, onTap: onBack),
        const SizedBox(width: 6),
        _Step(
          icon: LucideIcons.chevronRight,
          enabled: canGoForward,
          onTap: onForward,
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = context.budgyColors.heroInk;
    return PressScale(
      onTap: enabled ? onTap : null,
      haptic: HapticLevel.selection,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ink.withValues(alpha: enabled ? 0.08 : 0.03),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 17,
          color: ink.withValues(alpha: enabled ? 0.75 : 0.2),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.onToday, required this.onCancel});

  final VoidCallback? onToday;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final ink = c.heroInk;

    return Row(
      children: [
        if (onToday != null)
          PressScale(
            onTap: onToday,
            haptic: HapticLevel.selection,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: ink.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Today',
                style: context.textTheme.titleSmall?.copyWith(
                  color: ink.withValues(alpha: 0.85),
                ),
              ),
            ),
          ),
        const Spacer(),
        PressScale(
          onTap: onCancel,
          haptic: HapticLevel.selection,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Text(
              'Cancel',
              style: context.textTheme.titleSmall?.copyWith(
                color: ink.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The light along the card's top edge — a specular, not a border. It fades
/// out before the shoulders and never closes around the shape.
class _CardEdge extends CustomPainter {
  _CardEdge({required this.radius});

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
            Colors.white.withValues(alpha: 0.24),
            Colors.white.withValues(alpha: 0),
          ],
          stops: const [0, 0.30],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_CardEdge old) => old.radius != radius;
}
