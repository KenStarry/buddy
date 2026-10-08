import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/presentation/components/budgy_button.dart';
import '../../../../core/presentation/components/budgy_card.dart';
import '../../../../core/presentation/components/budgy_chip.dart';
import '../../../../core/presentation/components/budgy_masthead.dart';
import '../../../../core/presentation/components/budgy_sheet.dart';
import '../../../../core/presentation/components/category_glyph.dart';
import '../../../../core/presentation/components/look_picker.dart';
import '../../../../core/presentation/components/money_text.dart';
import '../../../../core/utils/budgy_constants.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../modules/ledger/domain/ledger_math.dart';
import '../../../../modules/ledger/state/providers/ledger_providers.dart';
import '../../domain/enum/category_kind.dart';
import '../../domain/model/category_model.dart';
import '../state/controllers/categories_controller.dart';

/// Manage categories: add, edit, archive, and see what each has cost.
class CategoriesPage extends ConsumerStatefulWidget {
  const CategoriesPage({super.key});

  @override
  ConsumerState<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends ConsumerState<CategoriesPage> {
  int _tab = 0;

  CategoryKind get _kind =>
      _tab == 0 ? CategoryKind.expense : CategoryKind.income;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final state = ref.watch(categoriesControllerProvider);
    final categories = state.ofKind(_kind);
    final base = ref.watch(baseCurrencyProvider);
    // Lifetime totals per category, so the list says which ones actually
    // matter rather than just listing eleven equal rows.
    final spend = {
      for (final s in LedgerMath.spendByCategory(
        ref.watch(ledgerProvider),
        base,
      ))
        s.categoryId: s.minor,
    };

    return Scaffold(
      backgroundColor: c.surface100,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                BudgyConstants.gutter,
                8,
                BudgyConstants.gutter,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    BudgyIconButton(
                      icon: LucideIcons.arrowLeft,
                      onTap: () => context.pop(),
                    ),
                    const Spacer(),
                    BudgyIconButton(
                      icon: LucideIcons.plus,
                      tone: c.accentSoft,
                      iconColor: c.accent,
                      onTap: () => _edit(null),
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                BudgyConstants.gutter,
                18,
                BudgyConstants.gutter,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: BudgyMasthead(
                  eyebrow: 'Categories',
                  title: 'How you label things',
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 22)),

            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: BudgyConstants.gutter,
              ),
              sliver: SliverToBoxAdapter(
                child: SegmentedPillTabs(
                  labels: const ['Spending', 'Income'],
                  index: _tab,
                  onChanged: (index) => setState(() => _tab = index),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: BudgyConstants.gutter,
              ),
              sliver: SliverList.separated(
                itemCount: categories.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return BudgyCard(
                    padding: const EdgeInsets.all(14),
                    onTap: () => _edit(category),
                    child: Row(
                      children: [
                        CategoryGlyph(
                          colorIndex: category.colorIndex,
                          iconKey: category.iconKey,
                          emoji: category.emoji,
                          size: 42,
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.name,
                                style: context.textTheme.titleMedium,
                              ),
                              if (category.hasSubcategories) ...[
                                const SizedBox(height: 2),
                                Text(
                                  category.subcategories
                                      .map((s) => s.name)
                                      .join(' · '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.textTheme.bodySmall
                                      ?.copyWith(color: c.text300),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (spend[category.id] != null)
                          MoneyText(
                            spend[category.id]!,
                            currency: base,
                            size: MoneySize.small,
                            color: c.text300,
                            showDecimals: false,
                            showSymbol: false,
                          ),
                        const SizedBox(width: 6),
                        Icon(
                          LucideIcons.chevronRight,
                          size: 16,
                          color: c.text300,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            SliverToBoxAdapter(
              child: SizedBox(height: 40 + context.viewPadding.bottom),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(CategoryModel? existing) => BudgySheet.show<void>(
    context,
    builder: (_) => _CategorySheet(existing: existing, kind: _kind),
  );
}

class _CategorySheet extends ConsumerStatefulWidget {
  const _CategorySheet({required this.existing, required this.kind});

  final CategoryModel? existing;
  final CategoryKind kind;

  @override
  ConsumerState<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends ConsumerState<_CategorySheet> {
  late final _nameController = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  late String _iconKey = widget.existing?.iconKey ?? 'shopping-bag';
  late int _colorIndex = widget.existing?.colorIndex ?? 0;
  late String? _emoji = widget.existing?.emoji;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final existing = widget.existing;
    final category = CategoryModel(
      id: existing?.id ?? const Uuid().v4(),
      name: _nameController.text.trim().isEmpty
          ? 'Untitled'
          : _nameController.text.trim(),
      kind: existing?.kind ?? widget.kind,
      iconKey: _iconKey,
      colorIndex: _colorIndex,
      emoji: _emoji,
      // Subcategories are preserved rather than re-collected: this sheet does
      // not edit them, and rebuilding the model without them would silently
      // delete every subcategory on an unrelated rename.
      subcategories: existing?.subcategories ?? const [],
      sortOrder:
          existing?.sortOrder ??
          ref.read(categoriesControllerProvider).ofKind(widget.kind).length,
      isArchived: existing?.isArchived ?? false,
    );
    await ref.read(categoriesControllerProvider.notifier).save(category);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _archive() async {
    final existing = widget.existing;
    if (existing == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hide “${existing.name}”?'),
        content: const Text(
          'It stays on everything you’ve already logged — it just stops '
          'showing up when you add something new.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hide it'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(categoriesControllerProvider.notifier).remove(existing.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    return BudgySheet(
      title: widget.existing == null ? 'New category' : 'Edit category',
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.sentences,
            style: context.textTheme.titleLarge,
            decoration: const InputDecoration(hintText: 'Name it'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 18),
          Text(
            'EMOJI (OPTIONAL)',
            style: context.textTheme.labelSmall?.copyWith(color: c.text300),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              BudgyChip(
                label: 'None',
                dense: true,
                selected: _emoji == null,
                onTap: () => setState(() => _emoji = null),
              ),
              for (final emoji in _emojiChoices)
                BudgyChip(
                  label: emoji,
                  dense: true,
                  selected: _emoji == emoji,
                  onTap: () => setState(() => _emoji = emoji),
                ),
            ],
          ),
          const SizedBox(height: 22),
          LookPicker(
            iconKey: _iconKey,
            colorIndex: _colorIndex,
            onIcon: (key) => setState(() => _iconKey = key),
            onColor: (index) => setState(() => _colorIndex = index),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              if (widget.existing != null) ...[
                BudgyTonalButton(
                  label: 'Hide',
                  icon: LucideIcons.eyeOff,
                  destructive: true,
                  onTap: _archive,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: BudgyFilledButton(
                  label: 'Save',
                  width: double.infinity,
                  onTap: _save,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// A short, curated set. A full emoji keyboard is the platform's job; this
  /// is the dozen that actually get used on a money category.
  static const _emojiChoices = [
    '🍜', '☕', '🛍️', '🚗', '⚡', '🏡', '🎉', '💚', '📚', '💼', '💻', '🎁',
    '✈️', '🐾', '🎮', '💊',
  ];
}
