import '../../../../core/data/hive_service.dart';
import '../../../../core/data/local_collection_repository.dart';
import '../../domain/model/transaction_model.dart';
import '../../domain/repository/transactions_repository.dart';

class TransactionsRepositoryImpl
    extends LocalCollectionRepository<TransactionModel>
    implements TransactionsRepository {
  TransactionsRepositoryImpl() : super(HiveService.transactions);

  @override
  String get label => 'transactions';
}
