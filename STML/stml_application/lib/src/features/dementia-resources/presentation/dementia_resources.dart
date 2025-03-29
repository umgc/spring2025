import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:memoryminder/src/features/caregiver-dashboard/presentation/app_bar.dart';
import 'package:memoryminder/src/utils/ui_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:memoryminder/src/utils/logger.dart';

class ResourceEntry {
  final String text;
  final String link;
  final String displayLink;

  ResourceEntry(
      {required this.text, required this.link, required this.displayLink});

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'link': link,
      'displayLink':displayLink,
    };
  }

  static ResourceEntry fromMap(Map<String, dynamic> map) {
    return ResourceEntry(
      text: map['text'],
      link: map['link'],
      displayLink: map['displayLink'],
    );
  }
}

class DementiaResourcesScreen extends StatefulWidget {
  final String? loc;
  const DementiaResourcesScreen({super.key, this.loc});
  @override
  _DementiaResourcesScreenState createState() => _DementiaResourcesScreenState();
}

class _DementiaResourcesScreenState extends State<DementiaResourcesScreen> {
  List<String> searchResults = [];

  _DementiaResourcesScreenState() {
    _fetchSearchResults();
  }

  // Fetch the search results from Google (or any search engine with a query)
  Future<List<ResourceEntry>> _fetchSearchResults() async {
    String apiKeyEnv = dotenv.get('GOOGLE_SEARCH_API_KEY', fallback: "");
    String searchEngineIdEnv = dotenv.get('SEARCH_ENGINE_ID', fallback: "");

    //The location is temporarily hard-coded to complete the implementation of this story.

    String encodedQueryString = Uri.encodeComponent('Dementia Resources in ${widget.loc ?? 'USA'}');

    final query = 'https://www.googleapis.com/customsearch/v1?q=$encodedQueryString&cx=$searchEngineIdEnv&key=$apiKeyEnv';
    final url = Uri.parse('$query');

    // Send the HTTP request to fetch the page
    final response = await http.get(url);

    if (response.statusCode == 200) {
      // If the server returns a successful response
      final data = jsonDecode(response.body);
      List<ResourceEntry> results = [];

      // Check if there are items in the 'items' field (search results)
      if (data['items'] != null) {
        for (var item in data['items']) {
          results.add(ResourceEntry(text: item['title'], link: item['link'], displayLink: item['displayLink']));  // Add the link to the result list
        }
      } else {
        results.add(ResourceEntry(text: 'No resources found. Check the care recipient location.', link: '', displayLink: ''));
      }
      return results;
    } else {
      appLogger.severe('Failed to load dementia resources search results');
      // If the server returns an error
      throw Exception('Failed to load dementia resources search results');
    }
  }

  // Function to launch URL in the browser
  _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      appLogger.severe('Could not launch Dementia Resource url - $url');
      appLogger.severe('Could not launch Dementia Resource url - $url');
      throw 'Could not launch  - $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: const CustomAppBar(
          title: 'Dementia Resources',
        ),
        body: Container(

          child: FutureBuilder<List<ResourceEntry>>(
            future: _fetchSearchResults(), // The Future you want to await
            builder: (context, snapshot) {
              // Handle different states of the Future

              if (snapshot.connectionState == ConnectionState.waiting) {
                // While data is being fetched
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                // If there was an error
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.hasData) {
                // If data is available
                final resources = snapshot.data!;

                return ListView.builder(
                  itemCount: resources.length,
                  itemBuilder: (context, index) {
                    Color backgroundColor = index % 2 == 0 ? Colors.white : Colors.grey[300]!;
                    final resource = resources[index];
                    return Card(
                      color: backgroundColor,
                      margin: EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        leading: Icon(Icons.bookmark_outline),
                        title: Text(resource.text),
                        subtitle: Text(resource.displayLink, style: TextStyle(color: Colors.blue,)),
                        onTap: () {
                          _launchURL(resource.link); // Open the link
                        },
                      ),
                    );
                  },
                );
              }

              return Center(child: Text("No data available"));
            },


          ),
        ),
        bottomNavigationBar: UiUtils.createBottomNavigationBar(context));

  }
}