import 'package:memoryminder/src/features/common/database/app_database.dart';
import 'package:memoryminder/src/features/common/model/photo.dart';
import 'package:memoryminder/src/features/common/model/media.dart';

const String tablePhotos = 'photos';

class PhotoFields extends MediaFields {
  static final List<String> values = [
    ...MediaFields.values,
    photoFileName,
  ];

  static const String photoFileName = 'photo_file_name';
}

class PhotoRepository {
  static final PhotoRepository instance = PhotoRepository._init();

  PhotoRepository._init();

  Future<Photo> create(Photo photo) async {
    final db = await AppDatabase.instance.database;

    final id = await db.insert(tablePhotos, photo.toJson());

    return photo.copy(id: id);
  }

  Future<int> delete(int id) async {
    final db = await AppDatabase.instance.database;

    return await db.delete(
      tablePhotos,
      where: '${MediaFields.id} = ?',
      whereArgs: [id],
    );
  }

  Future<Photo> read(int id) async {
    final db = await AppDatabase.instance.database;

    final maps = await db.query(
      tablePhotos,
      where: '${MediaFields.id} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Photo.fromJson(maps.first);
    } else {
      throw Exception('ID $id not found');
    }
  }

  Future<List<Photo>> readAll() async {
    final db = await AppDatabase.instance.database;

    const orderBy = '${MediaFields.id} ASC';
    final result = await db.query(tablePhotos, orderBy: orderBy);

    return result.map((json) => Photo.fromJson(json)).toList();
  }

  Future<int> update(Photo photo) async {
    final db = await AppDatabase.instance.database;

    return db.update(
      tablePhotos,
      photo.toJson(),
      where: '${MediaFields.id} = ?',
      whereArgs: [photo.id],
    );
  }
}
