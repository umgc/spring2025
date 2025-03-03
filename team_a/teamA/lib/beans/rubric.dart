import 'package:xml/xml.dart';
import 'package:learninglens_app/beans/rubric_criteria.dart';
import 'package:learninglens_app/beans/xml_consts.dart';

// A generated rubric containing criteria for an essay prompt.
// Commented out as the only other instance of Rubric being used is the other one.
class Rubric {
  String title;
  String subject;
  String gradeLevel;
  int maxPoints;
  List<RubricCriteria> criteriaList;

  Rubric({
    required this.title,
    required this.subject,
    required this.gradeLevel,
    required this.maxPoints,
    required this.criteriaList,
  });

  // Factory constructor to create a Rubric from XML
  factory Rubric.fromXmlString(String xmlStr) 
  {
    final document = XmlDocument.parse(xmlStr);
    final rubricElement = document.getElement(XmlConsts.rubric);

    return Rubric(
      title: rubricElement?.getElement(XmlConsts.title)?.innerText ?? 'Untitled',
      subject: rubricElement?.getElement(XmlConsts.subject)?.innerText ?? 'Unknown',
      gradeLevel: rubricElement?.getElement(XmlConsts.gradeLevel)?.innerText ?? 'Unknown',
      maxPoints: int.parse(rubricElement?.getElement(XmlConsts.maxPoints)?.innerText ?? '0'),
      criteriaList: rubricElement
          ?.findElements(XmlConsts.criteria)
          .map((e) => RubricCriteria.fromXml(e))
          .toList() ?? [],
    );
  }

    // Convert the Rubric object to an XML string
  String toXmlString() {
    final builder = XmlBuilder();
    builder.element(XmlConsts.rubric, nest: () {
      builder.element(XmlConsts.title, nest: title);
      builder.element(XmlConsts.subject, nest: subject);
      builder.element(XmlConsts.gradeLevel, nest: gradeLevel);
      builder.element(XmlConsts.maxPoints, nest: maxPoints.toString());

      for (var criteria in criteriaList) {
        builder.element(XmlConsts.criteria, nest: criteria.toXml);
      }
    });
    return builder.buildDocument().toXmlString(pretty: true);
  }

  @override
  String toString() {
    return toXmlString();
  }
}