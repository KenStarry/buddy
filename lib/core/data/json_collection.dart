import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// A Hive box of `id → JSON string`, typed.
///
/// ## Why JSON strings and not Hive adapters
///
/// Generated `TypeAdapter`s are faster and smaller, and they bind the box's
/// bytes to the exact field order of a generated class. Adding a field in the
/// middle, reordering, or changing a type then requires a migration — and
/// getting one wrong corrupts the box rather than failing a parse. Budgy's
/// models are hand-written with defensive `fromMap`s that already tolerate
/// missing and unknown keys, so storing JSON makes a schema change a non-event
/// and keeps the stored form inspectable (and exportable) by construction.
/// The ledger is thousands of rows, not millions; the decode cost is noise.
///
/// Every read is **fail-soft per row**: one unparseable row is skipped and
/// logged, never thrown. A single bad row must not blank the whole ledger.
class JsonCollection<T> {
  JsonCollection({
    required this.boxName,
    required this.fromMap,
    required this.toMap,
    required this.idOf,
  });

  final String boxName;
  final T Function(Map<String, dynamic> map) fromMap;
  final Map<String, dynamic> Function(T item) toMap;
  final String Function(T item) idOf;

  Box<String> get _box => Hive.box<String>(boxName);

  /// How many rows failed to parse on the last [all] call. Surfaced in
  /// Settings so a corrupted box is visible rather than silently lossy.
  int get unreadableCount => _unreadable;
  int _unreadable = 0;

  List<T> all() {
    var unreadable = 0;
    final items = <T>[];
    for (final key in _box.keys) {
      final raw = _box.get(key);
      if (raw == null) continue;
      try {
        items.add(fromMap(Map<String, dynamic>.from(jsonDecode(raw) as Map)));
      } catch (error) {
        unreadable++;
        // ⚠️ The row is **left on disk**. Deleting it here would turn a
        // transient decode failure — or a row written by a newer build — into
        // permanent data loss with no undo and no notice.
        debugPrint(
          'JsonCollection[$boxName]: skipping unreadable row "$key" ($error). '
          'The stored bytes are left untouched.',
        );
      }
    }
    _unreadable = unreadable;
    return items;
  }

  T? get(String id) {
    final raw = _box.get(id);
    if (raw == null) return null;
    try {
      return fromMap(Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (error) {
      debugPrint('JsonCollection[$boxName]: unreadable row "$id" ($error).');
      return null;
    }
  }

  Future<void> put(T item) =>
      _box.put(idOf(item), jsonEncode(toMap(item)));

  Future<void> putAll(Iterable<T> items) => _box.putAll({
    for (final item in items) idOf(item): jsonEncode(toMap(item)),
  });

  Future<void> delete(String id) => _box.delete(id);

  Future<void> deleteAll(Iterable<String> ids) => _box.deleteAll(ids);

  Future<void> clear() => _box.clear();

  /// Replaces the box contents with [items]: upsert everything present, then
  /// evict anything that is no longer. The safe shape for a full refresh —
  /// `clear()` followed by `putAll()` leaves the box empty for a frame, and
  /// anything that reads it in between sees an empty ledger.
  Future<void> replaceAll(Iterable<T> items) async {
    final keep = {for (final item in items) idOf(item)};
    await putAll(items);
    final stale = _box.keys
        .map((k) => k.toString())
        .where((k) => !keep.contains(k))
        .toList();
    if (stale.isNotEmpty) await _box.deleteAll(stale);
  }

  bool get isEmpty => _box.isEmpty;
  int get length => _box.length;
}
