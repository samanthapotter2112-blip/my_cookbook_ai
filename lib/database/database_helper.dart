import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('cookbook.db');

    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();

    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cookbooks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE recipes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cookbookId INTEGER,
        name TEXT NOT NULL,
        ingredients TEXT,
        instructions TEXT
      )
    ''');
  }

  Future<int> insertCookbook(String name) async {
    final db = await instance.database;

    return await db.insert(
      'cookbooks',
      {
        'name': name,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getCookbooks() async {
    final db = await instance.database;

    return await db.query('cookbooks');
  }

  Future<int> insertRecipe({
    required int cookbookId,
    required String name,
    String ingredients = '',
    String instructions = '',
  }) async {
    final db = await instance.database;

    return await db.insert(
      'recipes',
      {
        'cookbookId': cookbookId,
        'name': name,
        'ingredients': ingredients,
        'instructions': instructions,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getRecipes(
      int cookbookId) async {
    final db = await instance.database;

    return await db.query(
      'recipes',
      where: 'cookbookId = ?',
      whereArgs: [cookbookId],
    );
  }
}