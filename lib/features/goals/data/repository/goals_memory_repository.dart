import '../../../../core/data/local_collection_repository.dart';
import '../../../../core/data/ledger_seed.dart';
import '../../domain/model/goal_model.dart';
import '../../domain/repository/goals_repository.dart';

class GoalsMemoryRepository extends MemoryCollectionRepository<GoalModel>
    implements GoalsRepository {
  GoalsMemoryRepository({Iterable<GoalModel>? seed})
    : super(seed: seed ?? LedgerSeed.goals(), idOf: (g) => g.id);
}
