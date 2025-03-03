import 'package:xml/xml.dart';
import 'package:learninglens_app/beans/answer.dart';
import 'package:learninglens_app/beans/xml_consts.dart';

// Abstract class that represents a single question.
class Question {

  Question copyWith({String? name, List? answerList, String? type, String? questionText, bool? isFavorite}) =>
      Question(name: this.name, answerList: this.answerList,type: this.type, questionText: this.questionText, isFavorite: isFavorite ?? this.isFavorite);

  String name; // question name - required.
  String type; // question type (multichoice, truefalse, shortanswer, essay) - required.
  String questionText; // question text - required.
  String? generalFeedback;
  String? defaultGrade;
  String? responseFormat;
  String? responseRequired;
  String? attachmentsRequired;
  String? responseTemplate;
  String? graderInfo;
  final bool isFavorite;
  // String description;
  List<Answer> answerList =
      <Answer>[]; // list of answers. Not needed for essay.

  // Simple constructor.
  Question({
    required this.name,
    required this.type,
    required this.questionText,
    this.generalFeedback,
    this.defaultGrade,
    this.responseFormat,
    this.responseRequired,
    this.attachmentsRequired,
    this.responseTemplate,
    this.graderInfo,
    this.isFavorite = false,
    List<Answer>? answerList,
  }) : answerList = answerList ?? [];

  // XML factory constructor
  factory Question.fromXml(XmlElement questionElement) {
    Question question = Question(
      name: questionElement
              .getElement(XmlConsts.name)
              ?.getElement(XmlConsts.text)
              ?.innerText ??
          'UNKNOWN',
      type: questionElement.getAttribute(XmlConsts.type) ?? XmlConsts.essay,
      questionText: questionElement
              .getElement(XmlConsts.questiontext)
              ?.getElement(XmlConsts.text)
              ?.innerText ??
          'UNKNOWN',
      generalFeedback: questionElement
              .getElement(XmlConsts.generalfeedback)
              ?.getElement(XmlConsts.text)
              ?.innerText,
      defaultGrade: questionElement.getElement(XmlConsts.defaultgrade)?.innerText,
      responseFormat: questionElement.getElement(XmlConsts.responseformat)?.innerText,
      responseRequired: questionElement.getElement(XmlConsts.responserequired)?.innerText,
      attachmentsRequired: questionElement.getElement(XmlConsts.attachmentsrequired)?.innerText,
      responseTemplate: questionElement.getElement(XmlConsts.responsetemplate)?.innerText,
      graderInfo: questionElement.getElement(XmlConsts.graderinfo)?.getElement(XmlConsts.text)?.innerText,
    );

    for (XmlElement answerElement
        in questionElement.findElements(XmlConsts.answer).toList()) {
      question.answerList.add(Answer.fromXml(answerElement));
    }
    return question;
  }

  set setName(String newname) {
    name = newname;
  }

void buildXml(XmlBuilder builder) {
    builder.element(XmlConsts.question, attributes: {XmlConsts.type: type}, nest: () {
      builder.element(XmlConsts.name, nest: () {
        builder.element(XmlConsts.text, nest: name);
      });

      builder.element(XmlConsts.questiontext, nest: () {
        builder.element(XmlConsts.text, nest: questionText);
      });

      if (generalFeedback != null) {
        builder.element(XmlConsts.generalfeedback, nest: () {
          builder.element(XmlConsts.text, nest: generalFeedback);
        });
      }

      if (defaultGrade != null) {
        builder.element(XmlConsts.defaultgrade, nest: defaultGrade);
      }

      if (responseFormat != null) {
        builder.element(XmlConsts.responseformat, nest: responseFormat);
      }

      if (responseRequired != null) {
        builder.element(XmlConsts.responserequired, nest: responseRequired);
      }

      if (attachmentsRequired != null) {
        builder.element(XmlConsts.attachmentsrequired, nest: attachmentsRequired);
      }

      if (responseTemplate != null) {
        builder.element(XmlConsts.responsetemplate, nest: responseTemplate);
      }

      if (graderInfo != null) {
        builder.element(XmlConsts.graderinfo, nest: () {
          builder.element(XmlConsts.text, nest: graderInfo);
        });
      }

      // Answers
      for (var answer in answerList) {
        answer.buildXml(builder);
      }
    });
  }

  @override
  String toString() {
    final sb = StringBuffer();
    sb.write('$name\n$questionText');
    int charcode = 'A'.codeUnitAt(0);
    for (Answer answer in answerList) {
      String letter = String.fromCharCode(charcode);
      String answerStr = answer.toString();
      sb.write('\n  $letter. $answerStr');
      charcode++;
    }
    return sb.toString();
  }
}