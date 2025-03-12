import 'database_helper.dart';

class RestaurantAPI {
  final DatabaseHelper dbHelper = DatabaseHelper();

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  //Steps 1,2,3,4 needs to be done then in step 4 we will get extractedItems List - which contains exact orders - e.g[pizza,coke,chips]  then that extractedItems 
  //needs to be passed to step 5 

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  /// STEP 5: VALIDATE AGAINST THE RESTAURANT MENU
  ///
  /// We get a list of items from the LLM (e.g. ["Margherita Pizza", "Coke"]).
  /// We compare each item with what’s in the MenuItem table.
  /// Only items that match are returned in `validItems`.
  Future<List<String>> validateMenuItems(List<String> extractedItems) async {
    // 1) Fetch the menu from the database (MenuItem table).
    final db = await dbHelper.database;
    final menuRows =
        await db.query('MenuItem'); // Must contain 'item_name' column

    // Convert each item_name to lowercase for easy comparison
    List<String> menuNames = menuRows
        .map((row) => (row['item_name'] as String).toLowerCase())
        .toList();

    // 2) Check which extracted items exist in the menu
    List<String> validItems = [];
    for (var item in extractedItems) {
      if (menuNames.contains(item.toLowerCase())) {
        validItems.add(item);
      }
    }

    return validItems;
  }

  /// STEP 6: STORE THE VALIDATED ORDER IN THE DATABASE
  ///
  /// Once we have a list of valid items, we store them in RestaurantOrder
  /// with a "Pending" status. For simplicity, we join them into a single string
  /// (e.g. "Margherita Pizza, Coke, Garlic Bread").
  Future<void> storeValidatedOrder(List<String> validItems) async {
    if (validItems.isEmpty) {
      print(" No valid items to store in database.Please chech whether MenuItem table and RestaurantOrder table has column or not.If not then create it");
      return;
    }

    String orderText = validItems.join(", ");
    print("Storing order: $orderText"); 

    final db = await dbHelper.database;
    await db.insert('RestaurantOrder', {
      'order_text': orderText,
      'order_status': 'Pending',
    });

    print("Order successfully stored in database.");
  }

  /// STEP 7: UI FETCHES & DISPLAYS ORDER SUMMARY
  ///
  /// We provide a method to retrieve the latest orders from RestaurantOrder
  /// so the UI can display them.
  Future<List<Map<String, dynamic>>> getOrderHistory() async {
    final db = await dbHelper.database;
    return await db.query('RestaurantOrder', orderBy: 'order_id DESC');
  }

  // -------------------------------------------------------------------
  // Optional convenience method that does Steps 5 & 6 in one shot:
  // Given a list of extracted items, validate them, then store them.
  // The UI can then call getOrderHistory to show it.
  // -------------------------------------------------------------------
  Future<void> processValidatedItems(List<String> extractedItems) async {
    // Step 5
    List<String> validItems = await validateMenuItems(extractedItems);

    // Step 6
    await storeValidatedOrder(validItems);
  }
}
