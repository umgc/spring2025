import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:learninglens_app/Api/llm/llm_api_modules_base.dart';
import 'package:learninglens_app/services/api_service.dart';

class OpenAiLLM implements LLM {
  @override
  final String apiKey;
  @override
  final String url = 'https://api.openai.com/v1/chat/completions';
  @override
  final String model = 'gpt-4o-mini';
  OpenAiLLM(this.apiKey);

  Map<String, dynamic> convertHttpRespToJson(String httpResponseString) {
    return (json.decode(httpResponseString) as Map<String, dynamic>);
  }

  ///
  ///
  ///
  String getPostBody(String queryMessage) {
    return jsonEncode({
      'model': model,
      'messages': [
        {'role': 'system', 'content': 'Be precise and concise'},
        {'role': 'user', 'content': queryMessage}
      ]
    });
  }

  ///
  ///
  ///
  Map<String, String> getPostHeaders() {
    return ({
      'accept': 'application/json',
      'content-type': 'application/json',
      'authorization': 'Bearer $apiKey',
    });
  }

  ///
  ///
  ///
  Uri getPostUrl() => Uri.https('api.openai.com', '/v1/chat/completions');

  ///
  ///
  ///
  Future<String> postMessage(
      Uri url, Map<String, String> postHeaders, Object postBody) async {
    final httpPackageResponse =
        await ApiService().httpPost(url, headers: postHeaders, body: postBody);

    print(url);
    print(postHeaders);
    print(postBody);

    if (httpPackageResponse.statusCode != 200) {
      print('Failed to retrieve the http package!');
      print('statusCode :  ${httpPackageResponse.statusCode}');
      print('Reason: ${httpPackageResponse.body}');

      return "";
    }

    print("In postmessage : ${httpPackageResponse.body}");
    return httpPackageResponse.body;
  }

  List<String> parseQueryResponse(String resp) {
    // ignore: prefer_adjacent_string_concatenation
    String quizRegExp =
        // r'(<\?xml.*?\?>\s*<quiz>(\s*.*?<question>\s*.*?<text>\s*(.*?)</text>\s*.*?<options>(\s*.*?<option>\s*(.*?)</option>)+\s*</options>\s*.*?<answer>\s*(.*?)</answer>\s*.*?</question>)+\s*</quiz>)';
        r'(<\?xml.*?\?>\s*<quiz>.*?</quiz>)';

    RegExp exp = RegExp(quizRegExp);
    String respNoNewlines = resp.replaceAll('\n', '');
    Iterable<RegExpMatch> matches = exp.allMatches(respNoNewlines);
    List<String> parsedResp = [];

    print("Parsing the query response - matches: $matches");

    for (final m in matches) {
      if (m.group(0) != null) {
        parsedResp.add(m.group(0)!);

        print("This is a match : ${m.group(0)}");
        print("Number of groups in the match: ${m.groupCount}");
        print("parsedResp : $parsedResp");
      }
    }

    return parsedResp;
  }

  ///
  ///
  ///
  Future<String> postToLlm(String queryPrompt) async {
    var resp = "";

    // use the following test query so Perplexity doesn't charge
    // 'How many stars are there in our galaxy?'
    if (queryPrompt.isNotEmpty) {
      resp = await queryAI(queryPrompt);
    }
    return resp;
  }

  ///
  ///
  ///
  Future<String> queryAI(String query) async {
    final postHeaders = getPostHeaders();
    final postBody = getPostBody(query);
    final httpPackageUrl = getPostUrl();

    final httpPackageRespString =
        await postMessage(httpPackageUrl, postHeaders, postBody);

    final httpPackageResponseJson =
        convertHttpRespToJson(httpPackageRespString);

    var retResponse = "";
    for (var respChoice in httpPackageResponseJson['choices']) {
      retResponse += respChoice['message']['content'];
    }
    print("In queryAI - content :  $retResponse");
    return retResponse;
  }

  Future<String> getChatResponse(String prompt) async {

    final postHeaders = getPostHeaders();
    final postBody = getPostBody(prompt);
    final httpPackageUrl = getPostUrl();

    try {
      // Make the POST request to the chat completions endpoint
      var response = await ApiService().httpPost(httpPackageUrl, headers: postHeaders, body: postBody);

      // Check for successful response
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return data['choices'][0]['message']['content']
            .trim(); // Return the chat response
      } else {
        // Log the error response and handle failure cases
        print('Failed to fetch response. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return 'Sorry, I couldn’t fetch a response. Please try again.';
      }
    } catch (error) {
      // Log and handle connection or parsing errors
      print('Error occurred: $error');
      return 'An error occurred. Please check your internet connection and try again.';
    }
  }
  
  @override
  Future<String> generate(String prompt) async {
    print("In generate - prompt : $prompt");
  
final url = Uri.parse(this.url);
    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'model': model, 
      'messages': [
        {'role': 'system', 'content': 'You are a helpful assistant.'},
        {'role': 'user', 'content': prompt},
      ],
      'max_tokens': 500, // Limit response length
    });

    final response = await http.post(url, headers: headers, body: body);
    if (response.statusCode != 200) {
      throw Exception('OpenAI API error: ${response.statusCode} - ${response.body}');
    }

    final data = jsonDecode(response.body);
    return data['choices'][0]['message']['content'].trim();

  }

}