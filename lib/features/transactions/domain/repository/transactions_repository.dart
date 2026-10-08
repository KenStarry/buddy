import 'package:dartz/dartz.dart';

import '../model/transaction_model.dart';

/// The ledger's contract. `Left` carries a message already written for a
/// human; `Right` carries data.
abstract class TransactionsRepository {
  Future<Either<String, List<TransactionModel>>> getAll();
  Future<Either<String, TransactionModel?>> getById(String id);
  Future<Either<String, TransactionModel>> save(TransactionModel transaction);
  Future<Either<String, Unit>> saveAll(Iterable<TransactionModel> transactions);
  Future<Either<String, Unit>> delete(String id);
  Future<Either<String, Unit>> deleteAll(Iterable<String> ids);
}
