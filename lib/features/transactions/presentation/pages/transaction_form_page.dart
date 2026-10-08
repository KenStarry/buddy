import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/domain/currency.dart';
import '../../../../core/presentation/components/amount_keypad.dart';
import '../../../../core/presentation/components/budgy_button.dart';
import '../../../../core/presentation/components/budgy_card.dart';
import '../../../../core/presentation/components/budgy_chip.dart';
import '../../../../core/presentation/components/budgy_sheet.dart';
import '../../../../core/presentation/components/category_glyph.dart';
import '../../../../core/presentation/components/money_text.dart';
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
    }
    _categoryId ??= categories.firstOrNull?.id;
    _hydrated = primaryAccount != null;
  }

  AccountModel? get _account =>
      ref.read(accountsControllerProvider).byId(_accountId);

  int get _amountMinor {
    final account = _account;
    if (account == null) return 0;
    return AmountKeypad.toMinor(_amountText, account.currency);
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
    final currency = account?.currency;
    final category = categoriesState.byId(_subcategoryId ?? _categoryId);
    final parent = categoriesState.parentOf(_categoryId);

    return Scaffold(
      backgroundColor: c.surface100,
      body: SafeArea(
        child: Column(
          children: [
            // ── Chrome ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                BudgyConstants.gutter,
                8,
                BudgyConstants.gutter,
                0,
              ),
              child: Row(
                children: [
                  BudgyIconButton(
                    icon: LucideIcons.x,
                    onTap: () => context.pop(),
                  ),
                  const Spacer(),
                  Text(
                    _isEditing ? 'Edit entry' : 'New entry',
                    style: context.textTheme.titleMedium,
                  ),
                  const Spacer(),
                  if (_isEditing)
                    BudgyIconButton(
                      icon: LucideIcons.trash2,
                      iconColor: c.errorMain,
                      onTap: _delete,
                    )
                  else
                    const SizedBox(width: 44),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ── Direction ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BudgyConstants.gutter,
              ),
              child: SegmentedPillTabs(
                labels: const ['Spent', 'Earned', 'Moved'],
                index: _type.index,
                onChanged: (index) => setState(() {
                  _type = TransactionType.values[index];
                  // The category sets are disjoint, so a category chosen for
                  // an expense is meaningless once this becomes income.
                  // Clearing it is better than silently keeping a "Salary"
                  // expense.
                  _categoryId = null;
                  _subcategoryId = null;
                }),
              ),
            ),

            // ── The amount ────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: BudgyConstants.gutter,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 26),
                    MoneyText(
                      _amountMinor,
                      currency: currency ?? _fallbackCurrency,
                      size: MoneySize.hero,
                      showDecimals: _amountText.contains('.'),
                      color: _amountMinor == 0 ? c.text300 : c.text100,
                    ).animate(target: _amountMinor == 0 ? 0 : 1).scaleXY(
                      begin: 0.98,
                      end: 1,
                      duration: 180.ms,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      [
                        if (_type.isTransfer)
                          '${account?.name ?? '—'} → '
                              '${accounts.byId(_destinationAccountId)?.name ?? 'pick a wallet'}'
                        else ...[
                          category?.name ?? 'Pick a category',
                          account?.name ?? 'Pick a wallet',
                        ],
                        _date.relativeDayLabel,
                      ].join(' · '),
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: c.text300,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Category rail ─────────────────────────────────────
                    if (!_type.isTransfer)
                      _CategoryRail(
                        categories: categories,
                        selectedId: _categoryId,
                        onSelected: (id) => setState(() {
                          _categoryId = id;
                          _subcategoryId = null;
                        }),
                      ),

                    if (!_type.isTransfer &&
                        (parent?.hasSubcategories ?? false)) ...[
                      const SizedBox(height: 10),
                      _SubcategoryRail(
                        parent: parent!,
                        selectedId: _subcategoryId,
                        onSelected: (id) =>
                            setState(() => _subcategoryId = id),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // ── Title ─────────────────────────────────────────────
                    TextField(
                      controller: _titleController,
                      textCapitalization: TextCapitalization.sentences,
                      style: context.textTheme.bodyLarge,
                      decoration: const InputDecoration(
                        hintText: 'What was it? (optional)',
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── Row of one-tap options ────────────────────────────
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        BudgyChip(
                          label: account?.name ?? 'Wallet',
                          icon: LucideIcons.wallet,
                          dense: true,
                          onTap: () => _pickAccount(
                            accounts.live,
                            onPicked: (id) => setState(() => _accountId = id),
                            title: _type.isTransfer ? 'From' : 'Wallet',
                          ),
                        ),
                        if (_type.isTransfer)
                          BudgyChip(
                            label:
                                accounts.byId(_destinationAccountId)?.name ??
                                'To wallet',
                            icon: LucideIcons.arrowRight,
                            dense: true,
                            selected: _destinationAccountId != null,
                            onTap: () => _pickAccount(
                              accounts.live
                                  .where((a) => a.id != _accountId)
                                  .toList(),
                              onPicked: (id) =>
                                  setState(() => _destinationAccountId = id),
                              title: 'To',
                            ),
                          ),
                        BudgyChip(
                          label: _date.relativeDayLabel,
                          icon: LucideIcons.calendar,
                          dense: true,
                          onTap: _pickDate,
                        ),
                        BudgyChip(
                          label: _nature.label,
                          icon: LucideIcons.repeat,
                          dense: true,
                          selected: _nature != TransactionNature.standard,
                          onTap: _pickNature,
                        ),
                        _MoreChip(
                          hasExtras:
                              _noteController.text.isNotEmpty ||
                              _goalId != null ||
                              _budgetIds.isNotEmpty,
                          onTap: _openExtras,
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    AmountKeypad(
                      text: _amountText,
                      currency: currency ?? _fallbackCurrency,
                      onChanged: (value) =>
                          setState(() => _amountText = value),
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // ── Save ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                BudgyConstants.gutter,
                4,
                BudgyConstants.gutter,
                10,
              ),
              child: BudgyFilledButton(
                label: _isEditing ? 'Save changes' : 'Add it',
                icon: LucideIcons.check,
                width: double.infinity,
                disabled: !_canSave,
                onTap: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Used only while the wallet list is still loading, so the hero has a
  /// currency to format against for a frame. Falls back to the base currency
  /// rather than to null — a `MoneyText` with no currency cannot render at
  /// all, and the wallet it will resolve to is almost always in the base one.
  Currency get _fallbackCurrency =>
      ref.read(accountsControllerProvider).live.firstOrNull?.currency ??
      CurrencyRegistry.base;

  Future<void> _pickAccount(
    List<AccountModel> options, {
    required void Function(String id) onPicked,
    required String title,
  }) => BudgySheet.show<void>(
    context,
    builder: (sheetContext) => BudgySheet(
      title: title,
      child: Column(
        children: [
          for (final account in options)
            PressScale(
              onTap: () {
                onPicked(account.id);
                Navigator.of(sheetContext).pop();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Row(
                  children: [
                    CategoryGlyph(
                      colorIndex: account.colorIndex,
                      iconKey: account.iconKey,
                      size: 40,
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Text(
                        account.name,
                        style: context.textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      account.currencyCode,
                      style: context.textTheme.labelMedium?.copyWith(
                        color: context.budgyColors.text300,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      // Two years back is plenty for catching up a ledger; a year forward
      // covers scheduling next year's renewals.
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
    );
    if (picked == null) return;
    setState(() {
      // Keeps the original time of day, so re-dating an entry does not move
      // it to midnight and reshuffle that day's ordering.
      _date = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _date.hour,
        _date.minute,
      );
      // A future date cannot be a settled fact.
      if (_date.isAfter(DateTime.now()) &&
          _nature == TransactionNature.standard) {
        _nature = TransactionNature.upcoming;
        _isSettled = false;
      }
    });
  }

  Future<void> _pickNature() => BudgySheet.show<void>(
    context,
    builder: (sheetContext) => BudgySheet(
      title: 'What kind of entry?',
      subtitle: 'Changes how Budgy treats it',
      child: Column(
        children: [
          for (final nature in TransactionNature.values)
            PressScale(
              onTap: () {
                setState(() {
                  _nature = nature;
                  _isSettled = !nature.needsSettlement;
                  _recurrence = nature.recurs
                      ? (_recurrence ??
                            const Recurrence(
                              cadence: RecurrenceCadence.monthly,
                            ))
                      : null;
                });
                Navigator.of(sheetContext).pop();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    CategoryGlyph(
                      colorIndex: 2,
                      iconKey: nature.iconKey,
                      size: 38,
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nature.label,
                            style: context.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 1),
                          Text(
                            _natureBlurb(nature),
                            style: context.textTheme.bodySmall?.copyWith(
                              color: context.budgyColors.text300,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_nature == nature)
                      Icon(
                        LucideIcons.check,
                        size: 18,
                        color: context.budgyColors.accent,
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );

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

class _CategoryRail extends StatelessWidget {
  const _CategoryRail({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<CategoryModel> categories;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = categories[index];
          final active = category.id == selectedId;
          return PressScale(
            onTap: () => onSelected(category.id),
            haptic: HapticLevel.selection,
            child: SizedBox(
              width: 68,
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      // A selection ring around the live category — a
                      // mark on a control, not an outline on a surface.
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: active
                            ? c.categoryAt(category.colorIndex)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: CategoryGlyph(
                      colorIndex: category.colorIndex,
                      iconKey: category.iconKey,
                      emoji: category.emoji,
                      size: 46,
                      solid: active,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: context.textTheme.labelMedium?.copyWith(
                      color: active ? c.text100 : c.text300,
                      fontSize: 10.5,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SubcategoryRail extends StatelessWidget {
  const _SubcategoryRail({
    required this.parent,
    required this.selectedId,
    required this.onSelected,
  });

  final CategoryModel parent;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          for (final sub in parent.subcategories)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: BudgyChip(
                label: sub.name,
                dense: true,
                tint: c.categoryAt(parent.colorIndex),
                selected: sub.id == selectedId,
                // Tapping the live subcategory clears it — the parent on its
                // own is a valid choice, and without this there is no way
                // back to it.
                onTap: () => onSelected(sub.id == selectedId ? null : sub.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _MoreChip extends StatelessWidget {
  const _MoreChip({required this.hasExtras, required this.onTap});

  final bool hasExtras;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => BudgyChip(
    label: hasExtras ? 'More · set' : 'More',
    icon: LucideIcons.ellipsis,
    dense: true,
    selected: hasExtras,
    onTap: onTap,
  );
}

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
    final goals = ref.watch(goalsControllerProvider).live;
    final addable = ref.watch(budgetsControllerProvider).addable;

    return StatefulBuilder(
      builder: (context, setSheetState) => BudgySheet(
        title: 'A few more things',
        scrollable: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: noteController,
              maxLines: 3,
              minLines: 2,
              textCapitalization: TextCapitalization.sentences,
              style: context.textTheme.bodyMedium,
              decoration: const InputDecoration(
                hintText: 'Add a note — you’ll thank yourself later',
              ),
              onChanged: (_) => setSheetState(() {}),
            ),

            if (nature.needsSettlement) ...[
              const SizedBox(height: 20),
              BudgyCard(
                tone: BudgyCardTone.band,
                elevated: false,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: isSettled,
                  activeTrackColor: c.accent,
                  title: Text(
                    'Already settled',
                    style: context.textTheme.titleSmall,
                  ),
                  subtitle: Text(
                    isSettled
                        ? 'Counts toward balances and budgets'
                        : 'Sits in Upcoming until you settle it',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: c.text300,
                    ),
                  ),
                  onChanged: (value) {
                    onSettledChanged(value);
                    setSheetState(() {});
                  },
                ),
              ),
            ],

            if (nature.recurs) ...[
              const SizedBox(height: 20),
              Text(
                'REPEATS',
                style: context.textTheme.labelSmall?.copyWith(
                  color: c.text300,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  for (final cadence in RecurrenceCadence.values)
                    BudgyChip(
                      label: cadence.label,
                      dense: true,
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
              const SizedBox(height: 20),
              Text(
                'COUNTS TOWARD A GOAL',
                style: context.textTheme.labelSmall?.copyWith(
                  color: c.text300,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final goal in goals)
                    BudgyChip(
                      label: goal.name,
                      emoji: goal.emoji,
                      dense: true,
                      tint: c.categoryAt(goal.colorIndex),
                      selected: goalId == goal.id,
                      onTap: () {
                        onGoalChanged(goalId == goal.id ? null : goal.id);
                        setSheetState(() {});
                      },
                    ),
                ],
              ),
            ],

            if (addable.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'ADD TO A BUDGET',
                style: context.textTheme.labelSmall?.copyWith(
                  color: c.text300,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'These budgets only count what you hand them.',
                style: context.textTheme.bodySmall?.copyWith(
                  color: c.text300,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final budget in addable)
                    BudgyChip(
                      label: budget.name,
                      dense: true,
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
              ),
            ],

            const SizedBox(height: 22),
            BudgyFilledButton(
              label: 'Done',
              width: double.infinity,
              onTap: () async => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
