import 'database_helper.dart';

class MenuService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

// validate a menu
  Future<bool> validateMenuItem(String itemName) async {
    final db = await _dbHelper.database;
    List<Map<String, dynamic>> result = await db.query(
      'menu',
      where: 'name = ?',
      whereArgs: [itemName],
    );
    return result.isNotEmpty;
  }

  // Add a new menu item
  Future<int> addMenuItem(Map<String, dynamic> menuItem) async {
    final db = await _dbHelper.database;
    return await db.insert('menu', menuItem);
  }

  // Get all menu items
  Future<List<Map<String, dynamic>>> getMenuItems() async {
    final db = await _dbHelper.database;
    return await db.query('menu');
  }

  // Get a menu item by ID
  Future<Map<String, dynamic>?> getMenuItemById(int id) async {
    final db = await _dbHelper.database;
    final result =
        await db.query('menu', where: 'id = ?', whereArgs: [id], limit: 1);
    return result.isNotEmpty ? result.first : null;
  }

  // Update a menu item
  Future<int> updateMenuItem(int id, Map<String, dynamic> updatedMenuItem) async {
    final db = await _dbHelper.database;
    return await db.update('menu', updatedMenuItem, where: 'id = ?', whereArgs: [id]);
  }

  // Delete a menu item
  Future<int> deleteMenuItem(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('menu', where: 'id = ?', whereArgs: [id]);
  }
}

