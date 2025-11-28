import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:arunika/models/user.dart';
import 'package:arunika/services/encryption_service.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    String path = join(await getDatabasesPath(), 'perfume_app.db');
    return await openDatabase(
      path,
      version: 3, // UPDATE VERSION
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        email TEXT UNIQUE,
        password TEXT,
        photo TEXT
      )
    ''');

    await _createCartTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createCartTable(db);
    }

    if (oldVersion < 3) {
      await db.execute("ALTER TABLE users ADD COLUMN photo TEXT");
    }
  }

  Future<void> _createCartTable(Database db) async {
    await db.execute('''
      CREATE TABLE cart(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        productId INTEGER,
        quantity INTEGER,
        FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE,
        UNIQUE(userId, productId) 
      )
    ''');
  }

  // --- USER FUNCTIONS ---
  Future<int> registerUser(User user) async {
    final db = await database;
    try {
      String hashedPassword = EncryptionService.hashPassword(user.password);
      User u = User(
        name: user.name,
        email: user.email,
        password: hashedPassword,
      );
      return await db.insert('users', u.toMap(), conflictAlgorithm: ConflictAlgorithm.abort);
    } catch (e) {
      return -1;
    }
  }

  Future<User?> loginUser(String email, String password) async {
    final db = await database;
    String hashedPassword = EncryptionService.hashPassword(password);

    List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, hashedPassword],
    );

    if (maps.isNotEmpty) return User.fromMap(maps.first);
    return null;
  }

  Future<User?> getUserById(int id) async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) return User.fromMap(maps.first);
    return null;
  }

  // 🔵 UPDATE FOTO
  Future<int> updateUserPhoto(int id, String photoPath) async {
    final db = await database;
    return await db.update(
      'users',
      {'photo': photoPath},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 🔵 UPDATE NAMA + EMAIL + PASSWORD OPSIONAL
  Future<int> updateUserProfile(int id, String name, String email, String? newPassword) async {
    final db = await database;

    Map<String, dynamic> updates = {
      'name': name,
      'email': email,
    };

    if (newPassword != null && newPassword.isNotEmpty) {
      updates['password'] = EncryptionService.hashPassword(newPassword);
    }

    return await db.update(
      'users',
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- CART OMITTED (tidak diubah)
  Future<void> upsertCartItem(int userId, int productId) async {
    final db = await database;
    final List<Map<String, dynamic>> existing = await db.query(
      'cart',
      where: 'userId = ? AND productId = ?',
      whereArgs: [userId, productId],
    );

    if (existing.isNotEmpty) {
      int newQuantity = existing.first['quantity'] + 1;
      await db.update(
        'cart',
        {'quantity': newQuantity},
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    } else {
      await db.insert('cart', {
        'userId': userId,
        'productId': productId,
        'quantity': 1,
      });
    }
  }

  Future<int> updateCartItemQuantity(int userId, int productId, int quantity) async {
    final db = await database;
    return await db.update(
      'cart',
      {'quantity': quantity},
      where: 'userId = ? AND productId = ?',
      whereArgs: [userId, productId],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeCartItem(int userId, int productId) async {
    final db = await database;
    await db.delete(
      'cart',
      where: 'userId = ? AND productId = ?',
      whereArgs: [userId, productId],
    );
  }

  Future<List<Map<String, dynamic>>> getCart(int userId) async {
    final db = await database;
    return await db.query(
      'cart',
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  Future<void> clearCart(int userId) async {
    final db = await database;
    await db.delete(
      'cart',
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }
}
