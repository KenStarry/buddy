import 'package:flutter/material.dart';

import '../../theme/extensions/budgy_colors.dart';

extension BudgyContextX on BuildContext {
  /// Budgy's semantic colour tokens. The only sanctioned way to get a colour.
  BudgyColors get budgyColors => Theme.of(this).extension<BudgyColors>()!;

  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Size get screenSize => MediaQuery.sizeOf(this);
  EdgeInsets get viewPadding => MediaQuery.viewPaddingOf(this);

  /// True on a layout wide enough to warrant two columns / a nav rail.
  bool get isWide => MediaQuery.sizeOf(this).width >= 760;
}
