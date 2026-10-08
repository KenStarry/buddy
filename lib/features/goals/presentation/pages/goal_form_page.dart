import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/presentation/components/budgy_switch.dart';
import '../../../../core/presentation/components/amount_field.dart';
import '../../../../core/presentation/components/budgy_date_picker.dart';
import '../../../../core/presentation/components/amount_keypad.dart';
import '../../../../core/presentation/components/budgy_card.dart';
import '../../../../core/presentation/components/budgy_chip.dart';
import '../../../../core/presentation/components/look_picker.dart';
import '../../../../core/presentation/components/money_text.dart';
import '../../../../core/presentation/components/stepper/journey_stepper.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/utils/extensions/date_extensions.dart';
import '../../../../modules/ledger/state/providers/ledger_providers.dart';
import '../../domain/model/goal_model.dart';
import '../state/controllers/goals_controller.dart';

/// Create or edit a goal. Three steps: *how much* → *by when* → *what is it*.
class GoalFormPage extends ConsumerStatefulWidget {
  const GoalFormPage({super.key, this.goalId});

  final String? goalId;

  @override
  ConsumerState<GoalFormPage> createState() => _GoalFormPageState();
}

class _GoalFormPageState extends ConsumerState<GoalFormPage> {
  final _nameController = TextEditingController();
  final _noteController = TextEditingController();

  String _amountText = '';

  /// Insertion point in [_amountText], in raw characters.
  int _amountCaret = 0;
  GoalKind _kind = GoalKind.saving;
  DateTime? _targetDate;
  String _iconKey = 'target';
  int _colorIndex = 0;
  bool _isPinned = true;
  bool _hydrated = false;

  GoalModel? get _existing =>
      ref.read(goalsControllerProvider).byId(widget.goalId);

  bool get _isEditing => widget.goalId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _hydrate() {
    if (_hydrated) return;
    _hydrated = true;
    final existing = _existing;
    if (existing == null) return;
    _amountText = AmountKeypad.fromMinor(
      existing.targetMinor,
      existing.currency,
    );
    _kind = existing.kind;
    _targetDate = existing.targetDate;
    _iconKey = existing.iconKey;
    _colorIndex = existing.colorIndex;
    _isPinned = existing.isPinned;
    _nameController.text = existing.name;
    _noteController.text = existing.note ?? '';
  }

  int get _targetMinor =>
      AmountKeypad.toMinor(_amountText, ref.read(baseCurrencyProvider));

  Future<bool> _save() async {
    final base = ref.read(baseCurrencyProvider);
    final existing = _existing;
    final goal = GoalModel(
      id: existing?.id ?? const Uuid().v4(),
      name: _nameController.text.trim().isEmpty
          ? 'Goal'
          : _nameController.text.trim(),
      targetMinor: _targetMinor,
      currencyCode: existing?.currencyCode ?? base.code,
      iconKey: _iconKey,
      colorIndex: _colorIndex,
      // The start date is never re-derived on an edit: progress and pace are
      // both measured from it, so moving it would retroactively change how
      // the goal has been doing.
      startDate: existing?.startDate ?? DateTime.now(),
      kind: _kind,
      targetDate: _targetDate,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      isPinned: _isPinned,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );
    return ref.read(goalsControllerProvider.notifier).save(goal);
  }

  @override
  Widget build(BuildContext context) {
    _hydrate();
    final c = context.budgyColors;
    final base = ref.watch(baseCurrencyProvider);

    return JourneyStepper(
      kicker: _isEditing ? 'this goal' : 'your goal',
      completeLabel: _isEditing ? 'Save changes' : 'Set the goal',
      onExit: () => context.pop(),
      onDone: () => context.pop(),
      outcome: JourneyOutcome(
        title: _isEditing ? 'Updated' : 'Here we go',
        subtitle: _isEditing
            ? 'Your goal’s been brought up to date.'
            : 'Tag transactions to it and Budgy will track the climb.',
        iconKey: 'rocket',
      ),
      onComplete: _save,
      steps: [
        JourneyStep(
          iconKey: 'target',
          title: 'What’s the number?',
          subtitle: 'The amount you’re aiming at',
          canContinue: _targetMinor > 0,
          content: Column(
            children: [
              const SizedBox(height: 10),
              AmountField(
                text: _amountText,
                caret: _amountCaret,
                currency: base,
                style: MoneyText.baseStyle(context, MoneySize.hero),
                ink: c.text100,
                onCaret: (index) => setState(() => _amountCaret = index),
              ),
              const SizedBox(height: 26),
              AmountKeypad(
                currency: base,
                onKey: (key) => setState(() {
                  final next = applyAmountKey(
                    text: _amountText,
                    caret: _amountCaret,
                    key: key,
                    currency: base,
                  );
                  _amountText = next.text;
                  _amountCaret = next.caret;
                }),
              ),
            ],
          ),
        ),

        JourneyStep(
          iconKey: 'calendar',
          title: 'By when?',
          subtitle: 'A deadline gives Budgy a pace to hold you to',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  for (final preset in _DeadlinePreset.values)
                    BudgyChip(
                      label: preset.label,
                      dense: true,
                      selected: preset.matches(_targetDate),
                      onTap: () =>
                          setState(() => _targetDate = preset.resolve()),
                    ),
                  BudgyChip(
                    label: _targetDate == null
                        ? 'Pick a date'
                        : _targetDate!.fullLabel,
                    icon: Icons.event,
                    dense: true,
                    onTap: () async {
                      final picked = await showBudgyDatePicker(
                        context: context,
                        initialDate:
                            _targetDate ??
                            DateTime.now().add(const Duration(days: 180)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(DateTime.now().year + 20),
                      );
                      if (picked != null) {
                        setState(() => _targetDate = picked);
                      }
                    },
                  ),
                ],
              ),

              if (_targetDate != null && _targetMinor > 0) ...[
                const SizedBox(height: 22),
                _PaceCard(targetMinor: _targetMinor, targetDate: _targetDate!),
              ],

              const SizedBox(height: 24),
              Text(
                'WHAT HAPPENS WHEN YOU GET THERE',
                style: context.textTheme.labelSmall?.copyWith(color: c.text300),
              ),
              const SizedBox(height: 11),
              // Saving vs spending changes only how reaching the target is
              // framed — a reached saving goal is a celebration, a reached
              // spending goal is permission to buy the thing.
              Column(
                children: [
                  for (final kind in GoalKind.values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: BudgyCard(
                        tone: _kind == kind
                            ? BudgyCardTone.wash
                            : BudgyCardTone.band,
                        elevated: false,
                        onTap: () => setState(() => _kind = kind),
                        padding: const EdgeInsets.all(15),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    kind == GoalKind.saving
                                        ? 'I’m putting it away'
                                        : 'I’m saving up to spend it',
                                    style: context.textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    kind == GoalKind.saving
                                        ? 'An emergency fund, a cushion, a '
                                              'deposit.'
                                        : 'A laptop, a trip, a camera.',
                                    style: context.textTheme.bodySmall
                                        ?.copyWith(color: c.text300),
                                  ),
                                ],
                              ),
                            ),
                            if (_kind == kind)
                              Icon(
                                Icons.check_circle,
                                size: 20,
                                color: c.accent,
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        JourneyStep(
          iconKey: 'pencil',
          title: 'What is it?',
          subtitle: 'Name it like you’d say it out loud',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                style: context.textTheme.titleLarge,
                decoration: const InputDecoration(
                  hintText: 'Emergency fund, Japan 2027, MacBook…',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _noteController,
                maxLines: 2,
                minLines: 2,
                textCapitalization: TextCapitalization.sentences,
                style: context.textTheme.bodyMedium,
                decoration: const InputDecoration(
                  hintText: 'Why does it matter? (optional)',
                ),
              ),
              const SizedBox(height: 24),
              LookPicker(
                iconKey: _iconKey,
                colorIndex: _colorIndex,
                onIcon: (key) => setState(() => _iconKey = key),
                onColor: (index) => setState(() => _colorIndex = index),
              ),
              const SizedBox(height: 22),
              BudgyToggleTile(
                title: 'Show it on my home screen',
                value: _isPinned,
                onChanged: (value) => setState(() => _isPinned = value),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// What a pace looks like, computed live as the deadline moves — so picking
/// "in 3 months" immediately shows the daily and monthly cost of that choice.
class _PaceCard extends ConsumerWidget {
  const _PaceCard({required this.targetMinor, required this.targetDate});

  final int targetMinor;
  final DateTime targetDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.budgyColors;
    final base = ref.watch(baseCurrencyProvider);
    final days = targetDate.daysFromNow;
    if (days <= 0) return const SizedBox.shrink();
    final perDay = (targetMinor / days).ceil();
    final perMonth = (targetMinor / (days / 30.4)).ceil();

    return BudgyCard(
      tone: BudgyCardTone.wash,
      elevated: false,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'THAT’S ABOUT',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: c.text300,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    MoneyText(
                      perMonth,
                      currency: base,
                      size: MoneySize.title,
                      showDecimals: false,
                    ),
                    Text(
                      ' a month',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: c.text300,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    MoneyText(
                      perDay,
                      currency: base,
                      size: MoneySize.small,
                      color: c.text300,
                      showDecimals: false,
                    ),
                    Text(
                      ' a day for $days days',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: c.text300,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _DeadlinePreset { threeMonths, sixMonths, oneYear, twoYears, someday }

extension on _DeadlinePreset {
  String get label => switch (this) {
    _DeadlinePreset.threeMonths => '3 months',
    _DeadlinePreset.sixMonths => '6 months',
    _DeadlinePreset.oneYear => 'A year',
    _DeadlinePreset.twoYears => 'Two years',
    _DeadlinePreset.someday => 'No deadline',
  };

  DateTime? resolve() {
    final now = DateTime.now();
    return switch (this) {
      _DeadlinePreset.threeMonths => DateTime(now.year, now.month + 3, now.day),
      _DeadlinePreset.sixMonths => DateTime(now.year, now.month + 6, now.day),
      _DeadlinePreset.oneYear => DateTime(now.year + 1, now.month, now.day),
      _DeadlinePreset.twoYears => DateTime(now.year + 2, now.month, now.day),
      _DeadlinePreset.someday => null,
    };
  }

  bool matches(DateTime? date) {
    final mine = resolve();
    if (mine == null) return date == null;
    if (date == null) return false;
    return date.isSameDay(mine);
  }
}
