import '../../../../core/data/local_collection_repository.dart';
import '../../../../core/data/ledger_seed.dart';
import '../../domain/model/account_model.dart';
import '../../domain/repository/accounts_repository.dart';

class AccountsMemoryRepository
    extends MemoryCollectionRepository<AccountModel>
    implements AccountsRepository {
  AccountsMemoryRepository({Iterable<AccountModel>? seed})
    : super(seed: seed ?? LedgerSeed.accounts(), idOf: (a) => a.id);
}
