import '../../../../core/data/hive_service.dart';
import '../../../../core/data/local_collection_repository.dart';
import '../../domain/model/goal_model.dart';
import '../../domain/repository/goals_repository.dart';

class GoalsRepositoryImpl extends LocalCollectionRepository<GoalModel>
    implements GoalsRepository {
  GoalsRepositoryImpl() : super(HiveService.goals);

  @override
  String get label => 'goals';
}
