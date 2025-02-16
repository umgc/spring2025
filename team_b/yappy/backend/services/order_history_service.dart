import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../database_helper.dart';

class OrderHistoryService {
  static Future<Response> getOrderHistory(Request request, String userId) async {
    final db = DatabaseHelper.getDatabase();
    final result = db.select('SELECT * FROM orders WHERE user_id = ?', [userId]);

    List<Map<String, dynamic>> orders = result.map((row) => {
      "id": row['id'],
      "user_id": row['user_id'],
      "items": row['items'].toString().split(','),
      "timestamp": row['timestamp']
    }).toList();

    return Response.ok(jsonEncode({"orders": orders}),
        headers: {'Content-Type': 'application/json'});
  }

  static Future<void> saveOrder(String userId, List<String> items) async {
    final db = DatabaseHelper.getDatabase();
    db.execute(
        'INSERT INTO orders (user_id, items, timestamp) VALUES (?, ?, ?)',
        [userId, items.join(','), DateTime.now().toIso8601String()]
    );
  }
}
