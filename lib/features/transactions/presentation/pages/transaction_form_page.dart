import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/domain/currency.dart';
import '../../../../core/presentation/components/budgy_date_picker.dart';
import '../../../../core/presentation/components/amount_keypad.dart';
import '../../../../core/presentation/budgy_icons.dart';
import '../../../../core/presentation/components/glass_card.dart';
import '../../../../core/presentation/components/budgy_sheet.dart';
import '../../../../core/presentation/components/amount_field.dart';
import '../../../../core/presentation/components/budgy_switch.dart';
import '../../../../core/presentation/components/option_row.dart';
import '../../../../core/presentation/components/money_text.dart';
import '../../../../core/presentation/components/pill_popover.dart';
import '../../../../core/presentation/surfaces/glow.dart';
import '../../../../core/presentation/components/press_scale.dart';
import '../../../../core/utils/budgy_constants.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/utils/extensions/date_extensions.dart';
import '../../../accounts/domain/model/account_model.dart';
import '../../../accounts/presentation/state/controllers/accounts_controller.dart';
import '../../../budgets/presentation/state/controllers/budgets_controller.dart';
import '../../../categories/domain/model/category_model.dart';
import '../../../categories/presentation/state/controllers/categories_controller.dart';
import '../../../goals/presentation/state/controllers/goals_controller.dart';
import '../../domain/enum/transaction_type.dart';
import '../../domain/model/recurrence.dart';
import '../../domain/model/transaction_model.dart';
import '../state/controllers/transactions_controller.dart';

/// Values a caller can seed a new entry with — a category from a chart tap, a
/// wallet from a wallet page, an amount from a settled bill.
@immutable
class TransactionPrefill extends Equatable {
  const TransactionPrefill({
    this.type,
    this.nature,
    this.categoryId,
    this.accountId,
    this.goalId,
    this.budgetId,
    this.amountMinor,
    this.title,
  });

  final TransactionType? type;
  final TransactionNature? nature;
  final String? categoryId;
  final String? accountId;
  final String? goalId;
  final String? budgetId;
  final int? amountMinor;
  final String? title;

  @override
  List<Object?> get props => [
    type,
    nature,
    categoryId,
    accountId,
    goalId,
    budgetId,
    amountMinor,
    title,
  ];
}

/// Add or edit one transaction.
///
/// ## One screen, not a stepper
///
/// The house rule is that multi-step journeys use `JourneyStepper` and are
/// never hand-rolled — and this screen deliberately isn't one. Logging a
/// transaction is the most frequent action in the app and has to take about
/// four seconds; a three-step wizard for a cup of coffee is the fastest way
/// to make someone stop tracking their spending. Budgets and goals *are*
/// genuine multi-step journeys and do use the stepper.
///
/// So: the keypad is on screen from the first frame, the amount is the only
/// required field, and everything else has a working default that can be
/// changed with one tap.
class TransactionFormPage extends ConsumerStatefulWidget {
  const TransactionFormPage({super.key, this.transactionId, this.prefill});

  /// Null for a new entry.
  final String? transactionId;

  final TransactionPrefill? prefill;

  @override
  ConsumerState<TransactionFormPage> createState() =>
      _TransactionFormPageState();
}

class _TransactionFormPageState extends ConsumerState<TransactionFormPage> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();

  late TransactionType _type;
  late TransactionNature _nature;
  String _amountText = '';

  /// The left-hand side of a pending calculation, and the operation waiting on
  /// a second operand. Both null for the ordinary case of simply typing a
  /// number.
  double? _accumulator;
  CalcOp? _pendingOp;

  /// Insertion point in [_amountText], in raw characters.
  int _caret = 0;
  String? _categoryId;
  String? _subcategoryId;
  String? _accountId;
  String? _destinationAccountId;
  String? _goalId;
  List<String> _budgetIds = const [];
  DateTime _date = DateTime.now();
  bool _isSettled = true;
  Recurrence? _recurrence;
  bool _hydrated = false;

  TransactionModel? get _existing => widget.transactionId == null
      ? null
      : ref
            .read(transactionsControllerProvider)
            .items
            .where((t) => t.id == widget.transactionId)
            .firstOrNull;

  bool get _isEditing => widget.transactionId != null;

  @override
  void initState() {
    super.initState();
    final prefill = widget.prefill;
    _type = prefill?.type ?? TransactionType.expense;
    _nature = prefill?.nature ?? TransactionNature.standard;
    _categoryId = prefill?.categoryId;
    _accountId = prefill?.accountId;
    _goalId = prefill?.goalId;
    _budgetIds = prefill?.budgetId == null ? const [] : [prefill!.budgetId!];
    if (prefill?.title != null) _titleController.text = prefill!.title!;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// Fills the form from the stored row, once.
  ///
  /// ⚠️ Runs from `build`, not `initState`, and is guarded by [_hydrated].
  /// The controllers are loaded asynchronously, so in `initState` the ledger
  /// can still be empty — and without the guard, every rebuild would throw
  /// away whatever the user had typed.
  void _hydrate(AccountModel? primaryAccount, List<CategoryModel> categories) {
    if (_hydrated) return;
    final existing = _existing;
    if (existing != null) {
      _type = existing.type;
      _nature = existing.nature;
      _amountText = AmountKeypad.fromMinor(
        existing.amountMinor,
        existing.currency,
      );
      _caret = _amountText.length;
      _categoryId = existing.categoryId;
      _subcategoryId = existing.subcategoryId;
      _accountId = existing.accountId;
      _destinationAccountId = existing.destinationAccountId;
      _goalId = existing.goalId;
      _budgetIds = existing.budgetIds;
      _date = existing.date;
      _isSettled = existing.isSettled;
      _recurrence = existing.recurrence;
      _titleController.text = existing.title;
      _noteController.text = existing.note ?? '';
      _hydrated = true;
      return;
    }

    // New entry: fall back to the primary wallet and, for an expense, the
    // first category — so the form is immediately saveable.
    _accountId ??= primaryAccount?.id;
    if (widget.prefill?.amountMinor != null && _amountText.isEmpty) {
      _amountText = AmountKeypad.fromMinor(
        widget.prefill!.amountMinor!,
        primaryAccount?.currency ?? CurrencyRegistry.base,
      );
      _caret = _amountText.length;
    }
    _categoryId ??= categories.firstOrNull?.id;
    _hydrated = primaryAccount != null;
  }

  AccountModel? get _account =>
      ref.read(accountsControllerProvider).byId(_accountId);

  /// What would be saved right now, with any pending operation already
  /// applied.
  ///
  /// ⚠️ This is also what the figure renders, which is the whole reason the pad
  /// needs no `=` key: the display can never disagree with the value, and
  /// pressing save before pressing equals stops being a mistake you can make.
  double get _amountValue {
    final operand = double.tryParse(_amountText.replaceAll(',', '.'));
    final left = _accumulator;
    final op = _pendingOp;
    if (left == null || op == null) return operand ?? 0;
    if (operand == null) return left;
    return op.apply(left, operand);
  }

  int get _amountMinor {
    final account = _account;
    if (account == null) return 0;
    final value = _amountValue;
    // A negative result is not an amount — the sign is carried by
    // `TransactionType`, so "100 − 250" is a sum the user is mid-way through,
    // not a −150 expense. Clamped to zero, which also leaves `_canSave` false.
    return value <= 0 ? 0 : account.currency.toMinor(value);
  }

  /// Applies one keypad press at the caret.
  void _applyKey(String key, Currency currency) {
    // Backspacing past an empty operand unwinds the calculation a step rather
    // than doing nothing — the only way back out of a mis-tapped operator.
    if (key == '⌫' && _amountText.isEmpty && _pendingOp != null) {
      setState(() {
        final left = _accumulator;
        _pendingOp = null;
        _accumulator = null;
        _amountText = left == null
            ? ''
            : AmountKeypad.fromMinor(currency.toMinor(left), currency);
        _caret = _amountText.length;
      });
      return;
    }

    final next = applyAmountKey(
      text: _amountText,
      caret: _caret,
      key: key,
      currency: currency,
    );
    setState(() {
      _amountText = next.text;
      _caret = next.caret;
    });
  }

  /// Folds the pending operation into the accumulator and starts a fresh
  /// operand.
  void _applyOperator(CalcOp op) {
    setState(() {
      final operand = double.tryParse(_amountText.replaceAll(',', '.'));
      if (operand != null) {
        _accumulator = _accumulator == null || _pendingOp == null
            ? operand
            : _pendingOp!.apply(_accumulator!, operand);
      }
      // Pressing a second operator with nothing typed between them swaps the
      // operation rather than stacking one, which is what every calculator
      // does and what a mis-tap means.
      _pendingOp = _accumulator == null ? null : op;
      _amountText = '';
      _caret = 0;
    });
  }

  bool get _canSave {
    if (_amountMinor <= 0) return false;
    if (_accountId == null) return false;
    if (_type.isTransfer) {
      // A transfer to the wallet it came from is a no-op that still writes two
      // legs, so the balance maths cancels and the row is pure noise.
      return _destinationAccountId != null &&
          _destinationAccountId != _accountId;
    }
    return true;
  }

  Future<void> _save() async {
    final account = _account;
    if (account == null || !_canSave) return;

    final existing = _existing;
    final now = DateTime.now();
    final transaction = TransactionModel(
      id: existing?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      amountMinor: _amountMinor,
      type: _type,
      nature: _nature,
      accountId: account.id,
      currencyCode: account.currencyCode,
      date: _date,
      categoryId: _type.isTransfer ? null : _categoryId,
      subcategoryId: _type.isTransfer ? null : _subcategoryId,
      destinationAccountId: _type.isTransfer ? _destinationAccountId : null,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      budgetIds: _budgetIds,
      goalId: _goalId,
      recurrence: _recurrence,
      // An unsettled-by-nature entry that the user has not explicitly settled
      // stays a plan; a standard entry is settled the moment it is written.
      isSettled: _nature.needsSettlement ? _isSettled : true,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    final ok = await ref
        .read(transactionsControllerProvider.notifier)
        .save(transaction);
    if (!mounted) return;
    if (ok) {
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That didn’t save. Give it another go?')),
      );
    }
  }

  Future<void> _delete() async {
    final id = widget.transactionId;
    if (id == null) return;
    final confirmed = await _confirmDelete();
    if (!confirmed) return;
    final ok = await ref
        .read(transactionsControllerProvider.notifier)
        .delete(id);
    if (!mounted) return;
    if (ok) context.pop();
  }

  Future<bool> _confirmDelete() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this entry?'),
        content: const Text('It won’t be in your ledger or any budget.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style: TextStyle(color: context.budgyColors.errorMain),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// The colour the whole screen is lit by.
  ///
  /// ⚠️ Keyed to **direction**, not to the chosen category. It used to follow
  /// the category, which looked right only by accident: arriving from the home
  /// screen, Spend and Income happen to default to categories of different
  /// hues. Toggling direction in place cleared the category, so the tint fell
  /// through to a single fallback and the room stopped changing at all — the
  /// one thing the glow exists to show.
  ///
  /// Direction is also the better source on its own terms: it is the entry's
  /// primary fact, it can never be unset, and money leaving versus arriving is
  /// exactly the distinction worth lighting a room over. The category's own
  /// colour still appears, in its zone on the terms bar.
  Color _tint(BuildContext context) {
    final c = context.budgyColors;
    return switch (_type) {
      TransactionType.expense => c.outflow,
      TransactionType.income => c.inflow,
      TransactionType.transfer => c.transfer,
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final accounts = ref.watch(accountsControllerProvider);
    final categoriesState = ref.watch(categoriesControllerProvider);
    final categories = _type.isIncome
        ? categoriesState.income
        : categoriesState.expense;

    _hydrate(accounts.primary, categories);

    final account = accounts.byId(_accountId) ?? accounts.primary;
    final currency = account?.currency ?? _fallbackCurrency;
    final parent = categoriesState.parentOf(_categoryId);
    final sub = categoriesState.byId(_subcategoryId);
    final tint = _tint(context);

    return Scaffold(
      backgroundColor: c.surface100,
      // ⚠️ The layout does not resize for the system keyboard. The only field
      // that raises one is the optional label near the top; letting the
      // keyboard overlay the dial keeps the label visible, where resizing
      // would compress a column that has no slack to give.
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedSwitcher(
                // Cross-faded rather than lerped — the point is that choosing
                // a category visibly changes the room.
                duration: const Duration(milliseconds: 450),
                child: AmbientGlow(
                  key: ValueKey(tint.toARGB32()),
                  fadeBottom: 0.44,
                  blooms: [
                    AmbientBloom(
                      // ⚠️ Anchored **above** the top edge and wide, so only
                      // the falloff is on screen. Centred inside the page a
                      // bloom resolves as a visible disc — a spotlight parked
                      // behind the figure — and the eye reads the rim rather
                      // than the light. Pushed off the top it becomes a wash
                      // pouring down the page, which is what the header does
                      // and what makes the two screens feel lit by the same
                      // source.
                      color: asLight(tint),
                      center: const Alignment(0, -1.0),
                      radius: 1.3,
                      strength: 0.62,
                    ),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Chrome ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    BudgyConstants.gutter,
                    6,
                    BudgyConstants.gutter,
                    0,
                  ),
                  child: Row(
                    children: [
                      GlassIconButton(
                        icon: LucideIcons.x,
                        onTap: () => context.pop(),
                      ),
                      const Spacer(),
                      if (_isEditing) ...[
                        GlassIconButton(
                          icon: LucideIcons.trash2,
                          iconColor: c.errorMain,
                          onTap: _delete,
                        ),
                        const SizedBox(width: 9),
                      ],
                      GlassIconButton(
                        icon: LucideIcons.ellipsis,
                        active: _hasExtras,
                        badge: _hasExtras,
                        onTap: _openExtras,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // ── Direction, as words ───────────────────────────────────
                //
                // ⚠️ No boxes. Three filled cells put three more mid-grey
                // rectangles on a page that already had five, and on
                // near-black every one of those costs contrast the figure
                // needs. Set in type, the live word is simply white and the
                // other two recede — which is the same amount of information
                // for none of the ink.
                _DirectionWords(type: _type, onChanged: _setType),

                // ── The figure ────────────────────────────────────────────
                //
                // Left-aligned and enormous. Centred inside a panel it read as
                // *a result*; ranged left at this size it reads as something
                // being typed, which is what it is. The panel is gone for the
                // same reason — boxing a number shrinks it.
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BudgyConstants.gutter,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // What is pending, above the running total it feeds.
                        // Without it the figure silently changes meaning the
                        // moment an operator is pressed — "1,250" stops being
                        // what you typed and becomes a left-hand side, with
                        // nothing on screen saying so.
                        AnimatedSize(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          alignment: Alignment.bottomLeft,
                          child: _pendingOp == null
                              ? const SizedBox(width: double.infinity)
                              : Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    children: [
                                      MoneyText(
                                        currency.toMinor(_accumulator ?? 0),
                                        currency: currency,
                                        size: MoneySize.small,
                                        showSymbol: false,
                                        color: c.heroInk.withValues(alpha: 0.5),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _pendingOp!.glyph,
                                        style: context.textTheme.titleMedium
                                            ?.copyWith(color: c.accent),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                        _AmountPulse(
                          // Keyed to the text only — moving the caret must not
                          // kick the figure, or every tap to reposition reads
                          // as an edit that did not happen.
                          value: _amountText,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: AmountField(
                              text: _amountText,
                              caret: _caret,
                              currency: currency,
                              style: MoneyText.baseStyle(
                                context,
                                MoneySize.entry,
                              ),
                              ink: c.heroInk,
                              sign: _type.isTransfer
                                  ? null
                                  : (_type.isIncome ? '+' : '−'),
                              onCaret: (index) =>
                                  setState(() => _caret = index),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _LabelField(
                          controller: _titleController,
                          hint: _type.isTransfer
                              ? 'What was this move for?'
                              : 'What was it?',
                        ),
                      ],
                    ),
                  ),
                ),

                // ── The terms, as one bar ─────────────────────────────────
                //
                // Five separate coloured orbs were, after the figure, the
                // loudest thing on the screen — and they are the *least*
                // important part of an entry. One bar of quiet zones says the
                // same thing as one object, and each zone still opens its own
                // panel anchored to itself.
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BudgyConstants.gutter,
                  ),
                  child: _TermsBar(
                    children: [
                      if (!_type.isTransfer)
                        _CategoryTerm(
                          categories: categories,
                          selected: categoriesState.byId(_categoryId),
                          sub: sub,
                          parent: parent,
                          onSelected: (id) => setState(() {
                            _categoryId = id;
                            _subcategoryId = null;
                          }),
                          onSub: (id) => setState(() => _subcategoryId = id),
                        ),
                      _WalletTerm(
                        account: account,
                        options: accounts.live,
                        onSelected: (id) => setState(() => _accountId = id),
                      ),
                      if (_type.isTransfer)
                        _WalletTerm(
                          account: accounts.byId(_destinationAccountId),
                          fallbackIcon: LucideIcons.arrowRight,
                          title: 'Into',
                          options: accounts.live
                              .where((a) => a.id != _accountId)
                              .toList(),
                          onSelected: (id) =>
                              setState(() => _destinationAccountId = id),
                        ),
                      _DateTerm(
                        date: _date,
                        onPick: _setDate,
                        onCustom: _pickDate,
                      ),
                      _NatureTerm(nature: _nature, onChanged: _setNature),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ── The dial ──────────────────────────────────────────────
                Expanded(
                  flex: 7,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BudgyConstants.gutter,
                      vertical: 6,
                    ),
                    child: AmountKeypad(
                      currency: currency,
                      glowTint: tint,
                      activeOp: _pendingOp,
                      onOperator: _applyOperator,
                      onKey: (key) => _applyKey(key, currency),
                    ),
                  ),
                ),

                // ── 4. Commit ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    BudgyConstants.gutter,
                    2,
                    BudgyConstants.gutter,
                    10,
                  ),
                  child: _ConfirmAction(
                    label: _isEditing ? 'Save changes' : 'Add it',
                    enabled: _canSave,
                    glow: tint,
                    onTap: _save,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Switches direction, and re-seeds the category for the new set.
  ///
  /// ⚠️ Re-defaulted, not just cleared. The category sets are disjoint, so one
  /// chosen for an expense is meaningless once this is income — but `_hydrate`
  /// only ever runs once, so nothing was putting a new one back. Clearing
  /// alone left the form with no category at all: the terms bar fell to its
  /// placeholder and the saved row lost its category.
  void _setType(TransactionType value) {
    final categories = ref.read(categoriesControllerProvider);
    setState(() {
      _type = value;
      _subcategoryId = null;
      _categoryId = value.isTransfer
          ? null
          : (value.isIncome ? categories.income : categories.expense)
                .firstOrNull
                ?.id;
    });
  }

  void _setNature(TransactionNature nature) => setState(() {
    _nature = nature;
    _isSettled = !nature.needsSettlement;
    _recurrence = nature.recurs
        ? (_recurrence ?? const Recurrence(cadence: RecurrenceCadence.monthly))
        : null;
  });

  void _setDate(DateTime date) => setState(() {
    // Keeps the original time of day, so re-dating an entry does not move it
    // to midnight and reshuffle that day's ordering.
    _date = DateTime(date.year, date.month, date.day, _date.hour, _date.minute);
    // A future date cannot be a settled fact.
    if (_date.isAfter(DateTime.now()) &&
        _nature == TransactionNature.standard) {
      _nature = TransactionNature.upcoming;
      _isSettled = false;
    }
  });

  bool get _hasExtras =>
      _noteController.text.isNotEmpty ||
      _goalId != null ||
      _budgetIds.isNotEmpty;

  /// Used only while the wallet list is still loading, so the hero has a
  /// currency to format against for a frame. Falls back to the base currency
  /// rather than to null — a `MoneyText` with no currency cannot render at
  /// all, and the wallet it will resolve to is almost always in the base one.
  Currency get _fallbackCurrency =>
      ref.read(accountsControllerProvider).live.firstOrNull?.currency ??
      CurrencyRegistry.base;

  Future<void> _pickDate() async {
    final picked = await showBudgyDatePicker(
      context: context,
      initialDate: _date,
      // Two years back is plenty for catching up a ledger; a year forward
      // covers scheduling next year's renewals.
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
    );
    if (picked == null) return;
    _setDate(picked);
  }

  static String _natureBlurb(TransactionNature nature) => switch (nature) {
    TransactionNature.standard => 'Happened. Counts right away.',
    TransactionNature.subscription => 'A recurring charge you keep paying',
    TransactionNature.repeating => 'Comes round on a schedule',
    TransactionNature.upcoming => 'Scheduled — won’t count until settled',
    TransactionNature.debt => 'You borrowed it and owe it back',
    TransactionNature.credit => 'You lent it and it’s coming back',
  };

  Future<void> _openExtras() => BudgySheet.show<void>(
    context,
    builder: (sheetContext) => _ExtrasSheet(
      noteController: _noteController,
      goalId: _goalId,
      budgetIds: _budgetIds,
      isSettled: _isSettled,
      nature: _nature,
      recurrence: _recurrence,
      onGoalChanged: (id) => setState(() => _goalId = id),
      onBudgetsChanged: (ids) => setState(() => _budgetIds = ids),
      onSettledChanged: (value) => setState(() => _isSettled = value),
      onRecurrenceChanged: (value) => setState(() => _recurrence = value),
    ),
  );
}

// ───────────────────── Pieces ────────────────────────────────────────────────

/// Direction, set in type rather than in boxes.
class _DirectionWords extends StatelessWidget {
  const _DirectionWords({required this.type, required this.onChanged});

  final TransactionType type;
  final ValueChanged<TransactionType> onChanged;

  static const _labels = {
    TransactionType.expense: 'Spend',
    TransactionType.income: 'Income',
    TransactionType.transfer: 'Move',
  };

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final ink = c.heroInk;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final option in TransactionType.values) ...[
          if (option != TransactionType.values.first)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  color: ink.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          PressScale(
            onTap: () => onChanged(option),
            haptic: HapticLevel.selection,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style:
                    context.textTheme.titleMedium?.copyWith(
                      color: ink.withValues(
                        alpha: option == type ? 0.95 : 0.34,
                      ),
                    ) ??
                    const TextStyle(),
                child: Text(_labels[option]!),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// The terms of the entry, as one quiet bar of tap zones.
class _TermsBar extends StatelessWidget {
  const _TermsBar({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    return Container(
      height: 62,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: c.heroInk.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            // A hairline between zones *inside one surface* — the sanctioned
            // use of `divider`. It is not an outline around anything.
            if (i > 0)
              Container(
                width: 1,
                margin: const EdgeInsets.symmetric(vertical: 11),
                color: c.heroInk.withValues(alpha: 0.07),
              ),
            Expanded(child: children[i]),
          ],
        ],
      ),
    );
  }
}

/// One zone of [_TermsBar]: a small glyph over a short label, lit when it
/// holds a real choice rather than a standing default.
class _Zone extends StatelessWidget {
  const _Zone({
    required this.label,
    required this.isOpen,
    required this.set,
    this.icon,
    this.emoji,
    this.tint,
  });

  final String label;
  final bool isOpen;

  /// A real choice has been made, as opposed to a default still standing.
  final bool set;

  final IconData? icon;
  final String? emoji;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final ink = c.heroInk;
    final hue = tint ?? c.accent;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: isOpen ? ink.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (emoji != null)
            Text(emoji!, style: const TextStyle(fontSize: 15))
          else
            Icon(
              icon,
              size: 16,
              color: set ? hue : ink.withValues(alpha: 0.45),
            ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: context.textTheme.bodySmall?.copyWith(
              fontSize: 10.5,
              color: ink.withValues(alpha: set ? 0.8 : 0.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTerm extends StatelessWidget {
  const _CategoryTerm({
    required this.categories,
    required this.selected,
    required this.sub,
    required this.parent,
    required this.onSelected,
    required this.onSub,
  });

  final List<CategoryModel> categories;
  final CategoryModel? selected;
  final CategoryModel? sub;
  final CategoryModel? parent;
  final ValueChanged<String> onSelected;
  final ValueChanged<String?> onSub;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final leaf = sub ?? selected;

    return PillPopover(
      panelWidth: 280,
      pill: (context, isOpen) => _Zone(
        label: leaf?.name ?? 'Category',
        emoji: selected?.emoji,
        icon: LucideIcons.shapes,
        tint: selected == null ? null : c.categoryAt(selected!.colorIndex),
        set: selected != null,
        isOpen: isOpen,
      ),
      panel: (context, close) => _Panel(
        title: 'Category',
        children: [
          for (final category in categories) ...[
            OptionRow(
              label: category.name,
              emoji: category.emoji,
              icon: BudgyIcons.resolve(category.iconKey),
              tint: c.categoryAt(category.colorIndex),
              selected: category.id == selected?.id,
              onTap: () {
                onSelected(category.id);
                close();
              },
            ),
            // The live category's subcategories open **in place**, so picking
            // "Coffee" is one gesture rather than a second trip through a
            // second control.
            if (category.id == selected?.id && category.hasSubcategories)
              Padding(
                padding: const EdgeInsets.only(left: 22, bottom: 4),
                child: Column(
                  children: [
                    for (final subcategory in category.subcategories)
                      OptionRow(
                        label: subcategory.name,
                        tint: c.categoryAt(category.colorIndex),
                        selected: subcategory.id == sub?.id,
                        onTap: () {
                          onSub(
                            subcategory.id == sub?.id ? null : subcategory.id,
                          );
                          close();
                        },
                      ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _WalletTerm extends StatelessWidget {
  const _WalletTerm({
    required this.account,
    required this.options,
    required this.onSelected,
    this.fallbackIcon,
    this.title = 'Wallet',
  });

  final AccountModel? account;
  final List<AccountModel> options;
  final ValueChanged<String> onSelected;
  final IconData? fallbackIcon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    return PillPopover(
      panelWidth: 260,
      pill: (context, isOpen) => _Zone(
        label: account?.name ?? title,
        icon: account == null
            ? (fallbackIcon ?? LucideIcons.wallet)
            : BudgyIcons.resolve(account!.iconKey),
        tint: account == null ? null : c.categoryAt(account!.colorIndex),
        set: account != null,
        isOpen: isOpen,
      ),
      panel: (context, close) => _Panel(
        title: title,
        children: [
          for (final option in options)
            OptionRow(
              label: option.name,
              sublabel: option.currency.name,
              icon: BudgyIcons.resolve(option.iconKey),
              tint: c.categoryAt(option.colorIndex),
              selected: option.id == account?.id,
              onTap: () {
                onSelected(option.id);
                close();
              },
            ),
        ],
      ),
    );
  }
}

class _DateTerm extends StatelessWidget {
  const _DateTerm({
    required this.date,
    required this.onPick,
    required this.onCustom,
  });

  final DateTime date;
  final ValueChanged<DateTime> onPick;
  final VoidCallback onCustom;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final today = DateTime.now();
    // Five days back covers catching up after a weekend, which is what almost
    // every re-dated entry actually is. Anything older goes to the picker.
    final quick = [
      for (var i = 0; i < 5; i++) today.subtract(Duration(days: i)),
    ];

    return PillPopover(
      panelWidth: 230,
      pill: (context, isOpen) => _Zone(
        label: date.relativeDayLabel,
        icon: LucideIcons.calendar,
        tint: c.accent,
        // Today is the standing default, so the zone only lights once the date
        // has actually been moved.
        set: !date.isToday,
        isOpen: isOpen,
      ),
      panel: (context, close) => _Panel(
        title: 'When',
        children: [
          for (final day in quick)
            OptionRow(
              label: day.relativeDayLabel,
              selected: day.isSameDay(date),
              onTap: () {
                onPick(day);
                close();
              },
            ),
          OptionRow(
            label: 'Pick a date…',
            icon: LucideIcons.calendarDays,
            tint: c.accent,
            selected: false,
            onTap: () {
              close();
              onCustom();
            },
          ),
        ],
      ),
    );
  }
}

class _NatureTerm extends StatelessWidget {
  const _NatureTerm({required this.nature, required this.onChanged});

  final TransactionNature nature;
  final ValueChanged<TransactionNature> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final standard = nature == TransactionNature.standard;

    return PillPopover(
      panelWidth: 290,
      pill: (context, isOpen) => _Zone(
        label: standard ? 'One-off' : nature.label,
        icon: BudgyIcons.resolve(nature.iconKey),
        tint: c.accent,
        set: !standard,
        isOpen: isOpen,
      ),
      panel: (context, close) => _Panel(
        title: 'Kind of entry',
        children: [
          for (final option in TransactionNature.values)
            OptionRow(
              label: option.label,
              sublabel: _TransactionFormPageState._natureBlurb(option),
              icon: BudgyIcons.resolve(option.iconKey),
              tint: c.accent,
              selected: option == nature,
              onTap: () {
                onChanged(option);
                close();
              },
            ),
        ],
      ),
    );
  }
}

/// Shared chrome for a panel's contents.
class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10, bottom: 8),
            child: Text(
              title.toUpperCase(),
              style: context.textTheme.labelSmall?.copyWith(
                color: c.heroInk.withValues(alpha: 0.45),
              ),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(mainAxisSize: MainAxisSize.min, children: children),
            ),
          ),
        ],
      ),
    );
  }
}

/// The commit.
///
/// ## Why it is not a full-width bar
///
/// Everything else on this screen is a circle, a word, or one soft bar — and a
/// full-width rectangle landing under a circular dial broke that outright. It
/// was also carrying real weight while **disabled**, which is weight that means
/// nothing: a dead grey slab anchoring the bottom of a screen you have not
/// given an amount to yet.
///
/// So it is a capsule, sized to its own words, and it is simply **not there**
/// until there is something to commit. The slot keeps its height either way —
/// the dial must not jump when the first digit lands — and the action arrives
/// by scaling in, which turns "you can save now" into something you see rather
/// than something you have to notice.
///
/// White fill, because white is this app's single-primary-action colour
/// everywhere. The **glow** takes the direction's hue instead, so the one
/// chromatic halo on the page belongs to the same light as the room.
class _ConfirmAction extends StatelessWidget {
  const _ConfirmAction({
    required this.label,
    required this.enabled,
    required this.glow,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final Color glow;
  final VoidCallback onTap;

  static const double _height = 58;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;

    return SizedBox(
      height: _height,
      child: Center(
        child: IgnorePointer(
          ignoring: !enabled,
          child: AnimatedScale(
            scale: enabled ? 1 : 0.86,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutBack,
            child: AnimatedOpacity(
              opacity: enabled ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: PressScale(
                onTap: onTap,
                haptic: HapticLevel.medium,
                borderRadius: BorderRadius.circular(_height / 2),
                child: Container(
                  height: _height,
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  decoration: BoxDecoration(
                    color: c.primary,
                    borderRadius: BorderRadius.circular(_height / 2),
                    boxShadow: [
                      BoxShadow(
                        color: glow.withValues(alpha: 0.45),
                        blurRadius: 30,
                        spreadRadius: -6,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.check, size: 19, color: c.primaryInk),
                      const SizedBox(width: 9),
                      Text(
                        label,
                        style: context.textTheme.labelLarge?.copyWith(
                          color: c.primaryInk,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A short scale kick each time the amount changes.
///
/// The pad already answers a press with a haptic; this is the same
/// acknowledgement for the eye, on the element the eye is actually on. Kept
/// under 4% and 140ms — at any more it reads as the number wobbling, and the
/// whole point is that entering an amount feels *solid*.
class _AmountPulse extends StatefulWidget {
  const _AmountPulse({required this.value, required this.child});

  final String value;
  final Widget child;

  @override
  State<_AmountPulse> createState() => _AmountPulseState();
}

class _AmountPulseState extends State<_AmountPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 140),
    lowerBound: 0,
    upperBound: 1,
  );

  @override
  void didUpdateWidget(_AmountPulse old) {
    super.didUpdateWidget(old);
    // Only on a real change. Rebuilds happen for every other field on this
    // screen, and a figure that twitches when you pick a wallet is noise.
    if (old.value != widget.value) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, child) {
      // Out and back within the one pass, so there is no settle frame where
      // the figure sits at the wrong size waiting to be released.
      final t = _controller.value;
      final kick = (t < 0.5 ? t / 0.5 : (1 - t) / 0.5);
      return Transform.scale(
        scale: 1 + 0.035 * Curves.easeOut.transform(kick),
        child: child,
      );
    },
    child: widget.child,
  );
}

/// The label, as a line of the composition rather than a form field.
///
/// A filled 56pt input under the figure made the one *optional* field the
/// second-loudest object on the screen. Borderless and centred, it reads as a
/// caption under the amount — present, obviously editable, and quiet until it
/// has something in it.
class _LabelField extends StatelessWidget {
  const _LabelField({required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    return TextField(
      controller: controller,
      // Ranged left, on the figure's own axis. Centred under a left-aligned
      // number it read as a caption for the whole screen rather than as this
      // entry's label.
      textAlign: TextAlign.start,
      textCapitalization: TextCapitalization.sentences,
      textInputAction: TextInputAction.done,
      cursorColor: c.accent,
      style: context.textTheme.bodyLarge?.copyWith(
        color: c.heroInk.withValues(alpha: 0.85),
      ),
      decoration: InputDecoration(
        isDense: true,
        filled: false,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        hintText: hint,
        hintStyle: context.textTheme.bodyLarge?.copyWith(
          color: c.heroInk.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

/// The things most entries never need: a note, a goal, an added budget, a
/// repeat rule, and the settled switch. Behind one tap so the fast path stays
/// fast.
/// The things most entries never need: a note, a goal, an added budget, a
/// repeat rule, and the settled switch. Behind one tap so the fast path stays
/// fast.
class _ExtrasSheet extends ConsumerWidget {
  const _ExtrasSheet({
    required this.noteController,
    required this.goalId,
    required this.budgetIds,
    required this.isSettled,
    required this.nature,
    required this.recurrence,
    required this.onGoalChanged,
    required this.onBudgetsChanged,
    required this.onSettledChanged,
    required this.onRecurrenceChanged,
  });

  final TextEditingController noteController;
  final String? goalId;
  final List<String> budgetIds;
  final bool isSettled;
  final TransactionNature nature;
  final Recurrence? recurrence;
  final ValueChanged<String?> onGoalChanged;
  final ValueChanged<List<String>> onBudgetsChanged;
  final ValueChanged<bool> onSettledChanged;
  final ValueChanged<Recurrence?> onRecurrenceChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.budgyColors;
    final ink = c.heroInk;
    final goals = ref.watch(goalsControllerProvider).live;
    final addable = ref.watch(budgetsControllerProvider).addable;

    return StatefulBuilder(
      builder: (context, setSheetState) => BudgySheet(
        title: 'A few more things',
        scrollable: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The note, on its own quiet panel rather than in a filled input.
            // The theme's `InputDecoration` paints a `surface300` slab, which
            // on this sheet is a lighter rectangle than the sheet itself —
            // a hole, not a field.
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              decoration: BoxDecoration(
                color: ink.withValues(alpha: 0.055),
                borderRadius: BorderRadius.circular(18),
              ),
              child: TextField(
                controller: noteController,
                maxLines: 4,
                minLines: 2,
                textCapitalization: TextCapitalization.sentences,
                cursorColor: c.accent,
                style: context.textTheme.bodyMedium?.copyWith(color: ink),
                decoration: InputDecoration(
                  isDense: true,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintText: 'Add a note — you’ll thank yourself later',
                  hintStyle: context.textTheme.bodyMedium?.copyWith(
                    color: ink.withValues(alpha: 0.38),
                  ),
                ),
                onChanged: (_) => setSheetState(() {}),
              ),
            ),

            if (nature.needsSettlement) ...[
              const SizedBox(height: 14),
              BudgyToggleTile(
                title: 'Already settled',
                subtitle: isSettled
                    ? 'Counts toward balances and budgets'
                    : 'Sits in Upcoming until you settle it',
                value: isSettled,
                onChanged: (value) {
                  onSettledChanged(value);
                  setSheetState(() {});
                },
              ),
            ],

            if (nature.recurs) ...[
              const _SheetLabel('Repeats'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final cadence in RecurrenceCadence.values)
                    GlassPill(
                      label: cadence.label,
                      selected: recurrence?.cadence == cadence,
                      onTap: () {
                        onRecurrenceChanged(Recurrence(cadence: cadence));
                        setSheetState(() {});
                      },
                    ),
                ],
              ),
            ],

            if (goals.isNotEmpty) ...[
              const _SheetLabel('Counts toward a goal'),
              // ⚠️ An explicit "no goal" row. Without it the only way to undo a
              // goal is to tap the chosen one again — a toggle hidden inside
              // what looks like a single-choice list.
              OptionRow(
                label: 'Not toward a goal',
                selected: goalId == null,
                onTap: () {
                  onGoalChanged(null);
                  setSheetState(() {});
                },
              ),
              for (final goal in goals)
                OptionRow(
                  label: goal.name,
                  emoji: goal.emoji,
                  icon: BudgyIcons.resolve(goal.iconKey),
                  tint: c.categoryAt(goal.colorIndex),
                  selected: goalId == goal.id,
                  onTap: () {
                    onGoalChanged(goal.id);
                    setSheetState(() {});
                  },
                ),
            ],

            if (addable.isNotEmpty) ...[
              const _SheetLabel(
                'Add to a budget',
                blurb: 'These budgets only count what you hand them.',
              ),
              for (final budget in addable)
                OptionRow(
                  label: budget.name,
                  icon: BudgyIcons.resolve(budget.iconKey),
                  tint: c.categoryAt(budget.colorIndex),
                  selected: budgetIds.contains(budget.id),
                  onTap: () {
                    final next = budgetIds.toSet();
                    next.contains(budget.id)
                        ? next.remove(budget.id)
                        : next.add(budget.id);
                    onBudgetsChanged(next.toList());
                    setSheetState(() {});
                  },
                ),
            ],

            const SizedBox(height: 22),
            Center(
              child: _ConfirmAction(
                label: 'Done',
                enabled: true,
                glow: c.accent,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A section heading inside a sheet.
class _SheetLabel extends StatelessWidget {
  const _SheetLabel(this.text, {this.blurb});

  final String text;
  final String? blurb;

  @override
  Widget build(BuildContext context) {
    final ink = context.budgyColors.heroInk;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 22, 2, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text.toUpperCase(),
            style: context.textTheme.labelSmall?.copyWith(
              color: ink.withValues(alpha: 0.45),
            ),
          ),
          if (blurb != null) ...[
            const SizedBox(height: 5),
            Text(
              blurb!,
              style: context.textTheme.bodySmall?.copyWith(
                color: ink.withValues(alpha: 0.45),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
