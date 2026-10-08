import '../../../../core/data/hive_service.dart';
import '../../../../core/data/local_collection_repository.dart';
import '../../domain/model/category_model.dart';
import '../../domain/repository/categories_repository.dart';

class CategoriesRepositoryImpl
    extends LocalCollectionRepository<CategoryModel>
    implements CategoriesRepository {
  CategoriesRepositoryImpl() : super(HiveService.categories);

  @override
  String get label => 'categories';
}
