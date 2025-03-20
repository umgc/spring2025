import 'package:memoryminder/src/database/app_seed_data.dart';
import 'package:memoryminder/src/database/model/media.dart';
import 'package:memoryminder/src/features/sensitive_information_detection/data/audio_repository.dart';
import 'package:memoryminder/src/database/repository/photo_repository.dart';
import 'package:memoryminder/src/database/repository/significant_object_repository.dart';
import 'package:memoryminder/src/database/repository/video_repository.dart';
import 'package:memoryminder/src/database/repository/video_response_repository.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static const tableLocations = 'locations';
  static final AppDatabase instance = AppDatabase._init();

  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const boolType = 'BOOLEAN NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const textNullableType = 'TEXT';
    const floatType = 'FLOAT';

    final mediaColumns = [
      '${MediaFields.id} $idType',
      '${MediaFields.title} $textNullableType',
      '${MediaFields.description} $textNullableType',
      '${MediaFields.tags} $textNullableType',
      '${MediaFields.timestamp} $integerType',
      '${MediaFields.physicalAddress} $textNullableType',
      '${MediaFields.storageSize} $integerType',
      '${MediaFields.isFavorited} $boolType',
    ];

    await db.execute('''
      CREATE TABLE $tableAudios (
        ${mediaColumns.join(',\n')},
        ${AudioFields.audioFileName} $textType,
        ${AudioFields.transcriptFileName} $textNullableType,
        ${AudioFields.summary} $textNullableType,
        ${AudioFields.s3Url} $textNullableType
      )
    ''');

    await db.execute('''
      CREATE TABLE $tablePhotos (
        ${mediaColumns.join(',\n')},
        ${PhotoFields.photoFileName} $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableLocations (
        id $idType,
        latitude $floatType,
        longitude $floatType,
        address $textNullableType,
        timestamp $integerType
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableVideos (
        ${mediaColumns.join(',\n')},
        ${VideoFields.videoFileName} $textType,
        ${VideoFields.thumbnailFileName} $textNullableType,
        ${VideoFields.duration} $textType
      )
    ''');

    await db.execute('''
    CREATE TABLE $tableVideoResponses (
      ${VideoResponseFields.id} $idType,
      ${VideoResponseFields.title} $textType,
      ${VideoResponseFields.timestamp} $integerType,
      ${VideoResponseFields.referenceVideoFilePath} $textType,
      ${VideoResponseFields.confidence} $floatType,
      ${VideoResponseFields.left} $floatType,
      ${VideoResponseFields.top} $floatType,
      ${VideoResponseFields.width} $floatType,
      ${VideoResponseFields.height} $floatType,
      ${VideoResponseFields.address} $textNullableType,
      ${VideoResponseFields.parents} $textNullableType
    )
  ''');

    await db.execute('''
    CREATE TABLE $tableSignificantObjects (
      ${SignificantObjectFields.id} $idType,
      ${SignificantObjectFields.objectLabel} $textNullableType,
      ${SignificantObjectFields.customLabel} $textNullableType,
      ${SignificantObjectFields.timestamp} $integerType,
      ${SignificantObjectFields.imageFileName} $textType,
      ${SignificantObjectFields.left} $floatType,
      ${SignificantObjectFields.top} $floatType,
      ${SignificantObjectFields.width} $floatType,
      ${SignificantObjectFields.height} $floatType
    )
  ''');

    final appSeedData = AppSeedData();
    appSeedData.loadAppSeedData();
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
