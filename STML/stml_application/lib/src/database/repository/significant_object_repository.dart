import 'package:memoryminder/src/database/app_database.dart';
import 'package:memoryminder/src/database/model/significant_object.dart';

const String tableSignificantObjects = 'significant_objects';

class SignificantObjectFields {
  static final List<String> values = [
    id,
    objectLabel,
    customLabel,
    timestamp,
    imageFileName,
    left,
    top,
    width,
    height,
  ];

  static const String id = '_id';
  static const String objectLabel = 'object_label';
  static const String customLabel = 'custom_label';
  static const String timestamp = 'timestamp';
  static const String imageFileName = 'image_file_name';
  static const String left = 'left';
  static const String top = 'top';
  static const String width = 'width';
  static const String height = 'height';
}

class SignificantObjectRepository {
  static final SignificantObjectRepository instance =
      SignificantObjectRepository._init();

  SignificantObjectRepository._init();

  Future<SignificantObject> create(SignificantObject object) async {
    final db = await AppDatabase.instance.database;

    final id = await db.insert(tableSignificantObjects, object.toJson());

    return object.copy(id: id);
  }

  Future<int> delete(int id) async {
    final db = await AppDatabase.instance.database;

    return await db.delete(
      tableSignificantObjects,
      where: '${SignificantObjectFields.id} = ?',
      whereArgs: [id],
    );
  }

  Future<SignificantObject> read(int id) async {
    final db = await AppDatabase.instance.database;

    final maps = await db.query(
      tableSignificantObjects,
      where: '${SignificantObjectFields.id} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return SignificantObject.fromJson(maps.first);
    } else {
      throw Exception('ID $id not found');
    }
  }

  Future<List<SignificantObject>> readAll() async {
    final db = await AppDatabase.instance.database;

    const orderBy = '${SignificantObjectFields.id} ASC';
    final result = await db.query(tableSignificantObjects, orderBy: orderBy);

    return result.map((json) => SignificantObject.fromJson(json)).toList();
  }

  Future<int> update(SignificantObject object) async {
    final db = await AppDatabase.instance.database;

    return db.update(
      tableSignificantObjects,
      object.toJson(),
      where: '${SignificantObjectFields.id} = ?',
      whereArgs: [object.id],
    );
  }
}
