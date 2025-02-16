import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../database_helper.dart';

class MenuService {
  static Future<Response> validateOrder(Request request) async {
    final payload = jsonDecode(await request.readAsString());
    List<String> orderItems = List<String>.from(payload['orderItems']);

    final db = DatabaseHelper.getDatabase();
    final result = db.select('SELECT name FROM menu');
    List<String> menuItems = result.map((row) => row['name'] as String).toList();

    List<String> validItems = orderItems.where((item) => menuItems.contains(item)).toList();
    List<String> invalidItems = orderItems.where((item) => !menuItems.contains(item)).toList();

    return Response.ok(jsonEncode({"valid_items": validItems, "invalid_items": invalidItems}),
        headers: {'Content-Type': 'application/json'});
  }
}

