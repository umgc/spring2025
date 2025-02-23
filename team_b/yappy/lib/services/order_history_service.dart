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

// class OrderService {
//   final DatabaseHelper _dbHelper = DatabaseHelper.instance;

//   /// Processes raw speech input into structured order data
//   Future<Map<String, dynamic>> processSpeechOrder(String rawSpeech) async {
//     // Example: "I want two burgers and a coke"
//     List<String> words = rawSpeech.toLowerCase().split(" ");
//     Map<String, int> orderItems = {};

//     // Get menu items from the database
//     final db = await _dbHelper.database;
//     List<Map<String, dynamic>> menuItems = await db.query("menu");

//     // Extract ordered items from speech
//     for (var item in menuItems) {
//       String itemName = item['name'].toString().toLowerCase();
//       for (int i = 0; i < words.length; i++) {
//         if (words[i] == itemName) {
//           // Check if a quantity is mentioned before the item
//           int quantity = 1;
//           if (i > 0 && int.tryParse(words[i - 1]) != null) {
//             quantity = int.parse(words[i - 1]);
//           }
//           orderItems[itemName] = (orderItems[itemName] ?? 0) + quantity;
//         }
//       }
//     }

//     return {
//       "order": orderItems,
//       "rawSpeech": rawSpeech,
//     };
//   }

//   /// Allows manual modification of the order before saving
//   Future<void> modifyOrder(Map<String, int> updatedOrder) async {
//     // This function would be used for manual correction before saving
//     print("Modified Order: $updatedOrder");
//   }

//   /// Saves the processed order into the database
//   Future<void> saveOrder(Map<String, int> orderItems, String rawSpeech) async {
//     final db = await _dbHelper.database;
//     String orderDetails = orderItems.entries.map((e) => "${e.key} x${e.value}").join(", ");

//     await db.insert("orders", {
//       "details": orderDetails,
//       "raw_speech": rawSpeech,
//       "timestamp": DateTime.now().toIso8601String(),
//     });
//   }
// }