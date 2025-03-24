import 'package:learninglens_app/Api/lms/enum/lms_enum.dart';
import 'package:learninglens_app/Api/lms/lms_interface.dart';
import 'package:learninglens_app/Api/lms/moodle/moodle_lms_service.dart';
import 'package:learninglens_app/Api/lms/google_classroom/google_lms_service.dart';
import 'package:learninglens_app/services/local_storage_service.dart';

class LmsFactory {

  static MoodleLmsService _lmsServiceMoodle = MoodleLmsService();
  static GoogleLmsService _lmsServiceGoogle = GoogleLmsService();

  static LmsInterface getLmsService() {
    LmsType lmsType = LocalStorageService.getSelectedClassroom();

    switch (lmsType) {
      // TODO: Do we need this or can we just return Moodle as a default with the default: case?
      // case LmsType.MOODLE:
      //   return getLmsServiceMoodle();
      case LmsType.GOOGLE:
        return getLmsServiceGoogle();
      default:
        // print('LMS type not found, defaulting to Moodle');
        return getLmsServiceMoodle();
    }
  }

  static MoodleLmsService getLmsServiceMoodle() {
    return _lmsServiceMoodle;
  }

  static GoogleLmsService getLmsServiceGoogle() {
    return _lmsServiceGoogle;
  }
}