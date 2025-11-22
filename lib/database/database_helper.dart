import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/sms_message.dart';

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
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'messenger_ai.db');

    return await openDatabase(path, version: 1, onCreate: _createDb);
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        address TEXT NOT NULL,
        body TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        category TEXT NOT NULL,
        isImportant INTEGER NOT NULL DEFAULT 0,
        isSpam INTEGER NOT NULL DEFAULT 0,
        isRead INTEGER NOT NULL DEFAULT 0,
        metadata TEXT
      )
    ''');

    // Create indexes for better query performance
    await db.execute('CREATE INDEX idx_timestamp ON messages(timestamp DESC)');
    await db.execute('CREATE INDEX idx_category ON messages(category)');
    await db.execute('CREATE INDEX idx_address ON messages(address)');
  }

  // Insert a message
  Future<int> insertMessage(SmsMessage message) async {
    final db = await database;
    return await db.insert(
      'messages',
      message.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all messages
  Future<List<SmsMessage>> getAllMessages() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      orderBy: 'timestamp DESC',
    );
    return maps.map((map) => SmsMessage.fromMap(map)).toList();
  }

  // Get messages by category
  Future<List<SmsMessage>> getMessagesByCategory(SmsCategory category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'category = ?',
      whereArgs: [category.name],
      orderBy: 'timestamp DESC',
    );
    return maps.map((map) => SmsMessage.fromMap(map)).toList();
  }

  // Get important messages
  Future<List<SmsMessage>> getImportantMessages() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'isImportant = ?',
      whereArgs: [1],
      orderBy: 'timestamp DESC',
    );
    return maps.map((map) => SmsMessage.fromMap(map)).toList();
  }

  // Get spam messages
  Future<List<SmsMessage>> getSpamMessages() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'isSpam = ?',
      whereArgs: [1],
      orderBy: 'timestamp DESC',
    );
    return maps.map((map) => SmsMessage.fromMap(map)).toList();
  }

  // Update message
  Future<int> updateMessage(SmsMessage message) async {
    final db = await database;
    return await db.update(
      'messages',
      message.toMap(),
      where: 'id = ?',
      whereArgs: [message.id],
    );
  }

  // Delete message
  Future<int> deleteMessage(String id) async {
    final db = await database;
    return await db.delete('messages', where: 'id = ?', whereArgs: [id]);
  }

  // Get message count by category
  Future<Map<SmsCategory, int>> getMessageCountByCategory() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT category, COUNT(*) as count FROM messages GROUP BY category',
    );

    Map<SmsCategory, int> counts = {};
    for (var row in result) {
      final category = SmsCategory.values.firstWhere(
        (e) => e.name == row['category'],
        orElse: () => SmsCategory.other,
      );
      counts[category] = row['count'] as int;
    }
    return counts;
  }

  // Search messages
  Future<List<SmsMessage>> searchMessages(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'body LIKE ? OR address LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'timestamp DESC',
    );
    return maps.map((map) => SmsMessage.fromMap(map)).toList();
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
