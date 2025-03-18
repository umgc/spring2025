import 'package:memoryminder/src/database/app_database.dart';
import 'package:memoryminder/src/database/model/video_response.dart';

const String tableVideoResponses = 'video_responses';

class VideoResponseFields {
  static final List<String> values = [
    id,
    title,
    timestamp,
    confidence,
    left,
    top,
    width,
    height,
    referenceVideoFilePath,
    address,
    parents,
  ];

  static const String id = 'id';
  static const String title = 'title';
  static const String timestamp = 'timestamp';
  static const String confidence = 'confidence';
  static const String left = 'left';
  static const String top = 'top';
  static const String width = 'width';
  static const String height = 'height';
  static const String referenceVideoFilePath = 'referenceVideoFilePath';
  static const String address = 'address';
  static const String parents = 'parents';
}

class VideoResponseRepository {
  static final VideoResponseRepository instance =
      VideoResponseRepository._init();

  VideoResponseRepository._init();

  Future<VideoResponse> create(VideoResponse response) async {
    final db = await AppDatabase.instance.database;

    final id = await db.insert(tableVideoResponses, response.toJson());

    return response.copy(id: id);
  }

  Future<int> delete(int id) async {
    final db = await AppDatabase.instance.database;

    return await db.delete(
      tableVideoResponses,
      where: '${VideoResponseFields.id} = ?',
      whereArgs: [id],
    );
  }

  Future<VideoResponse> read(int id) async {
    final db = await AppDatabase.instance.database;

    final maps = await db.query(
      tableVideoResponses,
      where: '${VideoResponseFields.id} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return VideoResponse.fromJson(maps.first);
    } else {
      throw Exception('ID $id not found');
    }
  }

  Future<List<VideoResponse>> readAll() async {
    final db = await AppDatabase.instance.database;

    const orderBy = '${VideoResponseFields.id} ASC';
    final result = await db.query(tableVideoResponses, orderBy: orderBy);

    return result.map((json) => VideoResponse.fromJson(json)).toList();
  }

  Future<int> update(VideoResponse response) async {
    final db = await AppDatabase.instance.database;

    return db.update(
      tableVideoResponses,
      response.toJson(),
      where: '${VideoResponseFields.id} = ?',
      whereArgs: [response.id],
    );
  }
}
