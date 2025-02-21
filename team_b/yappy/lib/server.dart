import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import 'services/order_service.dart';
import 'services/menu_service.dart';
import 'services/order_history_service.dart';

void main() async {
  final router = Router();
  final OrderService orderService = OrderService();
  final OrderHistoryService orderHistoryService = OrderHistoryService();
  final MenuService menuService = MenuService();

  // 🟢 Route: Process Speech Order
  router.post('/order', (Request request) async {
    try {
      final payload = jsonDecode(await request.readAsString());
      String rawSpeech = payload['speech'];

      if (rawSpeech.isEmpty) {
        return Response(400, body: jsonEncode({'error': 'Speech input is required'}));
      }

      // Process the order
      Map<String, dynamic> structuredOrder = await orderService.processSpeechOrder(rawSpeech);
      return Response.ok(jsonEncode(structuredOrder), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'error': e.toString()}));
    }
  });

  // 🟢 Route: Fetch Order History
  router.get('/orders/history', (Request request) async {
    try {
      List<Map<String, dynamic>> history = await orderHistoryService.getOrderHistory();
      return Response.ok(jsonEncode(history), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'error': e.toString()}));
    }
  });

  // 🟢 Route: Validate Menu Item
  router.get('/menu/validate/<item>', (Request request, String item) async {
    try {
      bool isValid = await menuService.validateMenuItem(item);
      return Response.ok(jsonEncode({'item': item, 'valid': isValid}), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'error': e.toString()}));
    }
  });

  // 🌍 Start Server
  final handler = Pipeline().addMiddleware(logRequests()).addHandler(router);
  final server = await io.serve(handler, 'localhost', 8080);
  print('✅ Server running on http://${server.address.host}:${server.port}');
}
