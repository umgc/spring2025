import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../database_helper.dart';

class OrderService {
  static Future<Response> processOrder(Request request) async {
    final payload = jsonDecode(await request.readAsString());
    final String speechText = payload['speech'];

    List<String> extractedItems = extractMenuItems(speechText);

    return Response.ok(jsonEncode({"order": extractedItems}),
        headers: {'Content-Type': 'application/json'});
  }

  static List<String> extractMenuItems(String speechText) {
    final db = DatabaseHelper.getDatabase();
    final result = db.select('SELECT name FROM menu');
    List<String> menuItems = result.map((row) => row['name'] as String).toList();

    return menuItems.where((item) => speechText.toLowerCase().contains(item)).toList();
  }

  static Future<Response> correctOrder(Request request) async {
    final payload = jsonDecode(await request.readAsString());
    String orderId = payload['orderId'];
    List<String> correctedItems = List<String>.from(payload['correctedItems']);

    final db = DatabaseHelper.getDatabase();
    db.execute(
        'UPDATE orders SET items = ? WHERE id = ?',
        [correctedItems.join(','), orderId]
    );

    return Response.ok(jsonEncode({"message": "Order corrected", "new_order": correctedItems}),
        headers: {'Content-Type': 'application/json'});
  }
}
