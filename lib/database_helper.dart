import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('parcel_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE users(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL UNIQUE,
      password TEXT NOT NULL,
      station_code TEXT NOT NULL
    )
    ''');

    await db.execute('''
    CREATE TABLE transactions(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL,
      station_code TEXT NOT NULL,
      type TEXT NOT NULL,
      timestamp TEXT NOT NULL
    )
    ''');

    await db.insert('users', {
      'username': 'CRISPMS',
      'password': 'cris123',
      'station_code': 'NDLS',
    });

    await db.insert('users', {
      'username': 'Ashish',
      'password': 'cris678',
      'station_code': 'DELB',
    });
  }

  Future<int> insertUser(
    String username,
    String password,
    String station,
  ) async {
    final db = await instance.database;

    return await db.insert('users', {
      'username': username,
      'password': password,
      'station_code': station,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateUser(
    String username,
    String password,
    String station,
  ) async {
    final db = await instance.database;

    return await db.update(
      'users',
      {'password': password, 'station_code': station},
      where: 'username = ?',
      whereArgs: [username],
    );
  }

  Future<int> deleteUser(String username) async {
    final db = await instance.database;

    return await db.delete(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await instance.database;
    return await db.query('users');
  }

  Future<bool> checkLogin(
    String username,
    String password,
    String station,
  ) async {
    final db = await instance.database;

    var result = await db.query(
      'users',
      where: 'username = ? AND password = ? AND station_code = ?',
      whereArgs: [username, password, station],
    );

    return result.isNotEmpty;
  }
}
