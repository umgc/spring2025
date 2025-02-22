import 'package:learninglens_app/Api/lms/enum/lms_enum.dart';
import 'package:learninglens_app/Api/lms/lms_interface.dart';
import 'package:learninglens_app/Api/lms/moodle/moodle_lms_service.dart';

class LmsFactory {
  static LmsInterface getLmsService() {
    // TODO: use local storage to determine which LMS to use (Moodle, Google Classroom, etc.)
    LmsType lmsType = LmsType.MOODLE;

    switch (lmsType) {
      case LmsType.MOODLE:
        return MoodleLmsService();
      case LmsType.GOOGLE:
        // return GoogleClassroomLmsService();
        throw Exception('Make GoogleClassroomLmsService impelement the LmsInterface');
      default:
        print('LMS type not found, defaulting to Moodle');
        return MoodleLmsService();
    }
  }
}