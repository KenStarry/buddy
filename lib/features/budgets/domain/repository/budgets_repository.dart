import 'package:dartz/dartz.dart';

import '../model/budget_model.dart';

abstract class BudgetsRepository {
  Future<Either<String, List<BudgetModel>>> getAll();
  Future<Either<String, BudgetModel?>> getById(String id);
  Future<Either<String, BudgetModel>> save(BudgetModel budget);
  Future<Either<String, Unit>> saveAll(Iterable<BudgetModel> budgets);
  Future<Either<String, Unit>> delete(String id);
  Future<Either<String, Unit>> deleteAll(Iterable<String> ids);
}
