import 'package:memoryminder/src/features/common/database/app_database.dart';
import 'package:memoryminder/src/features/common/model/media.dart';
import 'package:memoryminder/src/features/common/model/video.dart';

const String tableVideos = 'videos';

class VideoFields extends MediaFields {
  static final List<String> values = [
    ...MediaFields.values,
    videoFileName,
    thumbnailFileName,
    duration,
  ];

  static const String videoFileName = 'video_file_name';
  static const String thumbnailFileName = 'thumbnail_file_name';
  static const String duration = 'duration';
}

class VideoRepository {
  static final VideoRepository instance = VideoRepository._init();

  VideoRepository._init();

  Future<Video> create(Video video) async {
    final db = await AppDatabase.instance.database;

    final id = await db.insert(tableVideos, video.toJson());

    return video.copy(id: id);
  }

  Future<int> delete(int id) async {
    final db = await AppDatabase.instance.database;

    return await db.delete(
      tableVideos,
      where: '${MediaFields.id} = ?',
      whereArgs: [id],
    );
  }

  Future<Video> read(int id) async {
    final db = await AppDatabase.instance.database;

    final maps = await db.query(
      tableVideos,
      where: '${MediaFields.id} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Video.fromJson(maps.first);
    } else {
      throw Exception('ID $id not found');
    }
  }

  Future<List<Video>> readAll() async {
    final db = await AppDatabase.instance.database;

    const orderBy = '${MediaFields.id} ASC';
    final result = await db.query(tableVideos, orderBy: orderBy);

    return result.map((json) => Video.fromJson(json)).toList();
  }

  Future<int> update(Video video) async {
    final db = await AppDatabase.instance.database;

    return db.update(
      tableVideos,
      video.toJson(),
      where: '${MediaFields.id} = ?',
      whereArgs: [video.id],
    );
  }
}
