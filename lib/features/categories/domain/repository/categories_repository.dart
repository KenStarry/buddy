import 'package:dartz/dartz.dart';

import '../model/category_model.dart';

abstract class CategoriesRepository {
  Future<Either<String, List<CategoryModel>>> getAll();
  Future<Either<String, CategoryModel?>> getById(String id);
  Future<Either<String, CategoryModel>> save(CategoryModel category);
  Future<Either<String, Unit>> saveAll(Iterable<CategoryModel> categories);
  Future<Either<String, Unit>> delete(String id);
  Future<Either<String, Unit>> deleteAll(Iterable<String> ids);
}
