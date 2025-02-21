import 'database_helper.dart';

class OrderHistoryService {
  final dbHelper = DatabaseHelper.instance;

  Future<List<Map<String, dynamic>>> getOrderHistory() async {
    final db = await dbHelper.database;
    return await db.query('orders', orderBy: 'timestamp DESC');
  }

  Future<List<Map<String, dynamic>>> getOrdersByDate(String date) async {
    final db = await dbHelper.database;
    return await db.query('orders', where: 'date = ?', whereArgs: [date]);
  }

}

