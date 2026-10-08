import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

class SaveDatabase extends GeneratedDatabase {
  SaveDatabase()
    : super(
        driftDatabase(
          name: 'nurturio',
          web: DriftWebOptions(
            sqlite3Wasm: Uri.parse('sqlite3.wasm'),
            driftWorker: Uri.parse('drift_worker.dart.js'),
          ),
        ),
      );
  SaveDatabase.forTesting(super.executor);
  @override
  int get schemaVersion => 1;
  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await customStatement(
        'CREATE TABLE saves (id TEXT PRIMARY KEY, payload TEXT NOT NULL, revision INTEGER NOT NULL DEFAULT 0)',
      );
      await customStatement(
        'CREATE TABLE outbox (id TEXT PRIMARY KEY, payload TEXT NOT NULL, attempts INTEGER NOT NULL DEFAULT 0)',
      );
    },
  );
  Future<Map<String, dynamic>?> load() async {
    final rows = await customSelect(
      "SELECT payload FROM saves WHERE id = 'local'",
    ).get();
    return rows.isEmpty
        ? null
        : jsonDecode(rows.first.read<String>('payload'))
              as Map<String, dynamic>;
  }

  Future<void> save(Map<String, dynamic> data, {String? operationId}) =>
      transaction(() async {
        final payload = jsonEncode(data);
        await customStatement(
          "INSERT INTO saves (id,payload) VALUES ('local',?) ON CONFLICT(id) DO UPDATE SET payload=excluded.payload,revision=revision+1",
          [payload],
        );
        if (operationId != null) {
          await customStatement(
            'INSERT OR IGNORE INTO outbox (id,payload) VALUES (?,?)',
            [operationId, payload],
          );
        }
      });
  Future<List<Map<String, dynamic>>> pending() async =>
      (await customSelect(
            'SELECT id,payload,attempts FROM outbox ORDER BY rowid LIMIT 50',
          ).get())
          .map(
            (r) => {
              'id': r.read<String>('id'),
              'payload': jsonDecode(r.read<String>('payload')),
              'attempts': r.read<int>('attempts'),
            },
          )
          .toList();
  Future<void> acknowledge(String id) =>
      customStatement('DELETE FROM outbox WHERE id=?', [id]);
  Future<void> clear() => transaction(() async {
    await customStatement('DELETE FROM saves');
    await customStatement('DELETE FROM outbox');
  });
}
