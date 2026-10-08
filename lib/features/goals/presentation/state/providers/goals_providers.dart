import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/repository/goals_repository_impl.dart';
import '../../../domain/repository/goals_repository.dart';

part 'goals_providers.g.dart';

@Riverpod(keepAlive: true)
GoalsRepository goalsRepository(Ref ref) => GoalsRepositoryImpl();
