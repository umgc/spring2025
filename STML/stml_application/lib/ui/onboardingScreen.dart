// ignore_for_file: avoid_print, prefer_const_constructors

import 'package:flutter/material.dart';
import '../src/onboarding.dart';
import 'home_screen.dart';
import 'package:flutter_tts/flutter_tts.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final Onboarding _functionality = Onboarding();
  final FlutterTts flutterTts = FlutterTts(); // Initialize FlutterTts

  @override
  void initState() {
    super.initState();
    _functionality.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0x00440000),
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: const Color(0x00440000), // Set appbar background color
        elevation: 0.0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black54),
        title:
            const Text('Onboarding', style: TextStyle(color: Colors.black54)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
          child: Container(
            padding: const EdgeInsets.only(top: 40.0),
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/background.jpg"),
                fit: BoxFit.cover,
              ),
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: OnboardingUI(
              functionality: _functionality,
              flutterTts: flutterTts, // Pass the FlutterTts instance here
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingUI extends StatefulWidget {
  final Onboarding functionality;
  final FlutterTts flutterTts; // Define the parameter here
  const OnboardingUI({super.key, 
    required this.functionality,
    required this.flutterTts, // Add this parameter
  });

  @override
  _OnboardingUIState createState() => _OnboardingUIState();
}

class _OnboardingUIState extends State<OnboardingUI> {
  final ScrollController _scrollController = ScrollController();
  final FlutterTts flutterTts = FlutterTts();
  bool isMuted = false;

  void toggleMute() {
    setState(() {
      isMuted = !isMuted;
    });

    // Adjust TTS volume based on the mute state
    if (isMuted) {
      widget.flutterTts.setVolume(0.0); // Mute TTS
    } else {
      widget.flutterTts.setVolume(1.0); // Unmute TTS
    }
  }

  Future<void> _speakMessage(String message) async {
    await widget.flutterTts.setVolume(1.0); // Set volume (0.0 to 1.0)
    await widget.flutterTts.setSpeechRate(0.5); // Set speech rate (0.0 to 1.0)
    await widget.flutterTts.setPitch(1.0); // Set pitch (0.0 to 2.0)

    await widget.flutterTts.speak(message);
  }

  @override
  Widget build(BuildContext context) {
    final currentPage =
        widget.functionality.pages[widget.functionality.currentPageIndex];

    // Determine whether to show the text input and microphone icon
    final showTextInputAndMic = widget.functionality.currentPageIndex <
        widget.functionality.pages.length - 3;
    if (widget.functionality.currentPageIndex == 0) {
      _speakMessage(
          "Welcome to our App! Hello and welcome to CogniOpen! My name is Cora your Virtual Assistance. As a new user, I'll guide you through the onboarding process to get you started. Firstly, may I know your name please?");
    }

    return PageView.builder(
      controller: widget.functionality.controller,
      itemCount: widget.functionality.pages.length,
      itemBuilder: (BuildContext context, int index) {
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset('assets/icons/virtual_assistant.png'),
                Text(
                  index == 0 ? "Welcome to our App!" : "",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  index == 0
                      ? "Hello and welcome to CogniOpen! My name is Cora your Virtual Assistant. As a new user, I'll guide you through the onboarding process to get you started. Firstly, may I know your name please?"
                      : "",
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 14),
                SizedBox(
                  height: 200,
                  child: ConversationView(
                    conversation: currentPage.conversation,
                    scrollController: _scrollController,
                    flutterTts: flutterTts,
                  ),
                ),
                SizedBox(height: 7),
                if (showTextInputAndMic) // Conditionally show text input and microphone
                  TextFormField(
                    controller: widget.functionality.userInputController,
                    decoration: InputDecoration(labelText: 'Your Response'),
                  ),
                if (!showTextInputAndMic) //
                  // Conditionally show the "Next" button
                  ElevatedButton(
                    onPressed: () {
                      print(
                          "Before processing, current page: ${widget.functionality.currentPage}");

                      if (widget.functionality.currentPageIndex ==
                          widget.functionality.pages.length - 1) {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => HomeScreen()));
                      } else {
                        widget.functionality.nextPage(context);
                        setState(() {});
                      }

                      print(
                          "After processing, current page: ${widget.functionality.currentPage}");
                    },
                    child: Text("Next"),
                  ),
                if (showTextInputAndMic) // Conditionally show text input and microphone
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          print(
                              "Before processing, current page: ${widget.functionality.currentPage}");

                          if (widget.functionality.currentPageIndex ==
                              widget.functionality.pages.length - 1) {
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => HomeScreen()));
                          } else {
                            widget.functionality.handleUserInput(context);
                            widget.functionality.nextPage(context);
                            setState(() {});
                          }

                          print(
                              "After processing, current page: ${widget.functionality.currentPage}");
                        },
                        child: Text("Next"),
                      ),
                      SizedBox(height: 10),
                      FloatingActionButton(
                        onPressed: widget.functionality.startListening,
                        mini: true,
                        backgroundColor: widget.functionality.isListening
                            ? Colors.red
                            : Theme.of(context).primaryColor,
                        child: widget.functionality.isListening
                            ? Icon(Icons.mic_off)
                            : Icon(Icons.mic),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ConversationView extends StatefulWidget {
  final List<ConversationBubble> conversation;
  final ScrollController scrollController;
  final FlutterTts flutterTts; // Pass the FlutterTts instance as a parameter

  const ConversationView({super.key, 
    required this.conversation,
    required this.scrollController,
    required this.flutterTts, // Add this parameter
  });

  @override
  _ConversationViewState createState() => _ConversationViewState();
}

class _ConversationViewState extends State<ConversationView> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: widget.scrollController,
      itemCount: widget.conversation.length,
      itemBuilder: (context, index) {
        final bubble = widget.conversation[index];
        final isVA = !bubble.isUser; // Check if the bubble is from the VA

        // Play TTS for VA responses
        if (isVA) {
          _speakMessage(bubble.text);
        }

        return ListTile(
          title: Text(
            bubble.text,
            style: TextStyle(
              color: bubble.isUser ? Colors.blue : Colors.black,
            ),
          ),
          trailing: isVA
              ? Icon(Icons.volume_up)
              : null, // Show speaker icon for VA responses
        );
      },
    );
  }

  void _speakMessage(String message) async {
    await widget.flutterTts.setVolume(1.0); // Set volume (0.0 to 1.0)
    await widget.flutterTts.setSpeechRate(0.5); // Set speech rate (0.0 to 1.0)
    await widget.flutterTts.setPitch(1.0); // Set pitch (0.0 to 2.0)

    await widget.flutterTts.speak(message);
  }
}

class NextOnboardingScreen extends StatelessWidget {
  const NextOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Next Onboarding Page")),
      body: Center(child: Text("Welcome to the next onboarding page!")),
    );
  }
}
