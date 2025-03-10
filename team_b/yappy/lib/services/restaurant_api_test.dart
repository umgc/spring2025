import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'database_helper.dart';
import 'restaurant_api_module.dart';

void main() {
  late RestaurantAPI restaurantAPI;
  late DatabaseHelper dbHelper;
 TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    // Initialize FFI SQLite for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    dbHelper = DatabaseHelper();
    restaurantAPI = RestaurantAPI();

    // Open an in-memory database for testing
    final db = await dbHelper.database;
    
    // Create test tables
    await db.execute('''
      CREATE TABLE MenuItem (
        item_id INTEGER PRIMARY KEY,
        item_name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE RestaurantOrder (
        order_id INTEGER PRIMARY KEY,
        order_text TEXT NOT NULL,
        order_status TEXT NOT NULL
      )
    ''');

    // Insert test menu items
    await db.insert('MenuItem', {'item_name': 'Pizza'});
    await db.insert('MenuItem', {'item_name': 'Coke'});
  });

  tearDown(() async {
    final db = await dbHelper.database;
    await db.close();
  });

  test('validateMenuItems should return only valid menu items', () async {
    List<String> extractedItems = ["Pizza", "Coke", "Burger"];
    
    List<String> validItems = await restaurantAPI.validateMenuItems(extractedItems);

    expect(validItems, ["Pizza", "Coke"]);
  });

  test('storeValidatedOrder should insert a valid order', () async {
    List<String> validItems = ["Pizza", "Coke"];

    await restaurantAPI.storeValidatedOrder(validItems);

    final db = await dbHelper.database;
    final result = await db.query('RestaurantOrder');

    expect(result.length, 1);
    expect(result.first['order_text'], 'Pizza, Coke');
    expect(result.first['order_status'], 'Pending');
  });
}