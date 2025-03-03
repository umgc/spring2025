//A criterion represents a single criteria for use in rubric data
class Criterion 
{
  //The name of the criterion, represents the quality being assessed
  String name;
  //The weight of the criterion, represents the grade percentage of the category
  num points;
  /// First String in map represents the scale level (e.g. Excellent, Poor)
  /// Second String represents the description of the critiera
  Map<String, String> descriptions;
  //Holds the default description before it's filled in with scale information
  String defaultDesc;
  //Defines the available scale descriptions
  final List<String> scale3 = ["High", "Moderate", "Low"];
  final List<String> scale4 = ["Outstanding", "Excellent", "Good", "Poor"];
  final List<String> scale5 = [
    "Exceptional",
    "Highly effective",
    "Effective",
    "Inconsistent",
    "Unsatisfactory"
  ];
  //Creates Criterion object
  Criterion(this.name, this.points, this.descriptions, this.defaultDesc);
  //Creates Criterion object from JSON asset
  Criterion.fromJson(Map<String, dynamic> json)
      : name = json['Name'],
        points = 0,
        descriptions = {},
        defaultDesc = json['Description'];
        
  void setWeight(num weight) {
    points = weight;
  }
  void addDescriptions(List<String> scale, List<String> values) {
    descriptions = Map.fromIterables(scale, values);
  }
}