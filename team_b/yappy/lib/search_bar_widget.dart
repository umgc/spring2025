import 'package:flutter/material.dart';
import 'package:yappy/services/database_helper.dart';

class SearchBarWidget extends StatefulWidget {
  final String industry;
  const SearchBarWidget({super.key, required this.industry});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late final SearchController _searchController;
  DatabaseHelper dbHelp = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _searchController = SearchController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Widget>> _fetchSuggestions(String query, String industry) async {
    List<String> results = await dbHelp.searchTranscripts(query, industry);

    return results.map((item) {
      return ListTile(
        title: Text(item),
        onTap: () {
          _showDetailsDialog(item);
        },
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 0, 0, 0),
      child: Padding(
        padding: const EdgeInsets.only(left: 4.0, right: 4.0),
        child: SearchAnchor(
          searchController: _searchController,
          suggestionsBuilder: (BuildContext context, SearchController controller) async {
            return _fetchSuggestions(controller.text, widget.industry);
          },
          builder: (BuildContext context, SearchController controller) {
            return SearchBar(
              controller: _searchController,
              padding: const WidgetStatePropertyAll<EdgeInsets>(
                EdgeInsets.symmetric(horizontal: 2.0),
              ),
              onTap: () {
                controller.openView();
              },
              onChanged: (_) {
                controller.openView();
              },
              leading: const Icon(Icons.search),
            );
          },
        ),
      ),
    );
  }

  // Opens a pop-up window when users clicks on a specific search result
  void _showDetailsDialog(String entry) async {
  Map<String, String>? transcriptDetails = await dbHelp.getTranscriptDetails(entry);

  if (transcriptDetails == null || !mounted) {
    return;
  }

    // Extract the results from the database query
  String text = transcriptDetails['text'] ?? "No text available.";
  String timestamp = transcriptDetails['timestamp'] ?? "No timestamp available.";
  String aiResponse = transcriptDetails['ai_response'] ?? "No AI response available.";

  // Shows the information extracted from the query
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Transcript Details"),
            content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Transcript Text: $text"),
                SizedBox(height: 8.0),
                Text("Timestamp: $timestamp"),
                SizedBox(height: 8.0),
                Text("AI Response: $aiResponse"),
              ],
            ),
          ),
            actions: <Widget>[
              TextButton(
                child: const Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        },
      );
    }
  }
}