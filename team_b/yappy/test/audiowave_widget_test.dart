import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yappy/audiowave_widget.dart';
import 'package:yappy/services/speech_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('AudiowaveWidget displays correctly',
      (WidgetTester tester) async {
    // Mock SpeechState
    final mockSpeechState = SpeechState();
    mockSpeechState.audioSamplesNotifier.value =
        List.generate(100, (index) => (index % 2 == 0) ? 1000 : -1000);

    // Build the AudiowaveWidget widget.
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AudiowaveWidget(speechState: mockSpeechState),
      ),
    ));

    // Allow the widget to fully build.
    await tester.pumpAndSettle();

    // Verify that the AudiowaveWidget is displayed.
    expect(find.byType(AudiowaveWidget), findsOneWidget);

    // Verify that the CustomPaint widget is present.
    expect(find.byType(CustomPaint), findsNWidgets(2));
  });

  testWidgets('AudiowaveWidget updates with new audio samples',
      (WidgetTester tester) async {
    // Mock SpeechState
    final mockSpeechState = SpeechState();
    mockSpeechState.audioSamplesNotifier.value =
        List.generate(100, (index) => (index % 2 == 0) ? 1000 : -1000);

    // Build the AudiowaveWidget widget.
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AudiowaveWidget(speechState: mockSpeechState),
      ),
    ));

    // Allow the widget to fully build.
    await tester.pumpAndSettle();

    // Update the audio samples.
    mockSpeechState.audioSamplesNotifier.value =
        List.generate(100, (index) => (index % 2 == 0) ? 2000 : -2000);
    await tester.pumpAndSettle();

    // Verify that the CustomPaint widget is updated.
    expect(find.byType(CustomPaint), findsNWidgets(2));
  });
}
