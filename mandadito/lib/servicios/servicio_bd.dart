import 'package:mandadito/modelos/articulo.dart';
import 'package:mandadito/modelos/compra.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';


class DatabaseService {
  DatabaseService._internal();
  static final DatabaseService instance = DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'pantry_app.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE pantry_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            barcode TEXT,
            name TEXT NOT NULL,
            brand TEXT,
            imageUrl TEXT,
            quantity INTEGER NOT NULL,
            contentSize TEXT,
            purchaseDate TEXT NOT NULL,
            expirationDate TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'activo',
            totalUnits INTEGER,
            remainingUnits INTEGER,
            lowStockNotified INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE shopping_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            quantity INTEGER NOT NULL,
            dateAdded TEXT NOT NULL,
            plannedDate TEXT,
            checked INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE pantry_items ADD COLUMN totalUnits INTEGER');
          await db.execute('ALTER TABLE pantry_items ADD COLUMN remainingUnits INTEGER');
          await db.execute(
            'ALTER TABLE pantry_items ADD COLUMN lowStockNotified INTEGER NOT NULL DEFAULT 0',
          );
        }
      },
    );
  }


  //ARTICULOS DE LA ALACENA

  Future<int> insertPantryItem(Articulo item) async {
    final db = await database;
    return db.insert('pantry_items', item.toMap()..remove('id'));
  }

  Future<List<Articulo>> getPantryItems({String? status}) async {
    final db = await database;
    final maps = await db.query(
      'pantry_items',
      where: status != null ? 'status = ?' : null,
      whereArgs: status != null ? [status] : null,
      orderBy: 'expirationDate ASC',
    );
    return maps.map((m) => Articulo.fromMap(m)).toList();
  }

  Future<Articulo?> getPantryItemByBarcode(String barcode) async {
    final db = await database;
    final maps = await db.query(
      'pantry_items',
      where: 'barcode = ? AND status = ?',
      whereArgs: [barcode, 'activo'],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Articulo.fromMap(maps.first);
  }

  Future<int> updatePantryItem(Articulo item) async {
    final db = await database;
    return db.update(
      'pantry_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  //Descuenta una pieza y no deja bajar de 0
  Future<void> decrementUnit(Articulo item) async {
    if (item.remainingUnits == null) return;
    final newValue = (item.remainingUnits! - 1).clamp(0, item.totalUnits ?? 0);
    await updatePantryItem(item.copyWith(remainingUnits: newValue));
  }

  //Elimina el alimento porque se terminó o se echó a perder
  Future<int> deletePantryItem(int id) async {
    final db = await database;
    return db.delete('pantry_items', where: 'id = ?', whereArgs: [id]);
  }


  //LISTA DE COMPRA

  Future<int> insertShoppingItem(Compra item) async {
    final db = await database;
    return db.insert('shopping_items', item.toMap()..remove('id'));
  }

  Future<List<Compra>> getShoppingItems() async {
    final db = await database;
    final maps = await db.query('shopping_items', orderBy: 'checked ASC, dateAdded ASC');
    return maps.map((m) => Compra.fromMap(m)).toList();
  }

  Future<int> updateShoppingItem(Compra item) async {
    final db = await database;
    return db.update(
      'shopping_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteShoppingItem(int id) async {
    final db = await database;
    return db.delete('shopping_items', where: 'id = ?', whereArgs: [id]);
  }
}