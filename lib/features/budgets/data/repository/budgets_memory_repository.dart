import '../../../../core/data/local_collection_repository.dart';
import '../../../../core/data/ledger_seed.dart';
import '../../domain/model/budget_model.dart';
import '../../domain/repository/budgets_repository.dart';

class BudgetsMemoryRepository extends MemoryCollectionRepository<BudgetModel>
    implements BudgetsRepository {
  BudgetsMemoryRepository({Iterable<BudgetModel>? seed})
    : super(seed: seed ?? LedgerSeed.budgets(), idOf: (b) => b.id);
}
