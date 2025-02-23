import 'package:xml/xml.dart';
import 'package:learninglens_app/beans/question.dart';
import 'package:learninglens_app/beans/xml_consts.dart';

// A Moodle quiz containing a list of questions.
class Quiz {
  String? name; // quiz name - optional.
  String? description; // quiz description - optional.
  List<Question> questionList = <Question>[]; // list of questions on the quiz.
  String? promptUsed;
  int? id; // quiz id, null if the quiz doesn't exist in Moodle yet
  int? coursedId;
  DateTime? timeOpen;
  DateTime? timeClose;
  // Constructor with all optional params.
  Quiz(
      {this.name,
      this.coursedId,
      this.description,
      this.id,
      this.timeOpen,
      this.timeClose,
      List<Question>? questionList})
      : questionList = questionList ?? [];

  // XML factory constructor using XML string
  factory Quiz.fromXmlString(String xmlStr) {
    Quiz quiz = Quiz();
    final document = XmlDocument.parse(xmlStr);
    final quizElement = document.getElement(XmlConsts.quiz);

    quiz.name = quizElement
        ?.getElement(XmlConsts.name)
        ?.getElement(XmlConsts.text)
        ?.innerText;

    quiz.description =
        quizElement!.getElement(XmlConsts.description)?.innerText;

    for (XmlElement questionElement
        in quizElement.findElements(XmlConsts.question)) {
      if (questionElement.getAttribute(XmlConsts.type) == 'category') {
        continue; // Skip category type questions
      }
      quiz.questionList.add(Question.fromXml(questionElement));
    }
    quiz.promptUsed = quizElement.getElement(XmlConsts.promptUsed)?.innerText;
    return quiz;
  }

  String toXmlString() {
    final builder = XmlBuilder();
    builder.element(XmlConsts.quiz, nest: () {
      // Name element
      if (name != null) {
        builder.element(XmlConsts.name, nest: () {
          builder.element(XmlConsts.text, nest: name);
        });
      }

      // Description element
      if (description != null) {
        builder.element(XmlConsts.description, nest: description);
      }

      // Insert a "category" type question using the description as the category name
      if (description != null) {
        builder.element(XmlConsts.question,
            attributes: {XmlConsts.type: 'category'}, nest: () {
          builder.element(XmlConsts.category, nest: () {
            builder.element(XmlConsts.text,
                nest: '\$course\$/Top/$description');
          });
        });
      }

      // PromptUsed element
      if (promptUsed != null) {
        builder.element(XmlConsts.promptUsed, nest: promptUsed);
      }

      // Questions
      for (var question in questionList) {
        question.buildXml(builder);
      }
    });

    return builder.buildDocument().toXmlString(pretty: true);
  }

  bool isNew() {
    return id == null;
  }

  @override
  String toString() {
    final sb = StringBuffer();
    sb.write('Quiz Name: $name\n');
    sb.write('Quiz Description: $description\n\n');
    for (var i = 1; i <= questionList.length; i++) {
      sb.write('Q$i: ');
      sb.write(questionList[i - 1].toString());
      sb.write('\n\n');
    }
    return sb.toString();
  }
}
