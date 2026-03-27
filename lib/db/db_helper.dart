import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/expense.dart';

class DbHelper {
  static Database? _database;

  static final DbHelper instance = DbHelper._init();

  DbHelper._init();

  Future<Database> get database async {
    if(_database != null) return _database!;
    _database = await _initDB('expense.db');
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
      CREATE TABLE expenses(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT,
      amount REAL,
      type TEXT,
      category TEXT,
      date TEXT
      )
    ''');
  }

  Future<int> insertExpense(Expense expense) async {
    final db = await instance.database;
    return await db.insert('expenses', expense.toMap());
  }

  Future<List<Expense>> getExpenses() async {
    final db = await instance.database;
    final result = await db.query('expenses', orderBy: 'date DESC');

    return result.map((e) => Expense.fromMap(e)).toList();
  }
  Future<int> deleteExpense(int id) async{
    final db = await instance.database;
    print("Deleting ID: $id");
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }
  Future<void> clearAllData() async {
    final db = await instance.database;
    await db.delete('expenses');
  }
  Future<int> updateExpense(Expense expense) async {
    final db = await database;

    return await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }
}
