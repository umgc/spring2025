import 'package:xml/xml.dart';
import 'package:learninglens_app/beans/xml_consts.dart';

// A single answer for a Question object. Used by all question types except for essay.
class Answer {
  String answerText; // Multiple choice text - required
  String fraction; // Point value from 0 (incorrect) to 100 (correct) - required
  String? feedbackText; // Feedback for the choice - optional

  // Simple constructor. Feedback param is optional.
  Answer(this.answerText, this.fraction, [this.feedbackText]);

  // XML factory constructor
  factory Answer.fromXml(XmlElement answerElement) {
    return Answer(
        answerElement.getElement(XmlConsts.text)?.innerText ?? 'UNKNOWN',
        answerElement.getAttribute(XmlConsts.fraction) ?? '100',
        answerElement
            .getElement(XmlConsts.feedback)
            ?.getElement(XmlConsts.text)
            ?.innerText);
  }

  void buildXml(XmlBuilder builder) {
    builder.element(XmlConsts.answer, attributes: {XmlConsts.fraction: fraction}, nest: () {
      builder.element(XmlConsts.text, nest: answerText);
      if (feedbackText != null) {
        builder.element(XmlConsts.feedback, nest: () {
          builder.element(XmlConsts.text, nest: feedbackText);
        });
      }
    });
  }

  @override
  String toString() {
    final sb = StringBuffer();
    sb.write(answerText);
    sb.write('  <= ($fraction%)');
    if (feedbackText != null) {
      sb.write(' - $feedbackText');
    }
    return sb.toString();
  }
}