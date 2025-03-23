import 'package:flutter/material.dart';
import 'package:editable/editable.dart';
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/Controller/custom_appbar.dart';
import 'dart:convert';

import 'send_essay_to_moodle.dart'; // Import for JSON encoding

class EssayEditPage extends StatefulWidget {
  final String jsonData;
  final String description;
  
  EssayEditPage(this.jsonData, this.description);
  
  @override
  EssayEditPageState createState() => EssayEditPageState(); // Public State class
}

class EssayEditPageState extends State<EssayEditPage> {


  // Convert JSON to rows compatible with Editable
  List rows = [];

  // Headers or Columns
  List headers = [];

  @override
  void initState() {
    super.initState();
    
    populateHeadersAndRows();
  }

  // Function to dynamically populate headers and rows based on JSON data
  void populateHeadersAndRows() {
    Map<String, dynamic> mappedData = jsonDecode(widget.jsonData);
    // Step 1: Build headers dynamically based on the number of levels in the first criterion
    List<dynamic> levels = List<dynamic>.from(mappedData['criteria']![0]['levels'] as List);
headers = [
  {"title": 'Criteria', 'index': 1, 'key': 'name', 'widthFactor': 0.15}, // 30% width
];

for (int i = 0; i < levels.length; i++) {
  headers.add({
    "title": '${levels[i]['score']}',
    'index': i + 2,
    'key': 'level_$i',
    'widthFactor': 0.8/levels.length, // 10% width for each level column
  });
}

    // Step 2: Build rows by mapping each criterion and its levels dynamically
    rows = (mappedData['criteria'] ?? []).map((criterion) {
      Map<String, dynamic> row = {
        "name": criterion['description'],
      };

      for (int i = 0; i < (criterion['levels'] as List).length; i++) {
        row['level_$i'] = (criterion['levels'] as List)[i]['definition'];
      }

      return row;
    }).toList();

    setState(() {}); // Ensure the UI is updated after populating headers and rows
  }

  /// Create a Key for EditableState
  final _editableKey = GlobalKey<EditableState>(); 

  /// Merge edits into the original jsonData and return updated JSON
  String getUpdatedJson() {
    List editedRows = _editableKey.currentState!.editedRows;
    Map<String, dynamic> mappedData = jsonDecode(widget.jsonData);

    // Apply the edits to the original jsonData
    for (var editedRow in editedRows) {
      int rowIndex = editedRow['row'];
      var originalCriterion = mappedData['criteria']?[rowIndex];

      // For each edited level, update the corresponding level in the original data
      editedRow.forEach((key, value) {
        if (key != 'row' && key.startsWith('level_')) {
          int levelIndex = int.parse(key.split('_')[1]);
          (originalCriterion as Map<String, dynamic>)['levels']?[levelIndex]['definition'] = value;
        }
      });
    }

    // Convert the updated jsonData back to the required format and return it
    Map<String, dynamic> updatedData = {
      "criteria": mappedData['criteria']
    };
    return jsonEncode(updatedData); // Return the JSON as a string
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: CustomAppBar(title: 'Edit Essay Rubric', userprofileurl: LmsFactory.getLmsService().profileImage ?? ''),  
    body: LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Align content to the top-left
          children: [
            SizedBox(height: 24.0),
            
            // Expanded is used for the Editable, wrapped with SingleChildScrollView for horizontal scrolling
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal, // Allow horizontal scrolling for the Editable
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: 600, // Ensure the table never shrinks below 600px
                    maxWidth: constraints.maxWidth > 600 ? constraints.maxWidth : 600,
                  ),
                  child: Editable(
                    key: _editableKey,
                    tdEditableMaxLines: 100,
                    trHeight: 100,
                    columns: headers,
                    rows: rows,
                    showCreateButton: false,
                    tdStyle: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    showSaveIcon: false,
                    onRowSaved: (value) {
                      print('rowsaved $value');
                    },
                    borderColor: Theme.of(context).colorScheme.primaryContainer,
                    onSubmitted: (value) {
                      print('onsubmitted: $value'); // You can grab this data to store anywhere
                    },
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 20), // Add some spacing between the Editable and the button
            
            // Row for the Button outside the scrollable area
            Row(
              mainAxisAlignment: MainAxisAlignment.center, // Center the button horizontally
              children: [
                ElevatedButton(
                  child: const Text('Send to Moodle'),
                  onPressed: () {
                    String updatedJson = getUpdatedJson();
                    // Navigate to the Essay Assignment Settings page with the updated JSON
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) =>
                            EssayAssignmentSettings(updatedJson, widget.description)));
                    print(updatedJson); // You can now see the updated JSON in the console
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Data sent to Moodle')));
                  },
                ),
              ],
            ),
            SizedBox(height: 20), // Optional additional spacing
          ],
        );
      },
    ),
  );
}





}