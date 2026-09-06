import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import 'package:nexora_flutter/core/database/database_service.dart';

/// Stands in for the platform DatabaseException (abstract in public API).
/// Production code catches all exceptions, so the behavior under test is
/// identical: the old code propagated this out of onConfigure and failed
/// openDatabase; the new code must swallow it.
Exception _darwinError() => Exception('DatabaseException(not an error)');

/// Mimics sqflite_darwin (iOS/macOS): a row-returning PRAGMA run via
/// execute() throws DatabaseException Code=0 "not an error", because the
/// native layer expects SQLITE_DONE but gets a result row.
class _DarwinLikeDb implements Database {
  final executed = <String>[];
  final queried = <String>[];

  @override
  dynamic noSuchMethod(Invocation inv) {
    if (inv.memberName == #execute) {
      final sql = inv.positionalArguments.first as String;
      executed.add(sql);
      if (sql.contains('journal_mode')) {
        throw _darwinError();
      }
      return Future.value();
    }
    if (inv.memberName == #rawQuery) {
      final sql = inv.positionalArguments.first as String;
      queried.add(sql);
      return Future.value([
        {'journal_mode': 'wal'},
      ]);
    }
    return super.noSuchMethod(inv);
  }
}

/// Worst case: every PRAGMA throws (locked-down platform build).
class _HostileDb implements Database {
  @override
  dynamic noSuchMethod(Invocation inv) {
    if (inv.memberName == #execute || inv.memberName == #rawQuery) {
      throw _darwinError();
    }
    return super.noSuchMethod(inv);
  }
}

void main() {
  test(
    'configureDb survives darwin journal_mode quirk (download regression)',
    () async {
      // Regression: PRAGMA journal_mode = WAL via execute() throws on
      // iOS/macOS, which used to fail openDatabase entirely and break
      // every download with:
      //   DatabaseException(... SqliteDarwinDatabase Code=0 "not an error")
      //   sql 'PRAGMA journal_mode = WAL'
      final db = _DarwinLikeDb();
      await DatabaseService.configureDb(db);
      expect(db.executed, contains('PRAGMA foreign_keys = ON'));
      expect(db.queried, anyElement(contains('journal_mode')));
    },
  );

  test('configureDb degrades gracefully when all PRAGMAs fail', () async {
    // Must never throw: platform defaults are always acceptable.
    await DatabaseService.configureDb(_HostileDb());
  });
}
