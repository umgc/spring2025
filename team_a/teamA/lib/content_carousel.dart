import 'package:flutter/material.dart';
import 'package:learninglens_app/Api/lms/enum/lms_enum.dart';
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';

import 'package:learninglens_app/Views/essay_generation.dart';
import 'package:learninglens_app/Views/g_assignment_create.dart';
import 'package:learninglens_app/Views/g_quiz_question_page.dart';

import 'package:learninglens_app/Views/m_assessment_view.dart';
import 'package:learninglens_app/Views/quiz_generator.dart';
import 'package:learninglens_app/Views/essays_view.dart';
import 'package:learninglens_app/beans/quiz.dart';
import 'package:learninglens_app/beans/assignment.dart';
import 'package:learninglens_app/beans/course.dart';
import 'package:learninglens_app/services/local_storage_service.dart';

//Provides a carousel of either assessments, essays, or submission
class ContentCarousel extends StatefulWidget {
  final String type;
  final List? children;
  final int? courseId;

  ContentCarousel(this.type, this.children, {this.courseId});

  @override
  State<ContentCarousel> createState() {
    return _ContentState(type, children, courseId ?? 0);
  }
}

//State of the carousel (allows for filtering in the future)
class _ContentState extends State<ContentCarousel> {
  final String type;
  //original list of content
  final List<Widget> _children;
  //filtered list to be shown
  var children = <Widget>[];
  final int courseId;
  _ContentState._(this.type, this._children, this.courseId) {
    children = _children;
  }

  factory _ContentState(String type, List? input, int? courseId) {
    {
      //generate the full list of cards
      if (type == "assessment") {
        return _ContentState._(
            type,
            CarouselCard.fromQuizzes(input) ??
                [
                  Text(
                      'There are no generated quizzes that match the requirements.',
                      style: TextStyle(fontSize: 32))
                ],
            courseId ?? 0);
      } else if (type == 'essay') {
        return _ContentState._(
            type,
            CarouselCard.fromEssays(input) ??
                [
                  Text(
                      'This are no generated essays that match the requirements.',
                      style: TextStyle(fontSize: 32))
                ],
            courseId ?? 0);
      }
      //todo: add submission type
      else {
        return _ContentState._(
            type, [Text('Invalid type input.')], courseId ?? 0);
      }
    }
  }
  //todo filtering features

  bool isMoodle() {
    print(LocalStorageService.getSelectedClassroom());
    return LocalStorageService.getSelectedClassroom() == LmsType.MOODLE;
  }

  @override
  Widget build(BuildContext context) {
    //For empty contents, we don't build a carousel
    if (_children.length == 1 && _children[0].runtimeType == Text) {
      return Padding(
          padding: EdgeInsets.all(20),
          child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 400),
              child: Center(child: _children[0])));
    } else {
      // return Padding(
      //     padding: EdgeInsets.symmetric(vertical: 10),
      //     child: ConstrainedBox(
      //         constraints: BoxConstraints(maxHeight: 250), //testing width
      //         child: CarouselView(
      //           backgroundColor: Theme.of(context).primaryColor,
      //           itemExtent: 400,
      //           shrinkExtent: 250,
      //           onTap: (value) {
      //             if (type == 'assessment') {

      //               Navigator.push(
      //                 context,
      //                 MaterialPageRoute(
      //                     builder: (context) => AssessmentsView(
      //                         quizID: (children[value] as CarouselCard).id,
      //                         courseID:
      //                             (children[value] as CarouselCard).courseId)),
      //               );
      //             } else if (type == 'essay') {
      //               print(
      //                   (children[value] as CarouselCard).courseId?.toString());
      //               Navigator.push(
      //                   context,
      //                   MaterialPageRoute(
      //                       builder: (context) => EssaysView(
      //                           essayID: (children[value] as CarouselCard).id,
      //                           courseID: (children[value] as CarouselCard)
      //                               .courseId)));
      //             }
      //           },
      //           children: children,
      //         )));

      return Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 250),
              child: CarouselView(
                backgroundColor: Theme.of(context).primaryColor,
                itemExtent: 400,
                shrinkExtent: 250,
                onTap: (value) {
                  if (type == 'assessment') {
                    bool isMoodleSelected = isMoodle();
                    String courseIdStr = (children[value] as CarouselCard)
                            .courseId
                            ?.toString() ??
                        '';
                    String assessmentIdStr =
                        (children[value] as CarouselCard).id.toString();

                    print('Course ID I am sending: $courseIdStr');
                    print('Assessment ID I am sending: $assessmentIdStr');

                    if (!isMoodleSelected) {
                      // Assuming "google" is !isMoodle()
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuizQuestionPage(
                            coursedId: courseIdStr,
                            assessmentId: assessmentIdStr,
                          ),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MAssessmentsView(
                            quizID: (children[value] as CarouselCard).id,
                            courseID:
                                (children[value] as CarouselCard).courseId ?? 0,
                          ),
                        ),
                      );
                    }
                  } else if (type == 'essay') {
                    print(
                        (children[value] as CarouselCard).courseId?.toString());
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => EssaysView(
                                essayID: (children[value] as CarouselCard).id,
                                courseID: (children[value] as CarouselCard)
                                    .courseId)));
                  }
                },
                children: children,
              )));
    }
  }
}

//Cards for the Carousel
class CarouselCard extends StatelessWidget {
  //assignment name
  final String title;
  //assignment information (may want to get a specific format, need to look into the various settings for each)
  final String information;
  //acceptable types: assessment, essay, submission
  final String type;
  final int id;
  final int? courseId;

  CarouselCard(this.title, this.information, this.type, this.id,
      {this.courseId});

  static CarouselCard fromQuiz(Quiz input) {
    return CarouselCard(
        input.name ?? "Unnamed Quiz",
        input.description?.replaceAll(RegExp(r"<[^>]*>"), "") ?? '',
        'assessment',
        input.id ?? 0,
        courseId: input.coursedId);
  }

  static List<CarouselCard>? fromQuizzes(List? input) {
    if (input == null) {
      return null;
    }
    List<CarouselCard> output = [];
    for (Object c in input) {
      if (c is Quiz) {
        output.insert(output.length, fromQuiz(c));
      }
    }
    return output;
  }

  static CarouselCard fromEssay(Assignment input) {
    return CarouselCard(
        input.name,
        input.description.replaceAll(RegExp(r"<[^>]*>"), ""),
        'essay',
        input.id ?? 0,
        courseId: input.courseId);
  }

  static List<CarouselCard>? fromEssays(List? input) {
    if (input == null) {
      return null;
    }
    List<CarouselCard> output = [];
    for (Object c in input) {
      if (c is Assignment) {
        output.insert(output.length, fromEssay(c));
      }
    }
    return output;
  }

  @override
  Widget build(BuildContext context) {
    List<Course>? theCourses = LmsFactory.getLmsService().courses;
    Course matchedCourse =
        theCourses!.firstWhere((element) => element.id == courseId);
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25.0), // Rounded corners
      ),
      child: SizedBox(
          height: 200, // Adjust this value based on the desired height
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child:
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(information),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Course: ${matchedCourse.fullName}'),
              ),
              Spacer(), // Pushes the buttons to the bottom
            ],
          )),
    );
  }
}

//buttons navigating to the create pages
class CreateButton extends StatelessWidget {
  //todo: maybe autofill filter information into the assignment creation settings?
  final String filters = '';
  //acceptable types: assessment, essay
  final String type;
  final String text;

  CreateButton._(this.type, this.text);

  factory CreateButton(String type) {
    if (type == "assessment") {
      return CreateButton._(type, "Create New Assessment");
    } else if (type == "essay") {
      return CreateButton._(type, "Create New Essay Assignment");
    } else {
      return CreateButton._(type, "");
    }
  }

  bool isMoodle() {
    print(LocalStorageService.getSelectedClassroom());
    return LocalStorageService.getSelectedClassroom() == LmsType.MOODLE;
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
        onPressed: () {
          MaterialPageRoute? route;
          if (type == 'assessment') {
            route = MaterialPageRoute(builder: (context) => CreateAssessment());
          } else if (type == 'essay') {
            bool isMoodleSelected = isMoodle();
            if (!isMoodleSelected) {
              // Assuming "google" is !isMoodle()

              route = MaterialPageRoute(
                  builder: (context) => CreateAssignmentPage());
            } else {
              route = MaterialPageRoute(
                  builder: (context) => EssayGeneration(title: 'New Essay'));
            }
          }
          if (route != null) {
            Navigator.push(context, route);
          }
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [Icon(Icons.add), Text(text)],
        ));
  }
}
