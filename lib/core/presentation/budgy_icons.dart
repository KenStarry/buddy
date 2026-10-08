import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// String key → glyph.
///
/// Categories, wallets, budgets and goals all store an `iconKey` **string**
/// rather than an `IconData`. Three reasons: an `IconData` cannot be JSON'd
/// without leaking a font package and a code point into the stored row; the
/// icon set can be swapped (or an SVG set layered in front of it) without a
/// data migration; and a key that no longer resolves degrades to [fallback]
/// instead of rendering the font's tofu box.
class BudgyIcons {
  BudgyIcons._();

  static const fallback = LucideIcons.circleDashed;

  /// The pickable set, grouped for the icon picker. Order is the order shown.
  static const Map<String, List<String>> pickerGroups = {
    'Money': [
      'wallet',
      'banknote',
      'coins',
      'credit-card',
      'piggy-bank',
      'landmark',
      'receipt',
      'hand-coins',
      'smartphone',
    ],
    'Everyday': [
      'utensils-crossed',
      'coffee',
      'shopping-bag',
      'shopping-cart',
      'shirt',
      'house',
      'zap',
      'wifi',
      'droplets',
      'flame',
    ],
    'Getting around': ['car', 'bus', 'bike', 'fuel', 'plane', 'train-front'],
    'Life': [
      'heart-pulse',
      'pill',
      'dumbbell',
      'baby',
      'cat',
      'dog',
      'graduation-cap',
      'book-open',
      'briefcase',
      'laptop',
    ],
    'Good times': [
      'party-popper',
      'film',
      'music',
      'gamepad-2',
      'gift',
      'palmtree',
      'ticket',
      'sparkles',
    ],
    'Targets': [
      'target',
      'trophy',
      'flag',
      'rocket',
      'mountain',
      'star',
      'shield',
    ],
  };

  /// Every pickable key, flattened.
  static List<String> get pickable =>
      pickerGroups.values.expand((g) => g).toList();

  static const Map<String, IconData> _map = {
    // Money
    'wallet': LucideIcons.wallet,
    'banknote': LucideIcons.banknote,
    'coins': LucideIcons.coins,
    'credit-card': LucideIcons.creditCard,
    'piggy-bank': LucideIcons.piggyBank,
    'landmark': LucideIcons.landmark,
    'receipt': LucideIcons.receipt,
    'hand-coins': LucideIcons.handCoins,
    'handshake': LucideIcons.handshake,
    'smartphone': LucideIcons.smartphone,
    // Everyday
    'utensils-crossed': LucideIcons.utensilsCrossed,
    'coffee': LucideIcons.coffee,
    'shopping-bag': LucideIcons.shoppingBag,
    'shopping-cart': LucideIcons.shoppingCart,
    'shirt': LucideIcons.shirt,
    'house': LucideIcons.house,
    'zap': LucideIcons.zap,
    'wifi': LucideIcons.wifi,
    'droplets': LucideIcons.droplets,
    'flame': LucideIcons.flame,
    // Getting around
    'car': LucideIcons.car,
    'bus': LucideIcons.bus,
    'bike': LucideIcons.bike,
    'fuel': LucideIcons.fuel,
    'plane': LucideIcons.plane,
    'train-front': LucideIcons.trainFront,
    // Life
    'heart-pulse': LucideIcons.heartPulse,
    'pill': LucideIcons.pill,
    'dumbbell': LucideIcons.dumbbell,
    'baby': LucideIcons.baby,
    'cat': LucideIcons.cat,
    'dog': LucideIcons.dog,
    'graduation-cap': LucideIcons.graduationCap,
    'book-open': LucideIcons.bookOpen,
    'briefcase': LucideIcons.briefcase,
    'laptop': LucideIcons.laptop,
    // Good times
    'party-popper': LucideIcons.partyPopper,
    'film': LucideIcons.film,
    'music': LucideIcons.music,
    'gamepad-2': LucideIcons.gamepad2,
    'gift': LucideIcons.gift,
    'palmtree': LucideIcons.palmtree,
    'ticket': LucideIcons.ticket,
    'sparkles': LucideIcons.sparkles,
    // Targets
    'target': LucideIcons.target,
    'trophy': LucideIcons.trophy,
    'flag': LucideIcons.flag,
    'rocket': LucideIcons.rocket,
    'mountain': LucideIcons.mountain,
    'star': LucideIcons.star,
    'shield': LucideIcons.shield,
    // Chrome — not pickable, used by the app's own UI.
    'repeat': LucideIcons.repeat,
    'rotate-cw': LucideIcons.rotateCw,
    'clock': LucideIcons.clock,
    'circle-dashed': LucideIcons.circleDashed,
  };

  /// Resolves a stored key. Unknown keys fall back rather than crash.
  static IconData resolve(String? key) => _map[key] ?? fallback;
}
