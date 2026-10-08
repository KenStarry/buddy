import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/presentation/budgy_icons.dart';
import '../../../../core/presentation/components/amount_keypad.dart';
import '../../../../core/presentation/components/budgy_card.dart';
import '../../../../core/presentation/components/budgy_chip.dart';
import '../../../../core/presentation/components/look_picker.dart';
import '../../../../core/presentation/components/money_text.dart';
import '../../../../core/presentation/components/stepper/journey_stepper.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/utils/extensions/date_extensions.dart';
import '../../../../modules/ledger/state/providers/ledger_providers.dart';
import '../../../categories/presentation/state/controllers/categories_controller.dart';
import '../../domain/enum/budget_period.dart';
import '../../domain/model/budget_model.dart';
import '../state/controllers/budgets_controller.dart';

/// Create or edit a budget — a genuine multi-step journey, so it uses
/// [JourneyStepper] rather than a hand-rolled wizard.
///
/// Four steps, in the order the decisions actually depend on each other:
/// *how much* → *how often* → *what counts* → *name it*. Asking for a name
/// first (the usual form order) makes the user name a thing they have not yet
/// decided the shape of.
class BudgetFormPage extends ConsumerStatefulWidget {
  const BudgetFormPage({super.key, this.budgetId});

  final String? budgetId;

  @override
  ConsumerState<BudgetFormPage> createState() => _BudgetFormPageState();
}

class _BudgetFormPageState extends ConsumerState<BudgetFormPage> {
  final _nameController = TextEditingController();

  String _amountText = '';
  BudgetPeriod _period = BudgetPeriod.monthly;
  int _customDays = 30;
  DateTime _anchor = DateTime.now().startOfMonth;
  Set<String> _categoryIds = {};
  Map<String, int> _categoryLimits = {};
  String _iconKey = 'wallet';
  int _colorIndex = 0;
  bool _isAddedOnly = false;
  bool _isPinned = true;
  bool _hydrated = false;

  BudgetModel? get _existing =>
      ref.read(budgetsControllerProvider).byId(widget.budgetId);

  bool get _isEditing => widget.budgetId != null;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _hydrate() {
    if (_hydrated) return;
    _hydrated = true;
    final existing = _existing;
    if (existing == null) return;
    _amountText = AmountKeypad.fromMinor(
      existing.limitMinor,
      existing.currency,
    );
    _period = existing.period;
    _customDays = existing.customDays;
    _anchor = existing.anchorDate;
    _categoryIds = existing.categoryIds.toSet();
    _categoryLimits = Map.of(existing.categoryLimits);
    _iconKey = existing.iconKey;
    _colorIndex = existing.colorIndex;
    _isAddedOnly = existing.isAddedOnly;
    _isPinned = existing.isPinned;
    _nameController.text = existing.name;
  }

  int get _limitMinor =>
      AmountKeypad.toMinor(_amountText, ref.read(baseCurrencyProvider));

  Future<bool> _save() async {
    final base = ref.read(baseCurrencyProvider);
    final existing = _existing;
    final budget = BudgetModel(
      id: existing?.id ?? const Uuid().v4(),
      name: _nameController.text.trim().isEmpty
          ? 'Budget'
          : _nameController.text.trim(),
      limitMinor: _limitMinor,
      currencyCode: existing?.currencyCode ?? base.code,
      period: _period,
      anchorDate: _anchor,
      iconKey: _iconKey,
      colorIndex: _colorIndex,
      customDays: _customDays,
      // An added-only budget ignores category and wallet filters entirely, so
      // carrying them would store scope that can never apply — and would come
      // back if the user later flipped the switch off, silently widening a
      // budget they had deliberately narrowed.
      categoryIds: _isAddedOnly ? const [] : _categoryIds.toList(),
      categoryLimits: _isAddedOnly ? const {} : _categoryLimits,
      isAddedOnly: _isAddedOnly,
      isPinned: _isPinned,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );
    return ref.read(budgetsControllerProvider.notifier).save(budget);
  }

  @override
  Widget build(BuildContext context) {
    _hydrate();
    final base = ref.watch(baseCurrencyProvider);
    final categories = ref.watch(categoriesControllerProvider).expense;

    return JourneyStepper(
      kicker: _isEditing ? 'this budget' : 'your budget',
      completeLabel: _isEditing ? 'Save changes' : 'Create budget',
      onExit: () => context.pop(),
      onDone: () => context.pop(),
      outcome: JourneyOutcome(
        title: _isEditing ? 'Updated' : 'You’re set',
        subtitle: _isEditing
            ? 'Your budget’s been brought up to date.'
            : 'Budgy will keep an eye on it and tell you how you’re pacing.',
      ),
      onComplete: _save,
      steps: [
        JourneyStep(
          iconKey: 'banknote',
          title: 'How much?',
          subtitle: 'The ceiling for one period',
          canContinue: _limitMinor > 0,
          content: Column(
            children: [
              const SizedBox(height: 10),
              MoneyText(
                _limitMinor,
                currency: base,
                size: MoneySize.hero,
                showDecimals: _amountText.contains('.'),
                color: _limitMinor == 0
                    ? context.budgyColors.text300
                    : context.budgyColors.text100,
              ),
              const SizedBox(height: 26),
              AmountKeypad(
                text: _amountText,
                currency: base,
                onChanged: (value) => setState(() => _amountText = value),
              ),
            ],
          ),
        ),

        JourneyStep(
          iconKey: 'calendar',
          title: 'How often does it reset?',
          subtitle: 'Budgy starts the count again each period',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  for (final period in BudgetPeriod.values)
                    BudgyChip(
                      label: period.label,
                      selected: _period == period,
                      onTap: () => setState(() {
                        _period = period;
                        // The anchor's meaning changes with the period, so it
                        // is re-derived rather than kept: a monthly budget
                        // anchored mid-week is fine, but a weekly one
                        // anchored to the 1st resets on whatever weekday that
                        // happened to be.
                        _anchor = switch (period) {
                          BudgetPeriod.weekly => DateTime.now().startOfWeek,
                          BudgetPeriod.monthly => DateTime.now().startOfMonth,
                          BudgetPeriod.yearly => DateTime.now().startOfYear,
                          BudgetPeriod.custom => DateTime.now().startOfDay,
                        };
                      }),
                    ),
                ],
              ),

              if (_period == BudgetPeriod.custom) ...[
                const SizedBox(height: 22),
                Text(
                  'HOW MANY DAYS',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: context.budgyColors.text300,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final days in const [7, 14, 30, 45, 60, 90])
                      BudgyChip(
                        label: '$days days',
                        dense: true,
                        selected: _customDays == days,
                        onTap: () => setState(() => _customDays = days),
                      ),
                  ],
                ),
              ],

              const SizedBox(height: 22),
              _AnchorRow(
                period: _period,
                anchor: _anchor,
                customDays: _customDays,
                onPick: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _anchor,
                    firstDate: DateTime(DateTime.now().year - 2),
                    lastDate: DateTime(DateTime.now().year + 1, 12, 31),
                  );
                  if (picked != null) setState(() => _anchor = picked);
                },
              ),
            ],
          ),
        ),

        JourneyStep(
          iconKey: 'shopping-bag',
          title: 'What counts toward it?',
          subtitle: 'Leave it open and everything you spend counts',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BudgyCard(
                tone: BudgyCardTone.band,
                elevated: false,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _isAddedOnly,
                  activeTrackColor: context.budgyColors.accent,
                  title: Text(
                    'Only what I add by hand',
                    style: context.textTheme.titleSmall,
                  ),
                  subtitle: Text(
                    'An envelope for a trip or a project — nothing lands in '
                    'it unless you put it there.',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.budgyColors.text300,
                    ),
                  ),
                  onChanged: (value) => setState(() => _isAddedOnly = value),
                ),
              ),

              if (!_isAddedOnly) ...[
                const SizedBox(height: 22),
                Row(
                  children: [
                    Text(
                      'CATEGORIES',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: context.budgyColors.text300,
                      ),
                    ),
                    const Spacer(),
                    if (_categoryIds.isNotEmpty)
                      BudgyChip(
                        label: 'All of them',
                        dense: true,
                        onTap: () => setState(() {
                          _categoryIds.clear();
                          _categoryLimits.clear();
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _categoryIds.isEmpty
                      ? 'Everything counts right now. Pick some to narrow it.'
                      : '${_categoryIds.length} selected',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.budgyColors.text300,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final category in categories)
                      BudgyChip(
                        label: category.name,
                        emoji: category.emoji,
                        dense: true,
                        tint: context.budgyColors.categoryAt(
                          category.colorIndex,
                        ),
                        selected: _categoryIds.contains(category.id),
                        onTap: () => setState(() {
                          if (_categoryIds.remove(category.id)) {
                            // Dropping a category also drops its sub-limit,
                            // or the budget keeps a ceiling for something it
                            // no longer watches.
                            _categoryLimits.remove(category.id);
                          } else {
                            _categoryIds.add(category.id);
                          }
                        }),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),

        JourneyStep(
          iconKey: 'pencil',
          title: 'Give it a name',
          subtitle: 'Something you’ll recognise at a glance',
          canContinue: true,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                style: context.textTheme.titleLarge,
                decoration: const InputDecoration(
                  hintText: 'Monthly spend, Eating well, Diani trip…',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 24),
              LookPicker(
                iconKey: _iconKey,
                colorIndex: _colorIndex,
                onIcon: (key) => setState(() => _iconKey = key),
                onColor: (index) => setState(() => _colorIndex = index),
              ),
              const SizedBox(height: 22),
              BudgyCard(
                tone: BudgyCardTone.band,
                elevated: false,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _isPinned,
                  activeTrackColor: context.budgyColors.accent,
                  title: Text(
                    'Show it on my home screen',
                    style: context.textTheme.titleSmall,
                  ),
                  onChanged: (value) => setState(() => _isPinned = value),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnchorRow extends StatelessWidget {
  const _AnchorRow({
    required this.period,
    required this.anchor,
    required this.customDays,
    required this.onPick,
  });

  final BudgetPeriod period;
  final DateTime anchor;
  final int customDays;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final window = BudgetPeriodMath.windowFor(
      period: period,
      anchor: anchor,
      date: DateTime.now(),
      customDays: customDays,
    );

    return BudgyCard(
      tone: BudgyCardTone.wash,
      elevated: false,
      onTap: onPick,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RESETS ON',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: c.text300,
                  ),
                ),
                const SizedBox(height: 6),
                Text(_resetLabel(), style: context.textTheme.titleMedium),
                const SizedBox(height: 4),
                // Shows the window this anchor actually produces, because
                // "the 31st" and "every 45 days from today" are both easy to
                // pick and hard to picture.
                Text(
                  'Right now that’s ${window.label}',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: c.text300,
                  ),
                ),
              ],
            ),
          ),
          Icon(BudgyIcons.resolve('calendar'), size: 18, color: c.accent),
        ],
      ),
    );
  }

  String _resetLabel() => switch (period) {
    BudgetPeriod.weekly => 'Every ${_weekday(anchor.weekday)}',
    BudgetPeriod.monthly => 'Day ${anchor.day} of each month',
    BudgetPeriod.yearly => '${anchor.day} ${anchor.monthShort}, yearly',
    BudgetPeriod.custom => 'Every $customDays days from ${anchor.fullLabel}',
  };

  static String _weekday(int weekday) => const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ][(weekday - 1).clamp(0, 6)];
}
