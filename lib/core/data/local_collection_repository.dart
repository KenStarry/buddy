import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import 'json_collection.dart';

/// CRUD against a [JsonCollection], wrapped in `Either<String, T>`.
///
/// The five ledger aggregates have byte-identical persistence needs, so the
/// mechanics live here once and each feature's `*RepositoryImpl` is a
/// four-line binding of its own contract to its own box. The *contracts* stay
/// per-aggregate (`TransactionsRepository`, `BudgetsRepository`, …) because
/// that is what presentation depends on, and what a future server-backed
/// implementation would have to satisfy.
abstract class LocalCollectionRepository<T> {
  LocalCollectionRepository(this.collection);

  @protected
  final JsonCollection<T> collection;

  /// What to call this data in an error message the user will actually read.
  /// "We couldn't open your transactions" beats "DB error 7".
  @protected
  String get label;

  Future<Either<String, List<T>>> getAll() async {
    try {
      return Right(collection.all());
    } catch (error) {
      debugPrint('LocalCollectionRepository<$T>.getAll failed: $error');
      return Left("We couldn't open your $label. Try again in a moment.");
    }
  }

  Future<Either<String, T?>> getById(String id) async {
    try {
      return Right(collection.get(id));
    } catch (error) {
      debugPrint('LocalCollectionRepository<$T>.getById failed: $error');
      return Left("We couldn't open that $label entry.");
    }
  }

  Future<Either<String, T>> save(T item) async {
    try {
      await collection.put(item);
      return Right(item);
    } catch (error) {
      debugPrint('LocalCollectionRepository<$T>.save failed: $error');
      return Left("That didn't save. Give it another go?");
    }
  }

  Future<Either<String, Unit>> saveAll(Iterable<T> items) async {
    try {
      await collection.putAll(items);
      return const Right(unit);
    } catch (error) {
      debugPrint('LocalCollectionRepository<$T>.saveAll failed: $error');
      return Left("We couldn't save those $label changes.");
    }
  }

  Future<Either<String, Unit>> delete(String id) async {
    try {
      await collection.delete(id);
      return const Right(unit);
    } catch (error) {
      debugPrint('LocalCollectionRepository<$T>.delete failed: $error');
      return const Left("That didn't delete. Give it another go?");
    }
  }

  Future<Either<String, Unit>> deleteAll(Iterable<String> ids) async {
    try {
      await collection.deleteAll(ids);
      return const Right(unit);
    } catch (error) {
      debugPrint('LocalCollectionRepository<$T>.deleteAll failed: $error');
      return const Left("Those didn't delete. Give it another go?");
    }
  }
}

/// In-memory variant, for widget tests and for UI work before a box exists.
///
/// Kept deliberately honest about async: every method awaits a zero-duration
/// future so a consumer that forgets to `await` fails in tests the same way it
/// would fail against the real store.
abstract class MemoryCollectionRepository<T> {
  MemoryCollectionRepository({
    Iterable<T> seed = const [],
    required String Function(T) idOf,
  }) : _idOf = idOf {
    for (final item in seed) {
      _items[idOf(item)] = item;
    }
  }

  final Map<String, T> _items = {};
  final String Function(T) _idOf;

  Future<Either<String, List<T>>> getAll() async =>
      Right(_items.values.toList());

  Future<Either<String, T?>> getById(String id) async => Right(_items[id]);

  Future<Either<String, T>> save(T item) async {
    _items[_idOf(item)] = item;
    return Right(item);
  }

  Future<Either<String, Unit>> saveAll(Iterable<T> items) async {
    for (final item in items) {
      _items[_idOf(item)] = item;
    }
    return const Right(unit);
  }

  Future<Either<String, Unit>> delete(String id) async {
    _items.remove(id);
    return const Right(unit);
  }

  Future<Either<String, Unit>> deleteAll(Iterable<String> ids) async {
    for (final id in ids) {
      _items.remove(id);
    }
    return const Right(unit);
  }
}
