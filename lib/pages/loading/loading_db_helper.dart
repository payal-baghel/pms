import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'package:flutter_application_1/pages/loading/models/wagon_master.dart';

class LoadingDbHelper {
  static final LoadingDbHelper instance = LoadingDbHelper._init();
  static Database? _database;

  LoadingDbHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pms_loading.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS WAGON_MASTER(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      code TEXT NOT NULL,
      wagon_type TEXT NOT NULL,
      codename TEXT NOT NULL,
      capacity TEXT NOT NULL
    )
    ''');
  }

  Future<void> saveWagonMasters(List<WagonMaster> items) async {
    final db = await instance.database;

    await db.transaction((txn) async {
      await txn.delete('WAGON_MASTER');
      final batch = txn.batch();
      for (final wagon in items) {
        batch.insert(
          'WAGON_MASTER',
          wagon.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<List<WagonMaster>> getWagonMasters() async {
    final db = await instance.database;
    final rows = await db.query('WAGON_MASTER');
    return rows
        .map((row) => WagonMaster.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }
}
