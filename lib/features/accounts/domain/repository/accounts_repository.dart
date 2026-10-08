import 'package:dartz/dartz.dart';

import '../model/account_model.dart';

abstract class AccountsRepository {
  Future<Either<String, List<AccountModel>>> getAll();
  Future<Either<String, AccountModel?>> getById(String id);
  Future<Either<String, AccountModel>> save(AccountModel account);
  Future<Either<String, Unit>> saveAll(Iterable<AccountModel> accounts);
  Future<Either<String, Unit>> delete(String id);
  Future<Either<String, Unit>> deleteAll(Iterable<String> ids);
}
