import 'package:flutter/material.dart';
import 'package:learninglens_app/Api/experimental/assistant/textbased_function_caller.dart';
import 'package:learninglens_app/Api/experimental/assistant/textbased_llm_client.dart';
import 'package:learninglens_app/Api/llm/enum/llm_enum.dart';
import 'package:learninglens_app/Api/llm/grok_api.dart';
import 'package:learninglens_app/Api/llm/llm_api_modules_base.dart';
import 'package:learninglens_app/Api/llm/openai_api.dart';
import 'package:learninglens_app/Api/llm/perplexity_api.dart';
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/Controller/custom_appbar.dart';
import 'package:learninglens_app/services/local_storage_service.dart';

class TextBasedFunctionCallerView extends StatefulWidget {
  const TextBasedFunctionCallerView({Key? key}) : super(key: key);

  @override
  _TextBasedFunctionCallerViewState createState() =>
      _TextBasedFunctionCallerViewState();
}

class _TextBasedFunctionCallerViewState
    extends State<TextBasedFunctionCallerView> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<Map<String, String>> _messages = [];
  late TextBasedLLMClient _chatGPT;
  bool _isThinking = false; // Tracks if the bot is thinking

  LlmType selectedLLM = LlmType.GROK; //default to chatgpt
  late LLM llm;

  @override
  void initState() {
    super.initState();

    llm = getLLM();

    _chatGPT = TextBasedLLMClient(
      llm,
      TextBasedFunctionCaller(LmsFactory.getLmsService()),
    );
  }

  // grabs the selected LLM.
  LLM getLLM() {
    final aiModel;
    if (selectedLLM == LlmType.CHATGPT) {
      aiModel = OpenAiLLM(LocalStorageService.getOpenAIKey());
    } else if (selectedLLM == LlmType.GROK) {
      aiModel = GrokLLM(LocalStorageService.getGrokKey());
    } else if (selectedLLM == LlmType.PERPLEXITY) {
      // aiModel = OpenAiLLM(perplexityApiKey);
      aiModel = PerplexityLLM(LocalStorageService.getPerplexityKey());
    } else {
      // default
      aiModel = OpenAiLLM(LocalStorageService.getOpenAIKey());
    }
    return aiModel;
  }

  void _sendMessage() async {
    if (_controller.text.isEmpty) return;

    setState(() {
      _messages.add({"sender": "user", "text": _controller.text});
      _isThinking = true; // Show thinking dots
    });

    final userMessage = _controller.text;
    _controller.clear();

    // Add a "thinking" message
    // setState(() {
    //   _messages.add({"sender": "bot", "text": "..."});
    // });

    String response = await _chatGPT.sendMessage(userMessage);

    setState(() {
      // _messages.removeLast(); // Remove "thinking" message
      _messages.add({"sender": "bot", "text": response});
      _isThinking = false; // Bot has finished responding
    });

    _focusNode.requestFocus(); // Refocus input field
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'EduLense Assistant (Beta textbased)',
        userprofileurl: LmsFactory.getLmsService().profileImage ?? '',
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                bool isUser = message["sender"] == "user";

                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  child: Row(
                    mainAxisAlignment: isUser
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      if (!isUser) ...[
                        CircleAvatar(
                          backgroundColor: Colors.grey[200],
                          child: Icon(Icons.android, color: Colors.blueAccent),
                        ),
                        SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                isUser ? Colors.blueAccent : Colors.grey[300],
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            message["text"]!,
                            style: TextStyle(
                              color: isUser ? Colors.white : Colors.black,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      if (isUser) ...[
                        SizedBox(width: 8),
                        CircleAvatar(
                          backgroundColor: Colors.grey[200],
                          child: Icon(Icons.person, color: Colors.blueAccent),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          if (_isThinking)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircularProgressIndicator(), // Loading indicator
            ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: "Ask ${selectedLLM.displayName}...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onSubmitted: (value) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8),
                ClipOval(
                  child: Material(
                    color: Colors.blueAccent,
                    child: InkWell(
                      onTap: _sendMessage,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Icon(Icons.send, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                DropdownButton<LlmType>(
                    value: selectedLLM,
                    onChanged: (LlmType? newValue) {
                      setState(() {
                        selectedLLM = newValue!;
                        llm = getLLM();

                        _chatGPT = TextBasedLLMClient(
                          llm,
                          TextBasedFunctionCaller(LmsFactory.getLmsService()),
                        );

                      });
                    },
                    items: LlmType.values.map((LlmType llm) {
                      return DropdownMenuItem<LlmType>(
                        value: llm,
                        enabled: LocalStorageService.userHasLlmKey(llm),
                        child: Text(
                          llm.displayName,
                          style: TextStyle(
                            color: LocalStorageService.userHasLlmKey(llm)
                                ? Colors.black87
                                : Colors.grey,
                          ),
                        ),
                      );
                    }).toList()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
