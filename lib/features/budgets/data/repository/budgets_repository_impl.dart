import '../../../../core/data/hive_service.dart';
import '../../../../core/data/local_collection_repository.dart';
import '../../domain/model/budget_model.dart';
import '../../domain/repository/budgets_repository.dart';

class BudgetsRepositoryImpl extends LocalCollectionRepository<BudgetModel>
    implements BudgetsRepository {
  BudgetsRepositoryImpl() : super(HiveService.budgets);

  @override
  String get label => 'budgets';
}
