import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'database_helper.dart';
import 'dart:convert';
import 'services/order_service.dart';
import 'services/menu_service.dart';
import 'services/order_history_service.dart';

void main() async {
  await DatabaseHelper.initDatabase();  // Initialize SQLite

  final router = Router();
  
  // ✅ Add a default route for '/'
  router.get('/', (Request request) {
    return Response.ok('API is running');
  });

  // Example route for fetching menu items
  router.get('/menu', (Request request) {
    return Response.ok('{"message": "Menu items will be listed here"}', headers: {'Content-Type': 'application/json'});
  });

  // ✅ Root route to check if API is running
  router.get('/', (Request request) {
    return Response.ok('API is running');
  });

  // ✅ Route to add a menu item
  router.post('/menu', (Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);

      if (data['name'] == null) {
        return Response(400, body: jsonEncode({'error': 'Menu name is required'}));
      }
      // Insert into database
      final db = DatabaseHelper.getDatabase();
      db.execute('INSERT INTO menu (name) VALUES (?)', [data['name']]);

      return Response.ok(jsonEncode({'message': 'Menu item added successfully'}), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'error': 'Failed to add menu item'}));
    }
  });

  router.post('/order/process', OrderService.processOrder);
  router.post('/menu/validate', MenuService.validateOrder);
  router.post('/order/correct', OrderService.correctOrder);
  router.get('/order/history/<userId>', OrderHistoryService.getOrderHistory);

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addHandler(router);

  final server = await io.serve(handler, InternetAddress.anyIPv4, 8080);
  print('Server listening on http://${server.address.host}:${server.port}');
}
