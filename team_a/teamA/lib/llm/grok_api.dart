import 'dart:async';
import 'dart:convert';
import 'package:learninglens_app/services/api_service.dart';

class GrokLLM {
  final String grokKey;

  GrokLLM(this.grokKey);

  Map<String, dynamic> convertHttpRespToJson(String httpResponseString) {
    return (json.decode(httpResponseString) as Map<String, dynamic>);
  }

//   curl https://api.x.ai/v1/chat/completions -H "Content-Type: application/json" -H "Authorization: Bearer grokKey" -d '{
//   "messages": [
//     {
//       "role": "system",
//       "content": "You are a test assistant."
//     },
//     {
//       "role": "user",
//       "content": "Testing. Just say hi and hello world and nothing else."
//     }
//   ],
//   "model": "grok-2-latest",
//   "stream": false,
//   "temperature": 0
// }'

  ///
  ///
  ///
  String getPostBody(String queryMessage) {
    return jsonEncode({
      'model': 'grok-2-latest',
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
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $grokKey',
    });
  }

  ///
  ///
  ///
  Uri getPostUrl() => Uri.https('api.x.ai', '/v1/chat/completions');

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
}