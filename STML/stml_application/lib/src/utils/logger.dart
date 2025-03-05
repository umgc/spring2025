import 'package:logging/logging.dart';

final Logger appLogger = Logger('AppLogger');

void initializeLogging() {
  Logger.root.level = Level.ALL;

  Logger.root.onRecord.listen((record) {
    if (record.error != null) {
      print('${record.level.name}: ${record.time}: ${record.message}: ${record.error}: ${record.stackTrace}');
    } else {
      print('${record.level.name}: ${record.time}: ${record.message}');
    }
  });
}