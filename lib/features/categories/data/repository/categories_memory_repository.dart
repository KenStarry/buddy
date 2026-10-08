import '../../../../core/data/local_collection_repository.dart';
import '../../../../core/data/ledger_seed.dart';
import '../../domain/model/category_model.dart';
import '../../domain/repository/categories_repository.dart';

class CategoriesMemoryRepository
    extends MemoryCollectionRepository<CategoryModel>
    implements CategoriesRepository {
  CategoriesMemoryRepository({Iterable<CategoryModel>? seed})
    : super(seed: seed ?? LedgerSeed.categories(), idOf: (c) => c.id);
}
