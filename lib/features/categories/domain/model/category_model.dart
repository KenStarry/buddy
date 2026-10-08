import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../enum/category_kind.dart';

/// A spending or earning bucket, and its subcategories.
@immutable
class CategoryModel extends Equatable {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.kind,
    required this.iconKey,
    required this.colorIndex,
    this.emoji,
    this.subcategories = const [],
    this.sortOrder = 0,
    this.isArchived = false,
  });

  final String id;
  final String name;
  final CategoryKind kind;

  /// Key into `BudgyIcons` — a Lucide glyph name, not a code point. Stored as
  /// a string so the icon set can be swapped without a data migration.
  final String iconKey;

  /// Slot in the **validated** categorical ramp (`BudgyColors.categories`).
  ///
  /// ⚠️ An index, not a colour. Budgy does not let a category carry an
  /// arbitrary hex, and that is a deliberate restriction rather than a missing
  /// feature: the eight slots were chosen together and checked for
  /// colour-vision separation as an ordered set (see `BudgyPalette`). A
  /// free-form picker hands users two categories they cannot tell apart in
  /// their own pie chart, and quietly invalidates every ΔE in that file. The
  /// picker offers the eight; the ramp stays honest.
  final int colorIndex;

  /// Optional emoji, shown in place of [iconKey] when set. Cashew leans on
  /// emoji and it is genuinely faster to scan a 🍜 than a bowl glyph.
  final String? emoji;

  final List<CategoryModel> subcategories;
  final int sortOrder;

  /// Archived categories stay on historical transactions but leave the
  /// pickers. Deleting outright would orphan a year of ledger rows.
  final bool isArchived;

  bool get hasSubcategories => subcategories.isNotEmpty;

  CategoryModel copyWith({
    String? id,
    String? name,
    CategoryKind? kind,
    String? iconKey,
    int? colorIndex,
    String? emoji,
    bool clearEmoji = false,
    List<CategoryModel>? subcategories,
    int? sortOrder,
    bool? isArchived,
  }) => CategoryModel(
    id: id ?? this.id,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    iconKey: iconKey ?? this.iconKey,
    colorIndex: colorIndex ?? this.colorIndex,
    emoji: clearEmoji ? null : (emoji ?? this.emoji),
    subcategories: subcategories ?? this.subcategories,
    sortOrder: sortOrder ?? this.sortOrder,
    isArchived: isArchived ?? this.isArchived,
  );

  factory CategoryModel.fromMap(Map<String, dynamic> map) => CategoryModel(
    id: map['id']?.toString() ?? '',
    name: map['name']?.toString() ?? 'Untitled',
    kind: CategoryKindX.fromKey(map['kind']?.toString()),
    iconKey: map['icon_key']?.toString() ?? 'circle',
    // Clamped on read, not trusted: a row written by a build with a longer
    // ramp would otherwise throw a RangeError deep inside a chart painter.
    colorIndex: ((map['color_index'] as num?)?.toInt() ?? 0).clamp(0, 7),
    emoji: (map['emoji']?.toString().isEmpty ?? true)
        ? null
        : map['emoji'].toString(),
    subcategories: [
      for (final raw in (map['subcategories'] as List<dynamic>? ?? []))
        CategoryModel.fromMap(Map<String, dynamic>.from(raw as Map)),
    ],
    sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
    isArchived: map['is_archived'] == true,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'kind': kind.storageKey,
    'icon_key': iconKey,
    'color_index': colorIndex,
    'emoji': emoji,
    'subcategories': [for (final s in subcategories) s.toMap()],
    'sort_order': sortOrder,
    'is_archived': isArchived,
  };

  @override
  List<Object?> get props => [
    id,
    name,
    kind,
    iconKey,
    colorIndex,
    emoji,
    subcategories,
    sortOrder,
    isArchived,
  ];
}
