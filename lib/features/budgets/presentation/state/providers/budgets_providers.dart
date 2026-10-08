import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/repository/budgets_repository_impl.dart';
import '../../../domain/repository/budgets_repository.dart';

part 'budgets_providers.g.dart';

@Riverpod(keepAlive: true)
BudgetsRepository budgetsRepository(Ref ref) => BudgetsRepositoryImpl();
