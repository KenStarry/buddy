import '../../../../core/data/hive_service.dart';
import '../../../../core/data/local_collection_repository.dart';
import '../../domain/model/account_model.dart';
import '../../domain/repository/accounts_repository.dart';

class AccountsRepositoryImpl extends LocalCollectionRepository<AccountModel>
    implements AccountsRepository {
  AccountsRepositoryImpl() : super(HiveService.accounts);

  @override
  String get label => 'wallets';
}
