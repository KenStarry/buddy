import '../../../../core/data/local_collection_repository.dart';
import '../../../../core/data/ledger_seed.dart';
import '../../domain/model/transaction_model.dart';
import '../../domain/repository/transactions_repository.dart';

/// In-memory ledger, pre-filled with the demo month. For widget tests and
/// for driving the UI without touching Hive.
class TransactionsMemoryRepository
    extends MemoryCollectionRepository<TransactionModel>
    implements TransactionsRepository {
  TransactionsMemoryRepository({Iterable<TransactionModel>? seed})
    : super(seed: seed ?? LedgerSeed.transactions(), idOf: (t) => t.id);
}
