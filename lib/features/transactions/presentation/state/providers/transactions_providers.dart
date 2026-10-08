import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/repository/transactions_repository_impl.dart';
import '../../../domain/repository/transactions_repository.dart';

part 'transactions_providers.g.dart';

/// Swap point between the Hive store and the in-memory one.
/// `return TransactionsMemoryRepository();` drives the whole UI off the demo
/// ledger without touching disk.
@Riverpod(keepAlive: true)
TransactionsRepository transactionsRepository(Ref ref) =>
    TransactionsRepositoryImpl();
