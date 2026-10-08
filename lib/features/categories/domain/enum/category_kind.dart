/// Which side of the ledger a category belongs to.
///
/// Cashew splits categories into income and expense sets; Budgy keeps that
/// split because it is what makes the category picker short — when you are
/// entering a coffee, "Salary" has no business being on screen.
enum CategoryKind { expense, income }

extension CategoryKindX on CategoryKind {
  String get label => switch (this) {
    CategoryKind.expense => 'Expense',
    CategoryKind.income => 'Income',
  };

  String get storageKey => name;

  static CategoryKind fromKey(String? key) => CategoryKind.values.firstWhere(
    (k) => k.name == key,
    orElse: () => CategoryKind.expense,
  );
}
