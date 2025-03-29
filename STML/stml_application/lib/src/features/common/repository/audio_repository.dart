
import 'package:memoryminder/src/features/common/database/app_database.dart';
import 'package:memoryminder/src/features/common/model/media.dart';
import 'package:memoryminder/src/features/sensitive_information_detection/domain/audio.dart';

const String tableAudios = 'audios';
const String transcriptType = 'transcript';

class AudioFields extends MediaFields {
  static final List<String> values = [
    ...MediaFields.values,
    audioFileName,
    transcriptFileName,
    summary,
  ];

  static const String audioFileName = 'audio_file_name';
  static const String transcriptFileName = 'transcript_file_name';
  static const String summary = 'summary';
}

class AudioRepository {
  static final AudioRepository instance = AudioRepository._init();

  AudioRepository._init();

  Future<Audio> create(Audio audio) async {
    final db = await AppDatabase.instance.database;

    final id = await db.insert(tableAudios, audio.toJson());

    return audio.copy(id: id);
  }

  Future<int> delete(int id) async {
    final db = await AppDatabase.instance.database;

    return await db.delete(
      tableAudios,
      where: '${MediaFields.id} = ?',
      whereArgs: [id],
    );
  }

  Future<Audio> read(int id) async {
    final db = await AppDatabase.instance.database;

    final maps = await db.query(
      tableAudios,
      where: '${MediaFields.id} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Audio.fromJson(maps.first);
    } else {
      throw Exception('ID $id not found');
    }
  }

  Future<List<Audio>> readAll() async {
    final db = await AppDatabase.instance.database;

    const orderBy = '${MediaFields.id} ASC';
    final result = await db.query(tableAudios, orderBy: orderBy);

    return result.map((json) => Audio.fromJson(json)).toList();
  }

  Future<int> update(Audio audio) async {
    final db = await AppDatabase.instance.database;

    return db.update(
      tableAudios,
      audio.toJson(),
      where: '${MediaFields.id} = ?',
      whereArgs: [audio.id],
    );
  }
}
