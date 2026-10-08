import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/domain/currency.dart';

/// A wallet — a real-world place money sits. Cash, a bank account, M-Pesa,
/// a card.
@immutable
class AccountModel extends Equatable {
  const AccountModel({
    required this.id,
    required this.name,
    required this.currencyCode,
    required this.iconKey,
    required this.colorIndex,
    this.openingBalanceMinor = 0,
    this.isPrimary = false,
    this.excludeFromNetWorth = false,
    this.sortOrder = 0,
    this.isArchived = false,
  });

  final String id;
  final String name;

  /// ISO code. Resolve with [currency]; never compare symbols.
  final String currencyCode;

  final String iconKey;

  /// Slot in the validated categorical ramp — same discipline as
  /// `CategoryModel.colorIndex`.
  final int colorIndex;

  /// What was in the wallet before Budgy started watching. The ledger's
  /// running balance is this plus every settled movement.
  final int openingBalanceMinor;

  /// The wallet new transactions default to.
  final bool isPrimary;

  /// Credit cards and loan accounts carry a balance you do not *own*.
  /// Excluding them keeps the net-worth figure honest.
  final bool excludeFromNetWorth;

  final int sortOrder;
  final bool isArchived;

  Currency get currency => CurrencyRegistry.byCode(currencyCode);

  AccountModel copyWith({
    String? id,
    String? name,
    String? currencyCode,
    String? iconKey,
    int? colorIndex,
    int? openingBalanceMinor,
    bool? isPrimary,
    bool? excludeFromNetWorth,
    int? sortOrder,
    bool? isArchived,
  }) => AccountModel(
    id: id ?? this.id,
    name: name ?? this.name,
    currencyCode: currencyCode ?? this.currencyCode,
    iconKey: iconKey ?? this.iconKey,
    colorIndex: colorIndex ?? this.colorIndex,
    openingBalanceMinor: openingBalanceMinor ?? this.openingBalanceMinor,
    isPrimary: isPrimary ?? this.isPrimary,
    excludeFromNetWorth: excludeFromNetWorth ?? this.excludeFromNetWorth,
    sortOrder: sortOrder ?? this.sortOrder,
    isArchived: isArchived ?? this.isArchived,
  );

  factory AccountModel.fromMap(Map<String, dynamic> map) => AccountModel(
    id: map['id']?.toString() ?? '',
    name: map['name']?.toString() ?? 'Wallet',
    currencyCode: map['currency_code']?.toString() ?? CurrencyRegistry.base.code,
    iconKey: map['icon_key']?.toString() ?? 'wallet',
    colorIndex: ((map['color_index'] as num?)?.toInt() ?? 0).clamp(0, 7),
    openingBalanceMinor: (map['opening_balance_minor'] as num?)?.toInt() ?? 0,
    isPrimary: map['is_primary'] == true,
    excludeFromNetWorth: map['exclude_from_net_worth'] == true,
    sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
    isArchived: map['is_archived'] == true,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'currency_code': currencyCode,
    'icon_key': iconKey,
    'color_index': colorIndex,
    'opening_balance_minor': openingBalanceMinor,
    'is_primary': isPrimary,
    'exclude_from_net_worth': excludeFromNetWorth,
    'sort_order': sortOrder,
    'is_archived': isArchived,
  };

  @override
  List<Object?> get props => [
    id,
    name,
    currencyCode,
    iconKey,
    colorIndex,
    openingBalanceMinor,
    isPrimary,
    excludeFromNetWorth,
    sortOrder,
    isArchived,
  ];
}
