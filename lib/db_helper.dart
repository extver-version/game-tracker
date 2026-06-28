import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbHelper {
  static final DbHelper _instance = DbHelper._internal();
  factory DbHelper() => _instance;
  static Database? _db;

  DbHelper._internal();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'auth_user.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
      )
    ''');
  }

  Future<bool> register(String username, String password) async {
    final db = await database;
    try {
      await db.insert(
        'users', 
        {'username': username, 'password': password}, 
        conflictAlgorithm: ConflictAlgorithm.replace
      );
      return true;
    } catch (_) {
      return false; //
    }
  }

  Future<bool> checkLogin(String username, String password) async {
    final db = await database;
    var res = await db.query(
      'users', 
      where: 'username = ? AND password = ?', 
      whereArgs: [username, password]
    );
    return res.isNotEmpty;
  }
}