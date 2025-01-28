import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LlmApi 
{
  final String apiKey;
  LlmApi(this.apiKey);

  Map<String, dynamic> convertHttpRespToJson(String httpResponseString) 
  {
    return (json.decode(httpResponseString) as Map<String, dynamic>);
  }

  //
  String getPostBody(String queryMessage) 
  {
    return jsonEncode({
      // 'model': 'llama-3-sonar-large-32k-online',
      'model': 'llama-3.1-sonar-large-128k-chat',
      'messages': [
        {'role': 'system', 'content': 'Be precise and concise'},
        {'content': queryMessage, 'role': 'user'}
      ]
    });
  }

  //
  Map<String, String> getPostHeaders() 
  {
    return ({
      'accept': 'application/json',
      'content-type': 'application/json',
      'authorization': 'Bearer $apiKey',
    });
  }

  //
  Uri getPostUrl() => Uri.https('api.perplexity.ai', '/chat/completions');

  //
  Future<String> postMessage(
      Uri url, Map<String, String> postHeaders, Object postBody) async 
  {
    final httpPackageResponse =
        await http.post(url, headers: postHeaders, body: postBody);

    if (httpPackageResponse.statusCode != 200) {
      print('Failed to retrieve the http package!');
      print('statusCode :  ${httpPackageResponse.statusCode}');
      print('body:  ${httpPackageResponse.body}');
      return "";
    }

    print("In postmessage : ${httpPackageResponse.body}");
    return httpPackageResponse.body;
  }

  List<String> parseQueryResponse(String resp) 
  {
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

  //
  Future<String> postToLlm(String queryPrompt) async 
  {
    var resp = "";

    // use the following test query so Perplexity doesn't charge
    // 'How many stars are there in our galaxy?'
    if (queryPrompt.isNotEmpty) {
      resp = await queryAI(queryPrompt);
    }
    return resp;
  }

  //
  Future<String> queryAI(String query) async 
  {
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
    // print("In queryAI - content :  $retResponse");
    return retResponse;
  }
}
