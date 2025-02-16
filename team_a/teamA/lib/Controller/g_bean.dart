class GCourse {
  String id;
  String fullName;

  GCourse({required this.id, required this.fullName});

  factory GCourse.fromJson(Map<String, dynamic> json) {
    return GCourse(
      id: json['id'] as String,
      fullName: json['name']
          as String, // Use 'name' to match the Google Classroom API
    );
  }
}

// beans.dart

class Course {
  String id;
  String name;
  String? section;
  String? descriptionHeading;
  String? description;
  String? room;
  String? ownerId;
  String? creationTime;
  String? updateTime;
  String? enrollmentCode;
  String? courseState; // Consider using an enum for CourseState
  String? alternateLink;
  String? teacherGroupEmail;
  String? courseGroupEmail;
  DriveFolder? teacherFolder;
  List<CourseMaterialSet>? courseMaterialSets;
  bool? guardiansEnabled;
  String? calendarId;
  GradebookSettings? gradebookSettings;

  Course({
    required this.id,
    required this.name,
    this.section,
    this.descriptionHeading,
    this.description,
    this.room,
    this.ownerId,
    this.creationTime,
    this.updateTime,
    this.enrollmentCode,
    this.courseState,
    this.alternateLink,
    this.teacherGroupEmail,
    this.courseGroupEmail,
    this.teacherFolder,
    this.courseMaterialSets,
    this.guardiansEnabled,
    this.calendarId,
    this.gradebookSettings,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as String,
      name: json['name'] as String,
      section: json['section'] as String?,
      descriptionHeading: json['descriptionHeading'] as String?,
      description: json['description'] as String?,
      room: json['room'] as String?,
      ownerId: json['ownerId'] as String?,
      creationTime: json['creationTime'] as String?,
      updateTime: json['updateTime'] as String?,
      enrollmentCode: json['enrollmentCode'] as String?,
      courseState: json['courseState'] as String?, // Consider using an enum
      alternateLink: json['alternateLink'] as String?,
      teacherGroupEmail: json['teacherGroupEmail'] as String?,
      courseGroupEmail: json['courseGroupEmail'] as String?,
      teacherFolder: json['teacherFolder'] == null
          ? null
          : DriveFolder.fromJson(json['teacherFolder'] as Map<String, dynamic>),
      courseMaterialSets: (json['courseMaterialSets'] as List<dynamic>?)
          ?.map((e) => CourseMaterialSet.fromJson(e as Map<String, dynamic>))
          .toList(),
      guardiansEnabled: json['guardiansEnabled'] as bool?,
      calendarId: json['calendarId'] as String?,
      gradebookSettings: json['gradebookSettings'] == null
          ? null
          : GradebookSettings.fromJson(
              json['gradebookSettings'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'section': section,
      'descriptionHeading': descriptionHeading,
      'description': description,
      'room': room,
      'ownerId': ownerId,
      'creationTime': creationTime,
      'updateTime': updateTime,
      'enrollmentCode': enrollmentCode,
      'courseState': courseState,
      'alternateLink': alternateLink,
      'teacherGroupEmail': teacherGroupEmail,
      'courseGroupEmail': courseGroupEmail,
      'teacherFolder': teacherFolder?.toJson(),
      'courseMaterialSets': courseMaterialSets?.map((e) => e.toJson()).toList(),
      'guardiansEnabled': guardiansEnabled,
      'calendarId': calendarId,
      'gradebookSettings': gradebookSettings?.toJson(),
    };
  }

  @override
  String toString() {
    return 'Course{id: $id, name: $name, section: $section}';
  }
}

class DriveFolder {
  String? id;
  String? title;
  String? alternateLink;

  DriveFolder({this.id, this.title, this.alternateLink});

  factory DriveFolder.fromJson(Map<String, dynamic> json) {
    return DriveFolder(
      id: json['id'] as String?,
      title: json['title'] as String?,
      alternateLink: json['alternateLink'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'alternateLink': alternateLink,
    };
  }
}

class CourseMaterialSet {
  String? title;

  CourseMaterialSet({this.title});

  factory CourseMaterialSet.fromJson(Map<String, dynamic> json) {
    return CourseMaterialSet(
      title: json['title'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
    };
  }
}

class GradebookSettings {
  // Define properties based on the GradebookSettings object
  // Example:
  String? categoryId;

  GradebookSettings({this.categoryId});

  factory GradebookSettings.fromJson(Map<String, dynamic> json) {
    return GradebookSettings(
      categoryId: json['categoryId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
    };
  }
}

// CourseWork Bean
class CourseWork {
  String? courseId;
  String? id;
  String? title;
  String? description;
  List<Material>? materials;
  String? state; // Consider enum for CourseWorkState
  String? alternateLink;
  String? creationTime;
  String? updateTime;
  Date? dueDate;
  TimeOfDay? dueTime;
  String? scheduledTime;
  double? maxPoints;
  String? workType; // Consider enum for CourseWorkType
  bool? associatedWithDeveloper;
  String? assigneeMode; // Consider enum for AssigneeMode
  IndividualStudentsOptions? individualStudentsOptions;
  String? submissionModificationMode; // Consider enum
  String? creatorUserId;
  String? topicId;
  GradeCategory? gradeCategory;
  String? gradingPeriodId;
  Assignment? assignment;
  MultipleChoiceQuestion? multipleChoiceQuestion;
  String? previewVersion;

  CourseWork(
      {this.courseId,
      this.id,
      this.title,
      this.description,
      this.materials,
      this.state,
      this.alternateLink,
      this.creationTime,
      this.updateTime,
      this.dueDate,
      this.dueTime,
      this.scheduledTime,
      this.maxPoints,
      this.workType,
      this.associatedWithDeveloper,
      this.assigneeMode,
      this.individualStudentsOptions,
      this.submissionModificationMode,
      this.creatorUserId,
      this.topicId,
      this.gradeCategory,
      this.gradingPeriodId,
      this.assignment,
      this.multipleChoiceQuestion,
      this.previewVersion});

  factory CourseWork.fromJson(Map<String, dynamic> json) {
    return CourseWork(
      courseId: json['courseId'] as String?,
      id: json['id'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      materials: (json['materials'] as List<dynamic>?)
          ?.map((e) => Material.fromJson(e as Map<String, dynamic>))
          .toList(),
      state: json['state'] as String?,
      alternateLink: json['alternateLink'] as String?,
      creationTime: json['creationTime'] as String?,
      updateTime: json['updateTime'] as String?,
      dueDate: json['dueDate'] == null
          ? null
          : Date.fromJson(json['dueDate'] as Map<String, dynamic>),
      dueTime: json['dueTime'] == null
          ? null
          : TimeOfDay.fromJson(json['dueTime'] as Map<String, dynamic>),
      scheduledTime: json['scheduledTime'] as String?,
      maxPoints: (json['maxPoints'] as num?)?.toDouble(),
      workType: json['workType'] as String?,
      associatedWithDeveloper: json['associatedWithDeveloper'] as bool?,
      assigneeMode: json['assigneeMode'] as String?,
      individualStudentsOptions: json['individualStudentsOptions'] == null
          ? null
          : IndividualStudentsOptions.fromJson(
              json['individualStudentsOptions'] as Map<String, dynamic>),
      submissionModificationMode: json['submissionModificationMode'] as String?,
      creatorUserId: json['creatorUserId'] as String?,
      topicId: json['topicId'] as String?,
      gradeCategory: json['gradeCategory'] == null
          ? null
          : GradeCategory.fromJson(
              json['gradeCategory'] as Map<String, dynamic>),
      gradingPeriodId: json['gradingPeriodId'] as String?,
      assignment: json['assignment'] == null
          ? null
          : Assignment.fromJson(json['assignment'] as Map<String, dynamic>),
      multipleChoiceQuestion: json['multipleChoiceQuestion'] == null
          ? null
          : MultipleChoiceQuestion.fromJson(
              json['multipleChoiceQuestion'] as Map<String, dynamic>),
      previewVersion: json['previewVersion'] as String?,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'id': id,
      'title': title,
      'description': description,
      'materials': materials?.map((e) => e.toJson()).toList(),
      'state': state,
      'alternateLink': alternateLink,
      'creationTime': creationTime,
      'updateTime': updateTime,
      'dueDate': dueDate?.toJson(),
      'dueTime': dueTime?.toJson(),
      'scheduledTime': scheduledTime,
      'maxPoints': maxPoints,
      'workType': workType,
      'associatedWithDeveloper': associatedWithDeveloper,
      'assigneeMode': assigneeMode,
      'individualStudentsOptions': individualStudentsOptions?.toJson(),
      'submissionModificationMode': submissionModificationMode,
      'creatorUserId': creatorUserId,
      'topicId': topicId,
      'gradeCategory': gradeCategory?.toJson(),
      'gradingPeriodId': gradingPeriodId,
      'assignment': assignment?.toJson(),
      'multipleChoiceQuestion': multipleChoiceQuestion?.toJson(),
      'previewVersion': previewVersion,
    };
  }

  @override
  String toString() {
    return 'CourseWork{id: $id, title: $title, description: $description}';
  }
}

// Material Bean
class Material {
  String? title;
  String? alternateLink;

  Material({this.title, this.alternateLink});

  factory Material.fromJson(Map<String, dynamic> json) {
    return Material(
      title: json['title'] as String?,
      alternateLink: json['alternateLink'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'alternateLink': alternateLink,
    };
  }

  @override
  String toString() {
    return 'Material{title: $title, alternateLink: $alternateLink}';
  }
}

// Date Bean
class Date {
  int? year;
  int? month;
  int? day;

  Date({this.year, this.month, this.day});

  factory Date.fromJson(Map<String, dynamic> json) {
    return Date(
      year: json['year'] as int?,
      month: json['month'] as int?,
      day: json['day'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'month': month,
      'day': day,
    };
  }

  @override
  String toString() {
    return 'Date{year: $year, month: $month, day: $day}';
  }
}

// TimeOfDay Bean
class TimeOfDay {
  int? hours;
  int? minutes;
  int? seconds;
  int? nanos;

  TimeOfDay({this.hours, this.minutes, this.seconds, this.nanos});

  factory TimeOfDay.fromJson(Map<String, dynamic> json) {
    return TimeOfDay(
      hours: json['hours'] as int?,
      minutes: json['minutes'] as int?,
      seconds: json['seconds'] as int?,
      nanos: json['nanos'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hours': hours,
      'minutes': minutes,
      'seconds': seconds,
      'nanos': nanos,
    };
  }

  @override
  String toString() {
    return 'TimeOfDay{hours: $hours, minutes: $minutes}';
  }
}

// IndividualStudentsOptions Bean
class IndividualStudentsOptions {
  // Add properties as needed based on the API definition

  IndividualStudentsOptions();

  factory IndividualStudentsOptions.fromJson(Map<String, dynamic> json) {
    return IndividualStudentsOptions();
  }

  Map<String, dynamic> toJson() {
    return {};
  }
}

// GradeCategory Bean
class GradeCategory {
  String? name;
  double? defaultPoints;

  GradeCategory({this.name, this.defaultPoints});

  factory GradeCategory.fromJson(Map<String, dynamic> json) {
    return GradeCategory(
      name: json['name'] as String?,
      defaultPoints: (json['defaultPoints'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'defaultPoints': defaultPoints,
    };
  }

  @override
  String toString() {
    return 'GradeCategory{name: $name, defaultPoints: $defaultPoints}';
  }
}

// Assignment Bean
class Assignment {
  // Add properties as needed based on the API definition
  // Example:
  String? instructions;

  Assignment({this.instructions});

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      instructions: json['instructions'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'instructions': instructions,
    };
  }
}

// MultipleChoiceQuestion Bean
class MultipleChoiceQuestion {
  // Add properties as needed based on the API definition
  List<String>? choices;

  MultipleChoiceQuestion({this.choices});

  factory MultipleChoiceQuestion.fromJson(Map<String, dynamic> json) {
    return MultipleChoiceQuestion(
      choices:
          (json['choices'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'choices': choices,
    };
  }
}

// UserProfile Bean (Used in Student and Teacher)
class UserProfile {
  String? id;
  Name? name;
  String? emailAddress;
  String? photoUrl;

  UserProfile({this.id, this.name, this.emailAddress, this.photoUrl});

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String?,
      name: json['name'] == null
          ? null
          : Name.fromJson(json['name'] as Map<String, dynamic>),
      emailAddress: json['emailAddress'] as String?,
      photoUrl: json['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name?.toJson(),
      'emailAddress': emailAddress,
      'photoUrl': photoUrl,
    };
  }
}

// Name Bean (Used within UserProfile)
class Name {
  String? familyName;
  String? givenName;
  String? fullName;

  Name({this.familyName, this.givenName, this.fullName});

  factory Name.fromJson(Map<String, dynamic> json) {
    return Name(
      familyName: json['familyName'] as String?,
      givenName: json['givenName'] as String?,
      fullName: json['fullName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'familyName': familyName,
      'givenName': givenName,
      'fullName': fullName,
    };
  }
}

// Student Bean
class Student {
  String courseId;
  String userId;
  UserProfile? profile;
  DriveFolder? studentWorkFolder;

  Student(
      {required this.courseId,
      required this.userId,
      this.profile,
      this.studentWorkFolder});

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      courseId: json['courseId'] as String,
      userId: json['userId'] as String,
      profile: json['profile'] == null
          ? null
          : UserProfile.fromJson(json['profile'] as Map<String, dynamic>),
      studentWorkFolder: json['studentWorkFolder'] == null
          ? null
          : DriveFolder.fromJson(
              json['studentWorkFolder'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'userId': userId,
      'profile': profile?.toJson(),
      'studentWorkFolder': studentWorkFolder?.toJson(),
    };
  }
}

// Teacher Bean
class Teacher {
  String courseId;
  String userId;
  UserProfile? profile;

  Teacher({required this.courseId, required this.userId, this.profile});

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      courseId: json['courseId'] as String,
      userId: json['userId'] as String,
      profile: json['profile'] == null
          ? null
          : UserProfile.fromJson(json['profile'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'userId': userId,
      'profile': profile?.toJson(),
    };
  }
}

//courses.topics Bean
class Topic {
  String courseId;
  String topicId;
  String name;
  String updateTime;

  Topic(
      {required this.courseId,
      required this.topicId,
      required this.name,
      required this.updateTime});

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      courseId: json['courseId'] as String,
      topicId: json['topicId'] as String,
      name: json['name'] as String,
      updateTime: json['updateTime'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'topicId': topicId,
      'name': name,
      'updateTime': updateTime,
    };
  }
}

//courses.courseWork.rubrics Bean
class Rubric {
  String courseId;
  String courseWorkId;
  String id;
  String creationTime;
  String updateTime;
  List<Criterion>? criteria;
  String? sourceSpreadsheetId; //Union field

  Rubric(
      {required this.courseId,
      required this.courseWorkId,
      required this.id,
      required this.creationTime,
      required this.updateTime,
      this.criteria,
      this.sourceSpreadsheetId});

  factory Rubric.fromJson(Map<String, dynamic> json) {
    return Rubric(
      courseId: json['courseId'] as String,
      courseWorkId: json['courseWorkId'] as String,
      id: json['id'] as String,
      creationTime: json['creationTime'] as String,
      updateTime: json['updateTime'] as String,
      criteria: (json['criteria'] as List<dynamic>?)
          ?.map((e) => Criterion.fromJson(e as Map<String, dynamic>))
          .toList(),
      sourceSpreadsheetId: json['sourceSpreadsheetId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'courseWorkId': courseWorkId,
      'id': id,
      'creationTime': creationTime,
      'updateTime': updateTime,
      'criteria': criteria?.map((e) => e.toJson()).toList(),
      'sourceSpreadsheetId': sourceSpreadsheetId,
    };
  }
}

// Criterion Bean (Used in Rubric)
class Criterion {
  String? criterionId;
  String? description;
  List<Level>? levels;

  Criterion({this.criterionId, this.description, this.levels});

  factory Criterion.fromJson(Map<String, dynamic> json) {
    return Criterion(
      criterionId: json['criterionId'] as String?,
      description: json['description'] as String?,
      levels: (json['levels'] as List<dynamic>?)
          ?.map((e) => Level.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'criterionId': criterionId,
      'description': description,
      'levels': levels?.map((e) => e.toJson()).toList(),
    };
  }
}

// Level Bean (Used in Criterion)
class Level {
  String? levelId;
  String? description;
  String? title;
  double? points;

  Level({this.levelId, this.description, this.title, this.points});

  factory Level.fromJson(Map<String, dynamic> json) {
    return Level(
      levelId: json['levelId'] as String?,
      description: json['description'] as String?,
      title: json['title'] as String?,
      points: (json['points'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'levelId': levelId,
      'description': description,
      'title': title,
      'points': points,
    };
  }
}

//Enum for CourseState
enum CourseState {
  COURSE_STATE_UNSPECIFIED,
  ACTIVE,
  ARCHIVED,
  PROVISIONED,
  DECLINED
}

//Enum for CourseWorkState
enum CourseWorkState {
  COURSE_WORK_STATE_UNSPECIFIED,
  PUBLISHED,
  DRAFT,
  DELETED
}

//Enum for CourseWorkType
enum CourseWorkType {
  COURSE_WORK_TYPE_UNSPECIFIED,
  ASSIGNMENT,
  SHORT_ANSWER_QUESTION,
  MULTIPLE_CHOICE_QUESTION
}

//Enum for AssigneeMode
enum AssigneeMode {
  ASSIGNEE_MODE_UNSPECIFIED,
  ALL_STUDENTS,
  INDIVIDUAL_STUDENTS
}

//Enum for SubmissionModificationMode
enum SubmissionModificationMode {
  SUBMISSION_MODIFICATION_MODE_UNSPECIFIED,
  MODIFIABLE_UNTIL_TURNED_IN,
  MODIFIABLE_AFTER_TURNED_IN
}

//Enum for PreviewVersion
enum PreviewVersion { PREVIEW_VERSION_UNSPECIFIED, PUBLISHED_VERSION }
