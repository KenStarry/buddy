import 'package:dartz/dartz.dart';

import '../model/goal_model.dart';

abstract class GoalsRepository {
  Future<Either<String, List<GoalModel>>> getAll();
  Future<Either<String, GoalModel?>> getById(String id);
  Future<Either<String, GoalModel>> save(GoalModel goal);
  Future<Either<String, Unit>> saveAll(Iterable<GoalModel> goals);
  Future<Either<String, Unit>> delete(String id);
  Future<Either<String, Unit>> deleteAll(Iterable<String> ids);
}
