import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class Essay 
{
  //Holds the assignment prompt
  String? prompt;
  //Holds the course level information
  String? courseLevel;
  //Holds the list of crtiera for a given assignment
  List<Criterion> criteria;
  //Constructor for a standard essay
  Essay(this.prompt, this.courseLevel, this.criteria);
  //Generates the table data for the rubric based on the criteria for the essay object. Does not create header row.
  List<Map<String, String>> genTableData() 
  {
    List<Criterion> critList = criteria;
    List<Map<String, String>> tableData = [];
    for (Criterion c in critList) 
    {
      int iterator = 1;
      Map<String, String> tempMap = {};
      String currName = c.name;
      num currWeight = c.points;
      Map<String, String> desc = c.descriptions;
      for (MapEntry<String, String> d in desc.entries) {
        if (iterator == 1) {
          tempMap[''] = '$currName\n\nPoints: $currWeight';
          iterator++;
        }
        tempMap[d.key] = d.value;
        iterator++;
      }
      tableData.add(tempMap);
    }
    return tableData;
  }
  //Creates the header row for the table data
  List<String> genHeaderData() 
  {
    List<String> headerData = criteria[0].descriptions.keys.toList();
    headerData.insert(0, '');
    return headerData;
  }
}
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

// Fetch Criteria data from JSON file and add it to the program
Future<List<dynamic>> fetchJsonCriteria() async 
{
  final String jsonString = await rootBundle.loadString('assets/Criteria.json');
  final Map<String, dynamic> jsonData = json.decode(jsonString);
  List<dynamic> critList = jsonData['Criteria']; // Access the 'users' key
  return critList.map((critJson) => Criterion.fromJson(critJson)).toList();
}

// Take the default descriptions from the JSON and build full list of critieria based on scale
Future<List<Criterion>> generateCriteria(
    int scale, List<String> selectedCriteria) async {
  List<Criterion> allCriteria = await fetchJsonCriteria() as List<Criterion>;
  List<Criterion> myCriteria = [];
  int iterator = 0;
  for (Criterion c in allCriteria) {
    List<String> newValues = [];
    if (selectedCriteria.contains(c.name)) {
      myCriteria.add(c);
      switch (scale) {
        case 3:
          for (int i = 0; i <= 2; i++) {
            String currScale = c.scale3[i];
            String currDesc = c.defaultDesc;
            newValues.add("Student displays $currScale $currDesc");
          }
          myCriteria[iterator].addDescriptions(c.scale3, newValues);
          myCriteria[iterator].setWeight(3);
          iterator++;
        case 4:
          for (int i = 0; i <= 3; i++) {
            String currScale = c.scale4[i];
            String currDesc = c.defaultDesc;
            newValues.add("Student displays $currScale $currDesc");
          }
          myCriteria[iterator].addDescriptions(c.scale4, newValues);
          myCriteria[iterator].setWeight(4);
          iterator++;
        case 5:
          for (int i = 0; i <= 4; i++) {
            String currScale = c.scale5[i];
            String currDesc = c.defaultDesc;
            newValues.add("Student displays $currScale $currDesc");
          }
          myCriteria[iterator].addDescriptions(c.scale5, newValues);
          myCriteria[iterator].setWeight(5);
          iterator++;
      }
    }
  }
  return myCriteria;
}

//App that constructs the table widget
class TableApp extends StatelessWidget 
{
  const TableApp(this.tableData, this.headerData);
  final List<Map<String, String>> tableData;
  final List<String> headerData;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Editable Table',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Rubric'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: EditableTable(tableData: tableData, headerData: headerData),
          ),
        ),
      ),
    );
  }
}

//Object that creates editable table rows
class EditableTable extends StatefulWidget 
{
  final List<Map<String, String>> tableData;
  final List<String> headerData;
  EditableTable({required this.tableData, required this.headerData});
  @override
  _EditableTableState createState() => _EditableTableState();
}

class _EditableTableState extends State<EditableTable> 
{
  late List<Map<String, TextEditingController>> controllers;
  @override
  void initState() {
    super.initState();
    // Create controllers for each cell in the table except the first column
    controllers = widget.tableData.map((row) {
      return row.map((key, value) {
        return MapEntry(key, TextEditingController(text: value));
      });
    }).toList();
  }
  @override
  Widget build(BuildContext context) {
    return Table(
      border: TableBorder.all(),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: _buildTableRows(),
    );
  }
  // Function to build the table rows dynamically
  List<TableRow> _buildTableRows() {
    List<TableRow> rows = [];
    // Add table header row dynamically based on column headers
    rows.add(
      TableRow(
        children: widget.headerData.map((header) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(header,
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold)),
          );
        }).toList(),
      ),
    );
    // Add rows dynamically based on data
    for (var i = 0; i < widget.tableData.length; i++) {
      rows.add(
        TableRow(
          children: widget.headerData.map((header) {
            // If it is the first column, display it as static text
            if (header == widget.headerData.first) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(widget.tableData[i][header] ?? '',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    )),
              );
            }
            // For other columns, make them editable
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                controller: controllers[i][header],
                onChanged: (value) {
                  widget.tableData[i][header] = value; // Update the data
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.multiline,
                maxLines: null, // This allows the text field to wrap and expand
                minLines: 1, // Minimum number of lines the field should show
              ),
            );
          }).toList(),
        ),
      );
    }
    return rows;
  }
  @override
  void dispose() {
    // Dispose of all controllers when the widget is disposed
    for (var row in controllers) {
      for (var controller in row.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }
}