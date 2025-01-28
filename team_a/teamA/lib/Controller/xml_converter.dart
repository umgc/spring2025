import 'package:collection/collection.dart';
import 'html_converter.dart';
import 'package:xml/xml.dart';

import 'package:learninglens_app/Controller/beans.dart';

// Static utility class for Moodle XML related functions.
class XmlConverter {

  static const cdata1 = '<![CDATA[';
  static const cdata2 = ']]>';

  // Convert a populated Quiz object into an XML Document.
  //
  // To get the XML String, use XmlDocument.toXmlString()
  static XmlDocument convertQuizToXml(Quiz quiz, [bool? toMoodle]) {
    bool convertForMoodle = toMoodle ?? false;
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element(XmlConsts.quiz, nest: () {
      // build category dummy node
      builder.element(XmlConsts.name, nest: quiz.name ?? 'Unnamed Quiz');
      builder.element(XmlConsts.description, nest: quiz.description ?? 'No description');
      builder.element(XmlConsts.question, nest: () {
        builder.attribute(XmlConsts.type, 'category');
        builder.element('category', nest: () {
          builder.element(XmlConsts.text, nest: '\$course\$/top/LLM-Generated');
        });
      });
      for (Question question in quiz.questionList) {
        builder.element(XmlConsts.question, nest: () {
          // question type
          builder.attribute(XmlConsts.type, question.type);
          // question name
          builder.element(XmlConsts.name, nest: () {
            if (convertForMoodle) {
              builder.element(XmlConsts.text, nest: getShortenedDesc(question.questionText));
            } else {
              builder.element(XmlConsts.text, nest: question.name);
            }
          });
          // question text
          builder.element(XmlConsts.questiontext, nest: () {
            builder.attribute(XmlConsts.format, XmlConsts.html);
            builder.element(XmlConsts.text, nest: () {
              builder.cdata(question.questionText);
            });
          });
          // general feedback
          if (question.generalFeedback != null) {
            builder.element(XmlConsts.generalfeedback, nest: () {
              builder.attribute(XmlConsts.format, XmlConsts.html);
              builder.element(XmlConsts.text, nest: () {
                builder.cdata(question.generalFeedback!);
              });
            });
          }
          // default grade
          if (question.defaultGrade != null) {
            builder.element(XmlConsts.defaultgrade, nest: question.defaultGrade);
          }
          // response format
          if (question.responseFormat != null) {
            builder.element(XmlConsts.responseformat, nest: question.responseFormat);
          }
          // response required
          if (question.responseRequired != null) {
            builder.element(XmlConsts.responserequired, nest: question.responseRequired);
          }
          // attachments required
          if (question.attachmentsRequired != null) {
            builder.element(XmlConsts.attachmentsrequired, nest: question.attachmentsRequired);
          }
          // response template
          if (question.responseTemplate != null) {
            builder.element(XmlConsts.responsetemplate, nest: () {
              builder.cdata(question.responseTemplate!);
            });
          }
          // grader info
          if (question.graderInfo != null) {
            builder.element(XmlConsts.graderinfo, nest: () {
              builder.attribute(XmlConsts.format, XmlConsts.html);
              builder.element(XmlConsts.text, nest: () {
                builder.cdata(question.graderInfo!);
              });
            });
          }
          // answers
          for (Answer answer in question.answerList) {
            builder.element(XmlConsts.answer, nest: () {
              builder.attribute(XmlConsts.fraction, answer.fraction);
              builder.element(XmlConsts.text, nest: answer.answerText);
              if (answer.feedbackText != null) {
                builder.element(XmlConsts.feedback, nest: () {
                  builder.element(XmlConsts.text, nest: answer.feedbackText);
                });
              }
            });
          }
        });
      }
      builder.element(XmlConsts.promptUsed, nest: quiz.promptUsed);
    });
    return builder.buildDocument();
  }

  static String getShortenedDesc(String description) {
    int charLimit = 30;
    String desc = HtmlConverter.convert(description.trim());
    desc = desc.replaceAll('\n', '');
    if (desc.length <= charLimit) return desc;
    desc = desc.substring(0, charLimit);
    desc = desc.substring(0, desc.lastIndexOf(' '));
    desc = "$desc...";
    return desc;
  }

  // Split a quiz into list of smaller quizzes
  static List<Quiz> splitQuiz(Quiz quiz) {
    int qperq;
    switch (quiz.questionList.first.type) {
      case 'essay':
        qperq = 1;
        break;
      case 'multichoice':
      case 'truefalse':
      case 'shortanswer':
      default:
        qperq = 4;
    }
    List<List<Question>> splitQuizzes = quiz.questionList.slices(qperq).toList();
    List<Quiz> quizList = [];
    for (List<Question> q in splitQuizzes) {
      quizList.add(Quiz(questionList: q));
    }
    return quizList;
  }
}