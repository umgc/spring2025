import 'package:xml/xml.dart';
import 'package:learninglens_app/beans/xml_consts.dart';

// Specific Rubric Criteria
class RubricCriteria {
  String description;
  int points;
  String feedback;

  RubricCriteria({
    required this.description,
    required this.points,
    this.feedback = '',
  });

  // Factory constructor to create criteria from XML
  factory RubricCriteria.fromXml(XmlElement criteriaElement) 
  {
    return RubricCriteria(
      description: criteriaElement.getElement(XmlConsts.description)?.innerText ?? 'Unknown',
      points: int.parse(criteriaElement.getElement(XmlConsts.points)?.innerText ?? '0'),
      feedback: criteriaElement.getElement(XmlConsts.feedback)?.innerText ?? '',
    );
  }

  // Convert the criteria to XML format
  void toXml(XmlBuilder builder) 
  {
    builder.element(XmlConsts.description, nest: description);
    builder.element(XmlConsts.points, nest: points.toString());
    builder.element(XmlConsts.feedback, nest: feedback);
  }

  @override
  String toString() {
    final builder = XmlBuilder();
    toXml(builder);
    return builder.buildFragment().toXmlString();
  }
}