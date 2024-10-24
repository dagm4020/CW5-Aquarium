import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'fish_settings.db');
    return await openDatabase(
      path,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE fish_settings(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, speed TEXT, color TEXT, kind TEXT)',
        );
      },
      version: 1,
    );
  }

  Future<void> insertFishSetting(
      String name, String speed, String color, String kind) async {
    final db = await database;
    await db.insert(
      'fish_settings',
      {'name': name, 'speed': speed, 'color': color, 'kind': kind},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getFishSettings() async {
    final db = await database;
    return await db.query('fish_settings');
  }

  Future<void> resetDatabase() async {
    final db = await database;
    await db.execute('DROP TABLE IF EXISTS fish_settings');
    await db.execute(
      'CREATE TABLE fish_settings(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, speed TEXT, color TEXT, kind TEXT)',
    );
  }

  Future<void> updateFishSetting(
      String name, String speed, String? color, String? kind) async {
    final db = await database;

    await db.update(
      'fish_settings',
      {
        'speed': speed,
        'color': color,
        'kind': kind,
      },
      where: 'name = ?',
      whereArgs: [name],
    );
  }
}
