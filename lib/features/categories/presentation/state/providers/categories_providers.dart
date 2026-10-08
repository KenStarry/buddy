import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/repository/categories_repository_impl.dart';
import '../../../domain/repository/categories_repository.dart';

part 'categories_providers.g.dart';

@Riverpod(keepAlive: true)
CategoriesRepository categoriesRepository(Ref ref) =>
    CategoriesRepositoryImpl();
