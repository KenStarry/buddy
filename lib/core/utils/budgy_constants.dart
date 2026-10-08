/// Build-time switches and the handful of layout numbers that genuinely need
/// to be shared. Spacing and radii stay inline at call sites per the house
/// style — only values that *two* widgets must agree on live here.
class BudgyConstants {
  BudgyConstants._();

  /// Page gutter. One number, every screen.
  static const double gutter = 20;

  /// Vertical reserve a scrollable body must leave at the bottom so its last
  /// row is not parked permanently under the floating nav. Feed it into a
  /// trailing sliver; do not eyeball it per page.
  static const double navReserve = 132;

  /// Seed the ledger with a demo month on first launch.
  ///
  /// An empty budget app is indistinguishable from a broken one: every chart
  /// is blank, every ring is at zero, and there is nothing to judge the
  /// design against. First launch lands on a furnished month that the user can
  /// wipe from Settings in one tap.
  static const bool seedDemoData = true;
}
